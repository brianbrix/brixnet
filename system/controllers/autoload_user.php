<?php

/**
 *  PHP Mikrotik Billing (https://github.com/hotspotbilling/phpnuxbill/)
 *  by https://t.me/ibnux
 **/

/**
 * used for ajax
 **/

_auth();

$action = $routes['1'];
$user = User::_info();

switch ($action) {
    case 'isLogin':
        $bill = ORM::for_table('tbl_user_recharges')->where('id', $routes['2'])->where('username', $user['username'])->findOne();
        if ($bill['type'] == 'Hotspot' && $bill['status'] == 'on') {
            $p = ORM::for_table('tbl_plans')->find_one($bill['plan_id']);
            $dvc = Package::getDevice($p);
            if ($_app_stage != 'demo') {
                try {
                    if (file_exists($dvc)) {
                        require_once $dvc;
                        if ((new $p['device'])->online_customer($user, $bill['routers'])) {
                            die('<a href="' . getUrl('home&mikrotik=logout&id=' . $bill['id']) . '" onclick="return confirm(\'' . Lang::T('Disconnect Internet?') . '\')" class="btn btn-success btn-xs btn-block">' . Lang::T('You are Online, Logout?') . '</a>');
                        } else {
                            if (!empty($_SESSION['nux-mac']) && !empty($_SESSION['nux-ip'])) {
                                die('<a href="' . getUrl('home&mikrotik=login&id=' . $bill['id']) . '" onclick="return confirm(\'' . Lang::T('Connect to Internet?') . '\')" class="btn btn-danger btn-xs btn-block">' . Lang::T('Not Online, Login now?') . '</a>');
                            } else {
                                die(Lang::T('-'));
                            }
                        }
                    } else {
                        die(Lang::T('-'));
                    }
                } catch (Exception $e) {
                    die(Lang::T('Failed to connect to device'));
                }
            }
            die(Lang::T('-'));
        } else {
            die('--');
        }
        break;
    case 'bw_name':
        $bw = ORM::for_table('tbl_bandwidth')->select("name_bw")->find_one($routes['2']);
        echo $bw['name_bw'];
        die();
    case 'inbox_unread':
        $count =  ORM::for_table('tbl_customers_inbox')->where('customer_id', $user['id'])->whereRaw('date_read is null')->count('id');
        if ($count > 0) {
            echo $count;
        }
        die();
    case 'inbox':
        $inboxs = ORM::for_table('tbl_customers_inbox')->selects(['id', 'subject', 'date_created'])->where('customer_id', $user['id'])->whereRaw('date_read is null')->order_by_desc('date_created')->limit(10)->find_many();
        foreach ($inboxs as $inbox) {
            echo '<li><a href="' . getUrl('mail/view/' . $inbox['id']) . '">' . $inbox['subject'] . '<br><sub class="text-muted">' . Lang::dateTimeFormat($inbox['date_created']) . '</sub></a></li>';
        }
        die();
    case 'language':
        $select = _get('select');
        $folders = [];
        $files = scandir('system/lan/');
        foreach ($files as $file) {
            if (is_file('system/lan/' . $file) && !in_array($file, ['index.html', 'country.json', '.DS_Store'])) {
                $file = str_replace(".json", "", $file);
                if(!empty($file)){
                    echo '<li><a href="' . getUrl('accounts/language-update-post&lang=' . $file) . '">';
                    if($select == $file){
                        echo '<span class="glyphicon glyphicon-ok"></span> ';
                    }
                    echo ucwords($file) . '</a></li>';
                }
            }
        }
        die();
    case 'request_new_plan':
        // Customer requests a new plan subscription (no existing bill needed)
        header('Content-Type: application/json');
        try {
            $plan_id = _post('plan_id');
            $message = _post('message', '');
            if (empty($plan_id)) {
                throw new Exception('Invalid plan ID');
            }
            $plan = ORM::for_table('tbl_plans')->where('id', $plan_id)->where('enabled', 1)->find_one();
            if (!$plan) {
                throw new Exception('Plan not found');
            }
            // Create recharge request record (no bill_id since they don't have one yet)
            $quantity = max(1, min(100, (int)_post('quantity', 1)));
            $request = ORM::for_table('tbl_recharge_requests')->create();
            $request->customer_id = $user['id'];
            $request->username = $user['username'];
            $request->bill_id = 0;
            $request->plan_id = $plan_id;
            $request->plan_name = $plan['name_plan'];
            $request->quantity = $quantity;
            $request->message = 'NEW PLAN REQUEST: ' . $message;
            $request->status = 'pending';
            $request->requested_date = date('Y-m-d H:i:s');
            $request->save();
            // Notify admins
            $admins = ORM::for_table('tbl_users')->where('user_type', 'SuperAdmin')->find_many();
            foreach ($admins as $adm) {
                $notification = ORM::for_table('tbl_admin_notifications')->create();
                $notification->admin_id = $adm['id'];
                $notification->type = 'new_plan_request';
                $notification->title = 'New Plan Request from ' . $user['fullname'];
                $notification->message = $user['fullname'] . ' (' . $user['username'] . ') wants to subscribe to: ' . $plan['name_plan'];
                $notification->related_id = $request->id;
                $notification->status = 'unread';
                $notification->created_date = date('Y-m-d H:i:s');
                $notification->save();
            }
            @Message::sendTelegram("#u" . $user['username'] . " wants to subscribe to plan: " . $plan['name_plan'] . "\n" . "Message: " . $message);
            _log('Customer ' . $user['username'] . ' requested new plan: ' . $plan['name_plan'], 'Customer', $user['id']);
            echo json_encode(['status' => 'success', 'message' => 'Request sent! Admin will activate your plan shortly.']);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        die();
    case 'request_recharge':
        // Handle recharge request from customer
        header('Content-Type: application/json');
        
        try {
            $bill_id = _post('bill_id');
            $message = _post('message', '');
            
            if (empty($bill_id)) {
                throw new Exception('Invalid bill ID');
            }
            
            // Get the bill details
            $bill = ORM::for_table('tbl_user_recharges')
                ->where('id', $bill_id)
                ->where('username', $user['username'])
                ->find_one();
            
            if (!$bill) {
                throw new Exception('Plan not found');
            }
            
            // Create recharge request record
            $quantity = max(1, min(100, (int)_post('quantity', 1)));
            $request = ORM::for_table('tbl_recharge_requests')->create();
            $request->customer_id = $user['id'];
            $request->username = $user['username'];
            $request->bill_id = $bill_id;
            $request->plan_id = $bill['plan_id'];
            $request->plan_name = $bill['namebp'];
            $request->quantity = $quantity;
            $request->message = $message;
            $request->status = 'pending';
            $request->requested_date = date('Y-m-d H:i:s');
            $request->save();
            
            // Send notification to admin
            $admins = ORM::for_table('tbl_users')->where('user_type', 'SuperAdmin')->find_many();
            foreach ($admins as $admin) {
                $notification = ORM::for_table('tbl_admin_notifications')->create();
                $notification->admin_id = $admin['id'];
                $notification->type = 'recharge_request';
                $notification->title = 'New Recharge Request from ' . $user['fullname'];
                $notification->message = $user['fullname'] . ' (' . $user['username'] . ') requested recharge for plan: ' . $bill['namebp'];
                $notification->related_id = $request->id;
                $notification->status = 'unread';
                $notification->created_date = date('Y-m-d H:i:s');
                $notification->save();
            }
            
            // Send telegram notification
            @Message::sendTelegram("#u" . $user['username'] . " (#id" . $user['id'] . ") #request #recharge\n" .
                "Plan: " . $bill['namebp'] . "\n" .
                "Message: " . $message);
            
            _log('Customer ' . $user['username'] . ' requested recharge for ' . $bill['namebp'], 'Customer', $user['id']);
            
            echo json_encode(['status' => 'success', 'message' => 'Recharge request sent successfully']);
            
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        die();
    default:
        die();
}
