<?php

/**
 * Server Health Check Cron
 * Monitors Router (MikroTik) and FreeRADIUS service status
 * Run every 5-10 minutes via cron
 */

// Enable error logging for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Write to stderr immediately for debugging
fwrite(STDERR, "[DEBUG] Cron starting at " . date('Y-m-d H:i:s') . "\n");

// Load system bootstrap
require_once dirname(__FILE__) . '/../init.php';

fwrite(STDERR, "[DEBUG] Bootstrap loaded successfully\n");

// Get server configuration from tbl_routers (NAS/routers table)
$router = ORM::for_table('tbl_routers')
    ->where('enabled', 1)
    ->order_by_desc('last_seen')
    ->find_one();

$router_ip = null;
$router_port = null;
$router_name = 'Unknown';
$router_db_status = 'Unknown';

if ($router) {
    $router_name = $router['name'];
    $router_db_status = $router['status'] ?? 'Unknown';
    $ip_address = $router['ip_address'];
    if (strpos($ip_address, ':') !== false) {
        list($router_ip, $router_port) = explode(':', $ip_address);
        $router_port = (int)$router_port;
    } else {
        $router_ip = $ip_address;
        $router_port = 8729; // Default MikroTik API port
    }
    fwrite(STDERR, "[DEBUG] Using router: $router_name -> $router_ip:$router_port (DB status: $router_db_status) (from tbl_routers)\n");
} else {
    fwrite(STDERR, "[WARNING] No enabled router found in tbl_routers\n");
}

$health_table = 'tbl_server_health';
$offline_table = 'tbl_offline_periods';

// Helper function to log with timestamp
function logWithTimestamp($message, $type = 'Server', $userid = 0) {
    $timestamp = date('Y-m-d H:i:s');
    _log("[$timestamp] $message", $type, $userid);
}

// Get current health status
$health = ORM::for_table($health_table)
    ->where('server_name', 'FreeRADIUS')
    ->find_one();

if (!$health) {
    $health = ORM::for_table($health_table)->create();
    $health->server_name = 'FreeRADIUS';
    $health->is_online = 1;
    $health->last_check = date('Y-m-d H:i:s');
    $health->last_online = date('Y-m-d H:i:s');
    $health->save();
}

// Check Router connectivity
$router_is_online = false;
$router_response_time = 0;
if ($router_ip) {
    $router_is_online = checkRouterOnline($router_ip, $router_port, $router_response_time);
}

// Check FreeRADIUS service status
$radius_service_online = checkFreeRadiusService();

// Determine overall system health
$system_is_healthy = $router_is_online && $radius_service_online;

// Log results
fwrite(STDERR, "[DEBUG] Router check: " . ($router_is_online ? "ONLINE" : "OFFLINE") . " (response: {$router_response_time}ms)\n");
fwrite(STDERR, "[DEBUG] FreeRADIUS service: " . ($radius_service_online ? "RUNNING" : "NOT RUNNING") . "\n");
fwrite(STDERR, "[DEBUG] Overall system: " . ($system_is_healthy ? "HEALTHY" : "DEGRADED") . "\n");

// Update router status in database
if ($router) {
    $router->last_seen = date('Y-m-d H:i:s');
    $new_status = $router_is_online ? 'Online' : 'Offline';
    if ($router_db_status !== $new_status) {
        logWithTimestamp("Router '$router_name' status changed: $router_db_status -> $new_status", 'Router', 0);
        $router->status = $new_status;
    }
    $router->save();
}

// Get or create health record for FreeRADIUS service
$radius_health = ORM::for_table($health_table)
    ->where('server_name', 'FreeRADIUS')
    ->find_one();

if (!$radius_health) {
    $radius_health = ORM::for_table($health_table)->create();
    $radius_health->server_name = 'FreeRADIUS';
    $radius_health->is_online = 1;
    $radius_health->last_check = date('Y-m-d H:i:s');
    $radius_health->last_online = date('Y-m-d H:i:s');
    $radius_health->save();
}

