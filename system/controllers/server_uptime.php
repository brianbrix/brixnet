<?php

/**
 * Server Uptime Management Controller
 * Admin interface to view server offline periods and manual plan extensions
 */

_admin();
$ui->assign('_title', Lang::T('Router Status & Uptime'));
$ui->assign('_system_menu', 'server_uptime');

$action = $routes['1'];
$admin = Admin::_info();
$ui->assign('_admin', $admin);

switch ($action) {
    case 'settings':
        // Manage auto-extension settings
        if (_post('save_settings')) {
            $auto_extend = _post('auto_extend_on_recovery') == 'yes' ? 'yes' : 'no';
            $max_days = (int)_post('max_offline_extension_days');
            
            if ($max_days < 1) $max_days = 7;
            if ($max_days > 365) $max_days = 365;
            
            // Update config
            $config_auto = ORM::for_table('tbl_appconfig')->where('setting', 'auto_extend_on_recovery')->find_one();
            if (!$config_auto) {
                $config_auto = ORM::for_table('tbl_appconfig')->create();
                $config_auto->setting = 'auto_extend_on_recovery';
            }
            $config_auto->value = $auto_extend;
            $config_auto->save();
            
            $config_days = ORM::for_table('tbl_appconfig')->where('setting', 'max_offline_extension_days')->find_one();
            if (!$config_days) {
                $config_days = ORM::for_table('tbl_appconfig')->create();
                $config_days->setting = 'max_offline_extension_days';
            }
            $config_days->value = $max_days;
            $config_days->save();
            
            r2(getUrl('server_uptime/settings'), 's', 'Settings saved successfully');
        }
        
        $auto_extend = $config['auto_extend_on_recovery'] ?? 'yes';
        $max_days = $config['max_offline_extension_days'] ?? 7;
        
        $ui->assign('auto_extend', $auto_extend);
        $ui->assign('max_days', $max_days);
        $ui->display('admin/server_uptime/settings.tpl');
        break;
        
    case 'list':
    default:
        // Get current router health status
        $health = ORM::for_table('tbl_server_health')
            ->where('server_name', 'Router')
            ->find_one();
        
        $ui->assign('health', $health ? $health->as_array() : [
            'is_online' => 0,
            'last_check' => null,
            'response_time_ms' => 0
        ]);
        
        // Get offline periods history (last 30 records)
        $offline_periods = ORM::for_table('tbl_offline_periods')
            ->order_by_desc('went_offline')
            ->limit(30)
            ->find_many();
        
        // Get max days setting for age check
        $max_days = $config['max_offline_extension_days'] ?? 7;
        $max_age_timestamp = time() - ($max_days * 86400);
        
        $periods = [];
        foreach ($offline_periods as $period) {
            $period_data = $period->as_array();
            
            // Check if period is still ongoing (no came_online yet)
            $is_still_offline = empty($period_data['came_online']);
            
            // Calculate age in days
            $period_timestamp = strtotime($period_data['went_offline']);
            $period_age_days = (time() - $period_timestamp) / 86400;
            $period_data['age_days'] = round($period_age_days, 1);
            
            // Period is ineligible if:
            // 1. Server is still offline (came_online is empty)
            // 2. OR period is too old (older than max_days)
            $period_data['is_too_old'] = $is_still_offline || ($period_timestamp < $max_age_timestamp);
            $period_data['is_still_offline'] = $is_still_offline;
            
            $periods[] = $period_data;
        }
        
        $ui->assign('offline_periods', $periods);
        $ui->assign('max_days', $max_days);
        
        // Statistics
        $total_offline_time = ORM::for_table('tbl_offline_periods')
            ->select_expr('SUM(duration_minutes)', 'total_minutes')
            ->find_one();
        
        $total_extended_customers = ORM::for_table('tbl_offline_periods')
            ->select_expr('SUM(affected_customers)', 'total_customers')
            ->find_one();
        
        $ui->assign('total_offline_minutes', $total_offline_time['total_minutes'] ?? 0);
        $ui->assign('total_extended_customers', $total_extended_customers['total_customers'] ?? 0);
        $ui->assign('total_offline_periods', count($periods));
        
        $ui->display('admin/server_uptime/list.tpl');
        break;
        
    case 'offline-period':
        // View single offline period details
        $id = $routes['2'];
        $period = ORM::for_table('tbl_offline_periods')->find_one($id);
        
        if (!$period) {
            r2(getUrl('server_uptime'), 'e', Lang::T('Offline period not found'));
        }
        
        // Check if period is eligible for extensions
        $max_days = $config['max_offline_extension_days'] ?? 7;
        $period_age_days = (time() - strtotime($period['went_offline'])) / 86400;
        
        // Period is ineligible if:
        // 1. Server is still offline (came_online is empty) - can't extend until server is back
        // 2. OR period is too old (older than max_days)
        $is_still_offline = empty($period['came_online']);
        $is_too_old = $is_still_offline || ($period_age_days > $max_days);
        
        $ui->assign('period', $period->as_array());
        $ui->assign('is_too_old', $is_too_old);
        $ui->assign('is_still_offline', $is_still_offline);
        $ui->assign('max_days', $max_days);
        $ui->assign('period_age_days', round($period_age_days, 1));
        
        // Get affected customers (already extended)
        $extended_customers = ORM::for_table('tbl_customer_offline_extensions')
            ->where('offline_period_id', $id)
            ->find_many();
        
        $affected = [];
        foreach ($extended_customers as $ext) {
            $user = ORM::for_table('tbl_customers')->find_one($ext['customer_id']);
            $recharge = ORM::for_table('tbl_user_recharges')->find_one($ext['recharge_id']);
            $affected[] = [
                'username' => $user ? $user['username'] : 'Unknown',
                'plan_name' => $recharge ? $recharge['namebp'] : 'Unknown',
                'old_expiration' => $ext['old_expiration'],
                'new_expiration' => $ext['new_expiration'],
                'extension_minutes' => $ext['extension_minutes'],
                'extended_by' => $ext['extended_by'],
                'extended_date' => $ext['created_date']
            ];
        }
        
        $ui->assign('affected_customers', $affected);
        $ui->display('admin/server_uptime/detail.tpl');
        break;
        
    case 'manual-extend':
        // Manual extension - select customers for a specific offline period
        $offline_id = $routes['2'] ?? null;
        
        if (!$offline_id) {
            r2(getUrl('server_uptime'), 'e', 'No offline period specified');
        }
        
        $period = ORM::for_table('tbl_offline_periods')->find_one($offline_id);
        if (!$period) {
            r2(getUrl('server_uptime'), 'e', 'Offline period not found');
        }
        
        // Check if period is still ongoing
        if (empty($period['came_online'])) {
            r2(getUrl('server_uptime/offline-period/' . $offline_id), 'e', 'Router is still offline. Cannot extend plans while router is down.');
        }
        
        // Check if period is too old
        $max_days = $config['max_offline_extension_days'] ?? 7;
        $period_age_days = (time() - strtotime($period['went_offline'])) / 86400;
        
        if ($period_age_days > $max_days) {
            r2(getUrl('server_uptime'), 'e', 'This offline period is too old for extensions (max ' . $max_days . ' days)');
        }
        
        if (_post('extend_selected')) {
            // Validate CSRF token
            $csrf_token = _post('csrf_token');
            if (!Csrf::check($csrf_token)) {
                r2(getUrl('server_uptime/manual-extend/' . $offline_id), 'e', 'Invalid request');
            }
            
            // Process manual extension for selected customers
            _log('Form submitted. Raw POST data: ' . json_encode($_POST), 'Debug', 0);
            
            // Get selected customers from POST (handle array properly)
            $selected_customers = isset($_POST['selected_customers']) && is_array($_POST['selected_customers']) 
                ? $_POST['selected_customers'] 
                : [];
            
            // Sanitize the array values
            $selected_customers = array_map('intval', $selected_customers);
            
            // Debug logging
            _log('Manual extend form submitted. Selected: ' . json_encode($selected_customers), 'Debug', 0);
            _log('Selected type: ' . gettype($selected_customers) . ', count: ' . count($selected_customers), 'Debug', 0);
            
            if (empty($selected_customers)) {
                r2(getUrl('server_uptime/manual-extend/' . $offline_id), 'e', 'No customers selected');
            }
            
            $extended_count = 0;
            $skipped_count = 0;
            $duration_minutes = $period['duration_minutes'];
            
            foreach ($selected_customers as $recharge_id) {
                $recharge = ORM::for_table('tbl_user_recharges')->find_one($recharge_id);
                
                if (!$recharge || $recharge['status'] != 'on') {
                    $skipped_count++;
                    continue;
                }
                
                // Check if already extended
                $already_extended = ORM::for_table('tbl_customer_offline_extensions')
                    ->where('customer_id', $recharge['customer_id'])
                    ->where('offline_period_id', $offline_id)
                    ->where('recharge_id', $recharge_id)
                    ->find_one();
                
                if ($already_extended) {
                    $skipped_count++;
                    continue;
                }
                
                // Extend the plan
                $old_expiration_full = $recharge['expiration'] . ' ' . $recharge['time'];
                $old_expiration = $old_expiration_full;
                $new_expiration_datetime = strtotime($old_expiration_full) + ($duration_minutes * 60);
                $new_expiration_date = date('Y-m-d', $new_expiration_datetime);
                $new_expiration_time = date('H:i:s', $new_expiration_datetime);
                
                $recharge->expiration = $new_expiration_date;
                $recharge->time = $new_expiration_time;
                $recharge->save();
                
                // Record extension
                $ext_record = ORM::for_table('tbl_customer_offline_extensions')->create();
                $ext_record->customer_id = $recharge['customer_id'];
                $ext_record->offline_period_id = $offline_id;
                $ext_record->recharge_id = $recharge_id;
                $ext_record->extension_minutes = $duration_minutes;
                $ext_record->old_expiration = $old_expiration;
                $ext_record->new_expiration = $new_expiration_date . ' ' . $new_expiration_time;
                $ext_record->extended_by = 'manual';
                $ext_record->admin_id = $admin['id'];
                $ext_record->save();
                
                $extended_count++;
                
                // Log
                _log('Plan manually extended by ' . $duration_minutes . ' minutes for router offline period #' . $offline_id, 'ManualExtension', $recharge['customer_id']);
                
                // Notify customer
                Message::addToInbox(
                    $recharge['customer_id'],
                    'Plan Extended - Router Downtime',
                    'Your plan "' . $recharge['namebp'] . '" has been extended by ' . $duration_minutes . ' minutes due to router downtime.' .
                    "\n\nOld expiration: " . $old_expiration .
                    "\nNew expiration: " . $new_expiration .
                    "\n\nWe apologize for the inconvenience."
                );
            }
            
            // Update period stats
            $period->plans_extended = ($period['plans_extended'] ?? 0) + $extended_count;
            $period->affected_customers = ($period['affected_customers'] ?? 0) + $extended_count;
            if ($period['extended'] == 0) {
                $period->extended = 1;
                $period->extension_date = date('Y-m-d H:i:s');
            }
            $period->save();
            
            $msg = $extended_count . ' customer(s) extended successfully';
            if ($skipped_count > 0) {
                $msg .= '. ' . $skipped_count . ' skipped (already extended or inactive)';
            }
            
            r2(getUrl('server_uptime/offline-period/' . $offline_id), 's', $msg);
        }
        
        // Get all customers who were active during the offline period
        // This includes customers whose plans were still valid when the server came back online
        // Convert came_online to date for comparison
        $came_online_datetime = strtotime($period['came_online']);
        $came_online_date = date('Y-m-d', $came_online_datetime);
        $came_online_time = date('H:i:s', $came_online_datetime);
        
        $active_plans = ORM::for_table('tbl_user_recharges')
            ->where('status', 'on')
            ->where_raw('CONCAT(expiration, \' \', time) >= ?', [$period['came_online']])
            ->order_by_asc('customer_id')
            ->find_many();
        
        $customers = [];
        foreach ($active_plans as $plan) {
            $customer = ORM::for_table('tbl_customers')->find_one($plan['customer_id']);
            
            if (!$customer) continue;
            
            // Check if already extended for this period
            $already_extended = ORM::for_table('tbl_customer_offline_extensions')
                ->where('customer_id', $plan['customer_id'])
                ->where('offline_period_id', $offline_id)
                ->where('recharge_id', $plan['id'])
                ->find_one();
            
            $expiration_full = $plan['expiration'] . ' ' . $plan['time'];
            
            $customers[] = [
                'recharge_id' => $plan['id'],
                'customer_id' => $plan['customer_id'],
                'username' => $customer['username'],
                'fullname' => $customer['fullname'],
                'plan_name' => $plan['namebp'],
                'expiration_date' => $expiration_full,
                'already_extended' => $already_extended ? true : false
            ];
        }
        
        $ui->assign('period', $period->as_array());
        $ui->assign('customers', $customers);
        $csrf_token = Csrf::generateAndStoreToken();
        $ui->assign('csrf_token', $csrf_token);
        $ui->display('admin/server_uptime/manual_extend.tpl');
        break;
}
