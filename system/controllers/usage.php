<?php

/**
 * Usage Analytics & Reports Controller
 * Track and visualize customer bandwidth usage with date range filtering
 */

_admin();
$ui->assign('_title', Lang::T('Usage Analytics'));
$ui->assign('_system_menu', 'usage');

$admin = Admin::_info();
$ui->assign('_admin', $admin);

$action = $routes['1'];
if (empty($action)) {
    $action = 'list';
}

switch ($action) {
    case 'list':
        // Show all customers with usage summary
        $date_from = _get('date_from');
        $date_to = _get('date_to');
        $search = _get('search');
        
        // Default to last 30 days if no dates provided
        if (!$date_from) {
            $date_from = date('Y-m-d', strtotime('-30 days'));
        }
        if (!$date_to) {
            $date_to = date('Y-m-d');
        }
        
        // Get all customers
        $customers_query = ORM::for_table('tbl_customers')
            ->select('tbl_customers.id', 'id')
            ->select('tbl_customers.username', 'username')
            ->select('tbl_customers.fullname', 'fullname')
            ->select('tbl_customers.email', 'email')
            ->order_by_asc('tbl_customers.username');
        
        if (!empty($search)) {
            $customers_query->where_raw("(tbl_customers.username LIKE ? OR tbl_customers.fullname LIKE ?)", 
                ['%'.$search.'%', '%'.$search.'%']);
        }
        
        $customers = $customers_query->find_many();
        
        // Calculate usage for each customer
        $customer_usage = [];
        foreach ($customers as $cust) {
            $usage = Usage::getCustomerUsage($cust['id'], $date_from, $date_to);
            $customer_usage[] = [
                'id' => $cust['id'],
                'username' => $cust['username'],
                'fullname' => $cust['fullname'],
                'email' => $cust['email'],
                'data_in' => $usage['data_in'],
                'data_out' => $usage['data_out'],
                'data_total' => $usage['data_total'],
                'sessions' => $usage['sessions'],
                'data_in_formatted' => Usage::formatBytes($usage['data_in']),
                'data_out_formatted' => Usage::formatBytes($usage['data_out']),
                'data_total_formatted' => Usage::formatBytes($usage['data_total'])
            ];
        }
        
        // Sort by total usage descending
        usort($customer_usage, function($a, $b) {
            return $b['data_total'] - $a['data_total'];
        });
        
        $ui->assign('customer_usage', $customer_usage);
        $ui->assign('date_from', $date_from);
        $ui->assign('date_to', $date_to);
        $ui->assign('search', $search);
        $ui->assign('csrf_token', Csrf::generateAndStoreToken());
        $ui->display('admin/usage/list.tpl');
        break;
        
    case 'detail':
        // Show detailed usage for a specific customer
        $customer_id = $routes['2'];
        $date_from = _get('date_from');
        $date_to = _get('date_to');
        
        // Default to last 30 days
        if (!$date_from) {
            $date_from = date('Y-m-d', strtotime('-30 days'));
        }
        if (!$date_to) {
            $date_to = date('Y-m-d');
        }
        
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            r2(getUrl('usage'), 'e', 'Customer not found');
        }
        
        // Get detailed usage data
        $usage_summary = Usage::getCustomerUsage($customer_id, $date_from, $date_to);
        $daily_usage = Usage::getDailyUsage($customer_id, $date_from, $date_to);
        $hourly_usage = Usage::getHourlyUsage($customer_id, $date_to);
        
        // Calculate statistics
        $stats = [
            'total_data' => $usage_summary['data_total'],
            'total_data_formatted' => Usage::formatBytes($usage_summary['data_total']),
            'data_in' => $usage_summary['data_in'],
            'data_in_formatted' => Usage::formatBytes($usage_summary['data_in']),
            'data_out' => $usage_summary['data_out'],
            'data_out_formatted' => Usage::formatBytes($usage_summary['data_out']),
            'sessions' => $usage_summary['sessions'],
            'avg_per_day' => !empty($daily_usage) ? Usage::formatBytes($usage_summary['data_total'] / count($daily_usage)) : '0 B',
            'peak_day' => !empty($daily_usage) ? $daily_usage[0] : null
        ];
        
        // Prepare chart data
        $chart_labels = [];
        $chart_data = [];
        foreach ($daily_usage as $day) {
            $chart_labels[] = $day['date'];
            $chart_data[] = round($day['total_bytes'] / (1024 * 1024), 2); // Convert to MB
        }
        
        $chart_labels_json = json_encode($chart_labels);
        $chart_data_json = json_encode($chart_data);
        
        // Hourly chart for last day
        $hourly_labels = [];
        $hourly_data = [];
        foreach ($hourly_usage as $hour) {
            $hourly_labels[] = $hour['hour'] . ':00';
            $hourly_data[] = round($hour['total_bytes'] / (1024 * 1024), 2);
        }
        
        $hourly_labels_json = json_encode($hourly_labels);
        $hourly_data_json = json_encode($hourly_data);
        
        $ui->assign('customer', $customer);
        $ui->assign('stats', $stats);
        $ui->assign('daily_usage', $daily_usage);
        $ui->assign('chart_labels', $chart_labels_json);
        $ui->assign('chart_data', $chart_data_json);
        $ui->assign('hourly_labels', $hourly_labels_json);
        $ui->assign('hourly_data', $hourly_data_json);
        $ui->assign('date_from', $date_from);
        $ui->assign('date_to', $date_to);
        $ui->assign('csrf_token', Csrf::generateAndStoreToken());
        $ui->display('admin/usage/detail.tpl');
        break;
        
    default:
        r2(getUrl('usage'), 'e', 'Invalid action');
        break;
}