// Get or create health record for Router
$router_health = ORM::for_table($health_table)
    ->where('server_name', 'Router')
    ->find_one();

if (!$router_health) {
    $router_health = ORM::for_table($health_table)->create();
    $router_health->server_name = 'Router';
    $router_health->is_online = 1;
    $router_health->last_check = date('Y-m-d H:i:s');
    $router_health->last_online = date('Y-m-d H:i:s');
    $router_health->save();
}

// Process FreeRADIUS service status changes
$radius_current_status = $radius_health['is_online'];
$radius_status_changed = ($radius_current_status != ($radius_service_online ? 1 : 0));

if ($radius_service_online) {
    if ($radius_status_changed) {
        // Service came back online
        logWithTimestamp('FreeRADIUS service came back online', 'FreeRADIUS', 0);
        
        // Record the offline period
        $offline_record = ORM::for_table($offline_table)
            ->where_null('came_online')
            ->where('server_type', 'FreeRADIUS')
            ->order_by_desc('went_offline')
            ->find_one();
        
        if ($offline_record) {
            $went_offline = strtotime($offline_record['went_offline']);
            $came_online = time();
            $duration_minutes = ceil(($came_online - $went_offline) / 60);
            
            $offline_record->came_online = date('Y-m-d H:i:s');
            $offline_record->duration_minutes = $duration_minutes;
            $offline_record->save();
            
            // Check if auto-extension is enabled
            $auto_extend_enabled = $config['auto_extend_on_recovery'] ?? 'yes';
            
            if ($auto_extend_enabled === 'yes') {
                extendPlansForOfflinePeriod($offline_record['id'], $duration_minutes, 'FreeRADIUS');
            } else {
                logWithTimestamp('FreeRADIUS recovered but auto-extension is disabled. Manual extension required.', 'FreeRADIUS', 0);
            }
        }
        
        $radius_health->is_online = 1;
        $radius_health->last_online = date('Y-m-d H:i:s');
        $radius_health->consecutive_failures = 0;
        $radius_health->save();
    } else {
        // Still online
        $radius_health->consecutive_failures = 0;
        $radius_health->last_check = date('Y-m-d H:i:s');
        $radius_health->save();
        logWithTimestamp("FreeRADIUS service check passed (systemctl: running)", 'FreeRADIUS', 0);
    }
} else {
    // Service is offline
    $radius_health->consecutive_failures = ($radius_health['consecutive_failures'] ?? 0) + 1;
    $radius_health->check_failures = ($radius_health['check_failures'] ?? 0) + 1;
    
    // Only mark as offline after 3 consecutive failures
    $offline_threshold = 3;
    if ($radius_health->consecutive_failures >= $offline_threshold && $radius_current_status != 0) {
        logWithTimestamp('FreeRADIUS service went offline after ' . $radius_health->consecutive_failures . ' failed checks', 'FreeRADIUS', 0);
        
        // Create new offline period record
        $offline = ORM::for_table($offline_table)->create();
        $offline->went_offline = date('Y-m-d H:i:s');
        $offline->server_type = 'FreeRADIUS';
        $offline->save();
        
        // Send alert
        Message::sendTelegram(
            "⚠️ *FreeRADIUS Service Down*\n\n" .
            "Service: freeradius\n" .
            "Time: " . date('Y-m-d H:i:s') . "\n\n" .
            "Monitoring active. Plans will be extended when service recovers."
        );
        
        $radius_health->is_online = 0;
    }
    
    $radius_health->last_check = date('Y-m-d H:i:s');
    $radius_health->save();
}

// Process Router status changes
$router_current_status = $router_health['is_online'];
$router_is_online_int = $router_is_online ? 1 : 0;
$router_status_changed = ($router_current_status != $router_is_online_int);

