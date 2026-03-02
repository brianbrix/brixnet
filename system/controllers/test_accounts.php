<?php

/**
 * Test Accounts Management Controller
 * Manage users excluded from statistics and calculations
 */

_admin();
$ui->assign('_title', Lang::T('Test Accounts Management'));
$ui->assign('_system_menu', 'settings');

$action = $routes['1'];
$admin = Admin::_info();
$ui->assign('_admin', $admin);

switch ($action) {
    case 'list':
    default:
        // Get all customers with their exclusion status
        $search = _post('search');
        $query = ORM::for_table('tbl_customers');
        
        if (!empty($search)) {
            $query->where_raw('(username LIKE ? OR fullname LIKE ? OR email LIKE ? OR phonenumber LIKE ?)', 
                ["%$search%", "%$search%", "%$search%", "%$search%"]);
        }
        
        // Order by excluded first, then by username
        $query->order_by_desc('exclude_from_stats')->order_by_asc('username');
        
        $customers = Paginator::findMany($query);
        
        // Count excluded users
        $excluded_count = ORM::for_table('tbl_customers')
            ->where('exclude_from_stats', 1)
            ->count();
        
        $ui->assign('customers', $customers);
        $ui->assign('excluded_count', $excluded_count);
        $ui->assign('search', $search);
        $ui->display('admin/test_accounts/list.tpl');
        break;
        
    case 'toggle':
        $id = $routes['2'];
        $customer = ORM::for_table('tbl_customers')->find_one($id);
        
        if (!$customer) {
            r2(getUrl('test_accounts/list'), 'e', Lang::T('Customer not found'));
        }
        
        // Toggle the exclusion status
        $customer->exclude_from_stats = $customer->exclude_from_stats ? 0 : 1;
        $customer->save();
        
        $status = $customer->exclude_from_stats ? 'excluded from' : 'included in';
        
        _log('[' . $admin['username'] . ']: ' . $customer->username . ' ' . $status . ' statistics', 
            $admin['user_type'], $admin['id']);
        
        // Redirect back to customer view if requested, otherwise to test accounts list
        $redirect = _get('redirect');
        if ($redirect == 'customer') {
            r2(getUrl('customers/view/' . $id), 's', 
                Lang::T('Customer') . ' ' . $customer->username . ' ' . Lang::T('has been') . ' ' . $status . ' ' . Lang::T('statistics'));
        } else {
            r2(getUrl('test_accounts/list'), 's', 
                Lang::T('Customer') . ' ' . $customer->username . ' ' . Lang::T('has been') . ' ' . $status . ' ' . Lang::T('statistics'));
        }
        break;
        
    case 'toggle_multiple':
        // Handle array of customer IDs from checkboxes
        $ids = isset($_POST['customer_ids']) && is_array($_POST['customer_ids']) ? $_POST['customer_ids'] : [];
        $action_type = _post('action_type'); // 'exclude' or 'include'
        
        if (empty($ids)) {
            r2(getUrl('test_accounts/list'), 'e', Lang::T('No customers selected'));
        }
        
        $value = ($action_type == 'exclude') ? 1 : 0;
        $count = 0;
        
        foreach ($ids as $id) {
            $id = (int)$id; // Ensure ID is integer
            $customer = ORM::for_table('tbl_customers')->find_one($id);
            if ($customer) {
                $customer->exclude_from_stats = $value;
                $customer->save();
                $count++;
            }
        }
        
        $status = ($action_type == 'exclude') ? 'excluded from' : 'included in';
        
        _log('[' . $admin['username'] . ']: Bulk ' . $status . ' statistics - ' . $count . ' customers', 
            $admin['user_type'], $admin['id']);
        
        r2(getUrl('test_accounts/list'), 's', 
            $count . ' ' . Lang::T('customers have been') . ' ' . $status . ' ' . Lang::T('statistics'));
        break;
        
    case 'exclude_all':
        // Get all customers matching criteria
        $search = _post('search');
        $query = ORM::for_table('tbl_customers');
        
        if (!empty($search)) {
            $query->where_raw('(username LIKE ? OR fullname LIKE ?)', ["%$search%", "%$search%"]);
        }
        
        $customers = $query->find_many();
        $count = 0;
        
        foreach ($customers as $customer) {
            $customer->exclude_from_stats = 1;
            $customer->save();
            $count++;
        }
        
        _log('[' . $admin['username'] . ']: Bulk excluded ' . $count . ' customers from statistics', 
            $admin['user_type'], $admin['id']);
        
        r2(getUrl('test_accounts/list'), 's', 
            $count . ' ' . Lang::T('customers have been excluded from statistics'));
        break;
        
    case 'statistics':
        // Show statistics comparison with/without excluded accounts
        
        // Total customers
        $total_all = ORM::for_table('tbl_customers')->count();
        $total_included = ORM::for_table('tbl_customers')->where('exclude_from_stats', 0)->count();
        $total_excluded = $total_all - $total_included;
        
        // Active subscriptions
        $active_all = ORM::for_table('tbl_user_recharges')->where('status', 'on')->count();
        $active_included = ORM::for_table('tbl_user_recharges')
            ->where('status', 'on')
            ->innerJoin('tbl_customers', ['tbl_user_recharges.customer_id', '=', 'tbl_customers.id'])
            ->where('tbl_customers.exclude_from_stats', 0)
            ->count();
        $active_excluded = $active_all - $active_included;
        
        // Revenue this month
        $start_date = date('Y-m-01');
        $revenue_all = ORM::for_table('tbl_transactions')
            ->where_gte('recharged_on', $start_date)
            ->sum('price');
        $revenue_included = ORM::for_table('tbl_transactions')
            ->where_gte('recharged_on', $start_date)
            ->innerJoin('tbl_customers', ['tbl_transactions.customer_id', '=', 'tbl_customers.id'])
            ->where('tbl_customers.exclude_from_stats', 0)
            ->sum('tbl_transactions.price');
        $revenue_excluded = $revenue_all - $revenue_included;
        
        $ui->assign('total_all', $total_all);
        $ui->assign('total_included', $total_included);
        $ui->assign('total_excluded', $total_excluded);
        $ui->assign('active_all', $active_all);
        $ui->assign('active_included', $active_included);
        $ui->assign('active_excluded', $active_excluded);
        $ui->assign('revenue_all', $revenue_all);
        $ui->assign('revenue_included', $revenue_included);
        $ui->assign('revenue_excluded', $revenue_excluded);
        
        $ui->display('admin/test_accounts/statistics.tpl');
        break;
}
