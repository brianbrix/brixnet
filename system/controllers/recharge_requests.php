<?php

/**
 * Recharge Requests Management Controller
 * Admin interface for viewing and processing customer recharge requests
 */

_admin();
$ui->assign('_title', Lang::T('Recharge Requests'));
$ui->assign('_system_menu', 'recharge_requests');

$action = $routes['1'];
$admin = Admin::_info();
$ui->assign('_admin', $admin);

switch ($action) {
    case 'list':
    default:
        // List all pending recharge requests
        $query = ORM::for_table('tbl_recharge_requests')
            ->where('status', 'pending')
            ->order_by_desc('requested_date');
        
        $requests = Paginator::findMany($query);
        
        $ui->assign('requests', $requests);
        $ui->display('admin/recharge_requests/list.tpl');
        break;
        
    case 'view':
        $id = $routes['2'];
        $request = ORM::for_table('tbl_recharge_requests')->find_one($id);
        
        if (!$request) {
            r2(getUrl('recharge_requests/list'), 'e', Lang::T('Request not found'));
        }
        
        // Get customer details (may have been deleted)
        $customer = ORM::for_table('tbl_customers')->find_one($request['customer_id']);
        $customer = $customer ? $customer->as_array() : ['id' => $request['customer_id'], 'username' => 'Deleted', 'fullname' => 'Deleted Customer'];

        // Get plan details (may have been deleted)
        $plan = ORM::for_table('tbl_plans')->find_one($request['plan_id']);
        $plan = $plan ? $plan->as_array() : ['id' => $request['plan_id'], 'name_plan' => 'Deleted Plan', 'price' => 0];

        $ui->assign('request', $request->as_array());
        $ui->assign('customer', $customer);
        $ui->assign('plan', $plan);
        
        $ui->display('admin/recharge_requests/view.tpl');
        break;
        
    case 'approve':
        $id = $routes['2'];
        $request = ORM::for_table('tbl_recharge_requests')->find_one($id);
        
        if (!$request) {
            r2(getUrl('recharge_requests/list'), 'e', Lang::T('Request not found'));
        }
        
        // Process the recharge
        $customer = ORM::for_table('tbl_customers')->find_one($request['customer_id']);
        $plan = ORM::for_table('tbl_plans')->find_one($request['plan_id']);

        if (!$customer || !$plan) {
            r2(getUrl('recharge_requests/view/' . $id), 'e', Lang::T('Customer or plan not found'));
        }

        // When bill_id = 0 it's a new plan request; use plan's router. Otherwise use existing bill's router.
        $bill = ($request['bill_id'] > 0) ? ORM::for_table('tbl_user_recharges')->find_one($request['bill_id']) : null;
        $router_name = ($bill && !empty($bill['routers'])) ? $bill['routers'] : $plan['routers'];

        // Get quantity from request (default to 1 if not set for backward compatibility)
        $quantity = isset($request['quantity']) && $request['quantity'] > 0 ? (int)$request['quantity'] : 1;

        if (Package::rechargeUser($customer['id'], $router_name, $plan['id'], 'Admin', 'Recharge Request', $quantity)) {
            // Fetch the transaction just created by rechargeUser (same as admin manual recharge flow)
            $in = ORM::for_table('tbl_transactions')
                ->where('username', $customer['username'])
                ->order_by_desc('id')
                ->find_one();

            // Generate invoice PDF/record (same as admin manual recharge)
            if ($in) {
                Package::createInvoice($in);
            }

            $request->status = 'completed';
            $request->admin_id = $admin['id'];
            $request->admin_response = 'Recharged successfully by admin';
            $request->processed_date = date('Y-m-d H:i:s');
            $request->save();

            // Send invoice notification to customer
            Message::sendInvoice($customer, $in ?: null);

            // Send inbox message to customer
            Message::addToInbox(
                $customer['id'],
                Lang::T('Recharge Request Approved'),
                Lang::T('Your recharge request for plan') . ' <strong>' . $plan['name_plan'] . '</strong> ' .
                Lang::T('has been approved and activated.') . '<br>' .
                Lang::T('Price') . ': ' . Lang::moneyFormat($plan['price']) . '<br>' .
                ($in ? Lang::T('Invoice') . ': ' . $in['invoice'] : ''),
                $admin['fullname']
            );

            Message::sendTelegram(
                "#u" . $customer['username'] . " (#id" . $customer['id'] . ") #recharge #approved\n" .
                "Plan: " . $plan['name_plan'] . "\n" .
                "Price: " . Lang::moneyFormat($plan['price']) . "\n" .
                "Admin: " . $admin['username']
            );

            _log('[' . $admin['username'] . ']: Recharge ' . $customer['username'] . ' [' . $plan['name_plan'] . '][' . Lang::moneyFormat($plan['price']) . ']', $admin['user_type'], $admin['id']);

            r2(getUrl('recharge_requests/list'), 's', Lang::T('Recharge request approved and processed'));
        } else {
            r2(getUrl('recharge_requests/view/' . $id), 'e', Lang::T('Failed to process recharge'));
        }
        break;
        
    case 'reject':
        $id = $routes['2'];
        $reason = _post('reason', _get('reason', ''));
        
        $request = ORM::for_table('tbl_recharge_requests')->find_one($id);
        
        if (!$request) {
            r2(getUrl('recharge_requests/list'), 'e', Lang::T('Request not found'));
        }
        
        $request->status = 'rejected';
        $request->admin_id = $admin['id'];
        $request->admin_response = $reason;
        $request->processed_date = date('Y-m-d H:i:s');
        $request->save();
        
        // Send notification to customer
        $customer = ORM::for_table('tbl_customers')->find_one($request['customer_id']);
        $plan = ORM::for_table('tbl_plans')->find_one($request['plan_id']);
        $plan_name = $plan ? $plan['name_plan'] : '#' . $request['plan_id'];

        // Send inbox message to customer
        Message::addToInbox(
            $customer['id'],
            Lang::T('Recharge Request Rejected'),
            Lang::T('Your recharge request for plan') . ' <strong>' . $plan_name . '</strong> ' .
            Lang::T('has been rejected.') .
            (!empty($reason) ? '<br>' . Lang::T('Reason') . ': ' . htmlspecialchars($reason) : ''),
            $admin['fullname']
        );

        Message::sendTelegram("#u" . $customer['username'] . " (#id" . $customer['id'] . ") #recharge #rejected\n" .
            "Reason: " . $reason);
        
        _log('[' . $admin['username'] . ']: Rejected recharge request #' . $id . ' for customer ' . $customer['username'] . ' - Reason: ' . $reason, $admin['user_type'], $admin['id']);
        
        r2(getUrl('recharge_requests/list'), 's', Lang::T('Recharge request rejected'));
        break;
        
    case 'history':
        // View processed recharge requests
        $query = ORM::for_table('tbl_recharge_requests')
            ->where_in('status', ['completed', 'rejected', 'approved'])
            ->order_by_desc('processed_date');
        
        $requests = Paginator::findMany($query);
        
        $ui->assign('requests', $requests);
        $ui->display('admin/recharge_requests/history.tpl');
        break;
    
    case 'check_new':
        // AJAX endpoint to check for new recharge requests
        header('Content-Type: application/json');
        
        // Get the last check timestamp from session or parameter
        $last_check = isset($_SESSION['last_recharge_check']) ? $_SESSION['last_recharge_check'] : _post('last_check', date('Y-m-d H:i:s', strtotime('-1 hour')));
        
        // Get count of new recharge requests since last check
        $new_count = ORM::for_table('tbl_recharge_requests')
            ->where('status', 'pending')
            ->where_gte('requested_date', $last_check)
            ->count();
        
        // Get total pending requests
        $total_pending = ORM::for_table('tbl_recharge_requests')
            ->where('status', 'pending')
            ->count();
        
        // Get latest request details if there's a new one
        $latest_request = null;
        if ($new_count > 0) {
            $request = ORM::for_table('tbl_recharge_requests')
                ->where('status', 'pending')
                ->where_gte('requested_date', $last_check)
                ->order_by_desc('requested_date')
                ->find_one();
            
            if ($request) {
                $latest_request = [
                    'id' => $request['id'],
                    'username' => $request['username'],
                    'plan_name' => $request['plan_name'],
                    'requested_date' => $request['requested_date']
                ];
            }
        }
        
        // Update last check timestamp in session
        $_SESSION['last_recharge_check'] = date('Y-m-d H:i:s');
        
        echo json_encode([
            'status' => 'success',
            'new_count' => $new_count,
            'total_pending' => $total_pending,
            'latest_request' => $latest_request,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        die();
}