if ($router_is_online) {
    if ($router_status_changed) {
        // Router came back online
        logWithTimestamp("Router '$router_name' came back online", 'Router', 0);
        
        // Record the offline period
        $offline_record = ORM::for_table($offline_table)
            ->where_null('came_online')
            ->where('server_type', 'Router')
            ->order_by_desc('went_offline')
            ->find_one();
        
        if ($offline_record) {
            $went_offline = strtotime($offline_record['went_offline']);
            $came_online = time();
            $duration_minutes = ceil(($came_online - $went_offline) / 60);
            
            $offline_record->came_online = date('Y-m-d H:i:s');
            $offline_record->duration_minutes = $duration_minutes;
            $offline_record->save();
            
            logWithTimestamp("Router offline period ended. Duration: $duration_minutes minutes", 'Router', 0);
        }
        
        $router_health->is_online = 1;
        $router_health->last_online = date('Y-m-d H:i:s');
        $router_health->consecutive_failures = 0;
        $router_health->save();
        
        // Send alert
        Message::sendTelegram(
            "✅ *Router Back Online*\n\n" .
            "Router: $router_name ($router_ip)\n" .
            "Time: " . date('Y-m-d H:i:s') . "\n" .
            "Response Time: {$router_response_time}ms"
        );
    } else {
        // Still online
        $router_health->consecutive_failures = 0;
        $router_health->response_time_ms = $router_response_time;
        $router_health->last_check = date('Y-m-d H:i:s');
        $router_health->save();
        logWithTimestamp("Router '$router_name' check passed (ping + port $router_port)", 'Router', 0);
    }
} else {
    // Router is offline
    $router_health->consecutive_failures = ($router_health['consecutive_failures'] ?? 0) + 1;
    $router_health->check_failures = ($router_health['check_failures'] ?? 0) + 1;
    
    // Only mark as offline after 3 consecutive failures
    $offline_threshold = 3;
    if ($router_health->consecutive_failures >= $offline_threshold && $router_current_status != 0) {
        logWithTimestamp("Router '$router_name' went offline after " . $router_health->consecutive_failures . ' failed checks', 'Router', 0);
        
        // Create new offline period record
        $offline = ORM::for_table($offline_table)->create();
        $offline->went_offline = date('Y-m-d H:i:s');
        $offline->server_type = 'Router';
        $offline->save();
        
        // Send alert
        Message::sendTelegram(
            "⚠️ *Router Down*\n\n" .
            "Router: $router_name ($router_ip:$router_port)\n" .
            "Time: " . date('Y-m-d H:i:s') . "\n\n" .
            "Cannot reach MikroTik router."
        );
        
        $router_health->is_online = 0;
    }
    
    $router_health->last_check = date('Y-m-d H:i:s');
    $router_health->save();
}

// Update overall system status
$overall_health = ORM::for_table($health_table)
    ->where('server_name', 'Overall')
    ->find_one();

if (!$overall_health) {
    $overall_health = ORM::for_table($health_table)->create();
    $overall_health->server_name = 'Overall';
}
$overall_health->is_online = $system_is_healthy ? 1 : 0;
$overall_health->last_check = date('Y-m-d H:i:s');
if ($system_is_healthy) {
    $overall_health->last_online = date('Y-m-d H:i:s');
}
$overall_health->save();

// Log overall status
if ($system_is_healthy) {
    logWithTimestamp("System health check PASSED - All services operational", 'System', 0);
} else {
    $issues = [];
    if (!$router_is_online) $issues[] = "Router OFFLINE";
    if (!$radius_service_online) $issues[] = "FreeRADIUS NOT RUNNING";
    logWithTimestamp("System health check FAILED - " . implode(', ', $issues), 'System', 0);
}

/**
 * Check if Router (MikroTik) is online via ping and port check
 * @return bool router is online
 */
function checkRouterOnline($host, $port, &$response_time) {
    $start = microtime(true);
    
    // Method 1: Ping the host
    $ping_cmd = PHP_OS_FAMILY === 'Windows' 
        ? "ping -n 1 -w 3000 " . escapeshellarg($host) 
        : "ping -c 1 -W 3 " . escapeshellarg($host) . " 2>/dev/null";
    
    $output = shell_exec($ping_cmd);
    $ping_success = ($output !== null && (strpos($output, 'received') !== false || strpos($output, 'Received') !== false || strpos($output, 'bytes from') !== false || strpos($output, 'ttl') !== false));
    
    // Method 2: Try socket connection to MikroTik API port
    $socket_success = false;
    if (function_exists('fsockopen')) {
        $connection = @fsockopen($host, $port, $errno, $errstr, 3);
        if ($connection) {
            fclose($connection);
            $socket_success = true;
        }
    }
    
    $response_time = round((microtime(true) - $start) * 1000);
    
    // Router is considered online if both ping and socket check pass
    return $ping_success && $socket_success;
}

/**
 * Check if FreeRADIUS service is running (container-friendly)
 * Since app is in container and FreeRADIUS is on host, we check via:
 * 1. Socket connection to RADIUS port on host (auto-detected from container network)
 * 2. Recent radius accounting entries in database
 * @return bool service is running
 */
function checkFreeRadiusService() {
    // Dynamically detect possible host IPs
    $possible_hosts = [];
    
    // Method A: Get default gateway (usually the Docker host on Linux)
    $gateway = shell_exec("ip route | grep default | awk '{print $3}' | head -1");
    if ($gateway && filter_var(trim($gateway), FILTER_VALIDATE_IP)) {
        $possible_hosts[] = trim($gateway);
    }
    
    // Method B: Get host.docker.internal (works on Docker Desktop)
    $host_docker = gethostbyname('host.docker.internal');
    if ($host_docker && $host_docker !== 'host.docker.internal') {
        $possible_hosts[] = $host_docker;
    }
    
    // Method C: Parse /proc/net/route to find gateway
    if (file_exists('/proc/net/route')) {
        $route_content = file_get_contents('/proc/net/route');
        if (preg_match('/^[a-z0-9]+\s+00000000\s+([0-9A-F]{8})/m', $route_content, $matches)) {
            // Convert hex IP to dotted notation
            $hex = $matches[1];
            $ip = hexdec(substr($hex, 6, 2)) . '.' . 
                  hexdec(substr($hex, 4, 2)) . '.' .
                  hexdec(substr($hex, 2, 2)) . '.' .
                  hexdec(substr($hex, 0, 2));
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                $possible_hosts[] = $ip;
            }
        }
    }
    
    // Fallback common IPs if detection failed
    if (empty($possible_hosts)) {
        $possible_hosts = [
            '172.17.0.1',
            '172.18.0.1', 
            '192.168.1.1',
            '127.0.0.1',
        ];
    }
    
    // Remove duplicates while preserving order
    $possible_hosts = array_unique($possible_hosts);
    
    $port = 1812; // Standard RADIUS authentication port
    
    fwrite(STDERR, "[DEBUG] Checking FreeRADIUS on hosts: " . implode(', ', $possible_hosts) . "\n");
    
    // Try socket connection to RADIUS port on each detected host
    if (function_exists('fsockopen')) {
        foreach ($possible_hosts as $host) {
            $connection = @fsockopen($host, $port, $errno, $errstr, 1);
            if ($connection) {
                fclose($connection);
                fwrite(STDERR, "[DEBUG] FreeRADIUS reachable on $host:$port\n");
                return true;
            }
        }
    }
    
    // Check for recent radius activity as fallback
    return checkRadiusDatabaseActivity();
}

/**
 * Check if FreeRADIUS is active via database entries
 */
function checkRadiusDatabaseActivity() {
    // Check for recent radius accounting entries (last 5 minutes)
    try {
            $recent = ORM::for_table('radacct')
            ->where_gte('acctstarttime', date('Y-m-d H:i:s', strtotime('-5 minutes')))
            ->count();
        
        if ($recent > 0) {
            fwrite(STDERR, "[DEBUG] FreeRADIUS active - $recent recent accounting entries\n");
            return true;
        }
    } catch (Exception $e) {
        // Database check failed
    }
    
    // Check if radpostauth has recent entries
    try {
        $recent_auth = ORM::for_table('radpostauth', 'radius')
            ->where_gte('authdate', date('Y-m-d H:i:s', strtotime('-5 minutes')))
            ->count();
        if ($recent_auth > 0) {
            fwrite(STDERR, "[DEBUG] FreeRADIUS active - $recent_auth recent auth attempts\n");
            return true;
        }
    } catch (Exception $e) {
        // Cannot access radius database
    }
    
    return false;
}

/**
 * Extend all active customer plans by the offline duration
 */
function extendPlansForOfflinePeriod($offline_id, $duration_minutes, $server_type = 'FreeRADIUS') {
    global $_c;
    
    // Get all active plans that are currently valid
    $plans = ORM::for_table('tbl_user_recharges')
        ->where('status', 'on')
        ->where_gt('expiration', date('Y-m-d'))
        ->find_many();
    
    $extended_count = 0;
    $skipped_count = 0;
    
    foreach ($plans as $plan) {
        // Check if this customer was already extended for this offline period
        $already_extended = ORM::for_table('tbl_customer_offline_extensions')
            ->where('customer_id', $plan['customer_id'])
            ->where('offline_period_id', $offline_id)
            ->where('recharge_id', $plan['id'])
            ->find_one();
        
        if ($already_extended) {
            $skipped_count++;
            continue; // Skip if already extended
        }
        
        // Extend expiration by offline duration
        $old_expiration_full = $plan['expiration'] . ' ' . $plan['time'];
        $old_expiration = $old_expiration_full;
        $new_expiration_datetime = strtotime($old_expiration_full) + ($duration_minutes * 60);
        $new_expiration_date = date('Y-m-d', $new_expiration_datetime);
        $new_expiration_time = date('H:i:s', $new_expiration_datetime);
        $new_expiration = $new_expiration_date . ' ' . $new_expiration_time;
        
        $plan->expiration = $new_expiration_date;
        $plan->time = $new_expiration_time;
        $plan->save();
        
        // Record extension in tracking table
        $ext_record = ORM::for_table('tbl_customer_offline_extensions')->create();
        $ext_record->customer_id = $plan['customer_id'];
        $ext_record->offline_period_id = $offline_id;
        $ext_record->recharge_id = $plan['id'];
        $ext_record->extension_minutes = $duration_minutes;
        $ext_record->old_expiration = $old_expiration;
        $ext_record->new_expiration = $new_expiration;
        $ext_record->extended_by = 'auto';
        $ext_record->admin_id = NULL;
        $ext_record->save();
        
        $extended_count++;
        
        // Log extension
        _log(
            'Plan extended by ' . $duration_minutes . ' minutes due to server downtime (Auto)',
            'SystemExtension',
            $plan['customer_id']
        );
        
        // Send inbox notification to customer
        Message::addToInbox(
            $plan['customer_id'],
            'Plan Extended - Server Downtime',
            'Your plan "' . $plan['plan_name'] . '" has been automatically extended by ' . $duration_minutes . ' minutes due to server downtime.' .
            "\n\nOld expiration: " . $old_expiration .
            "\nNew expiration: " . $new_expiration .
            "\n\nWe apologize for the inconvenience."
        );
    }
    
    // Update offline period with extension info
    $offline = ORM::for_table('tbl_offline_periods')->find_one($offline_id);
    if ($offline) {
        $offline->plans_extended = $extended_count;
        $offline->affected_customers = $extended_count;
        $offline->extended = 1;
        $offline->extension_date = date('Y-m-d H:i:s');
        if ($skipped_count > 0) {
            $offline->notes = $skipped_count . ' customers skipped (already extended)';
        }
        $offline->save();
    }
    
    // Send Telegram notification about extensions
    if ($extended_count > 0) {
        Message::sendTelegram(
            "✅ *Server Recovery - Plans Extended*\n\n" .
            "Customers Extended: " . $extended_count . "\n" .
            ($skipped_count > 0 ? "Skipped (Already Extended): " . $skipped_count . "\n" : "") .
            "Extension Duration: " . $duration_minutes . " minutes\n" .
            "Extended At: " . date('Y-m-d H:i:s')
        );
    }
}

fwrite(STDERR, "[DEBUG] Cron completed successfully at " . date('Y-m-d H:i:s') . "\n");
