<?php

/**
 * Admin Messages Controller
 * View guest messages from hotspot and other system notifications
 */

_admin();
$ui->assign('_title', Lang::T('Admin Messages'));
$ui->assign('_system_menu', 'admin_messages');

$action = $routes['1'];
$admin = Admin::_info();
$ui->assign('_admin', $admin);

function ensure_guest_reply_table()
{
    ORM::raw_execute("CREATE TABLE IF NOT EXISTS `tbl_guest_replies` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `source_message_id` int(11) DEFAULT NULL,
        `mac` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
        `ip` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
        `reply_message` text COLLATE utf8_unicode_ci,
        `status` enum('unread','read') COLLATE utf8_unicode_ci DEFAULT 'unread',
        `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
        `read_date` datetime NULL,
        `admin_id` int(11) DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `status` (`status`),
        KEY `mac` (`mac`),
        KEY `ip` (`ip`),
        KEY `created_date` (`created_date`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci");
}

function extract_guest_identity($messageBody)
{
    $mac = '';
    $ip = '';

    if (preg_match('/^MAC:\s*(.+)$/mi', $messageBody, $macMatch)) {
        $mac = trim($macMatch[1]);
    }

    if (preg_match('/^IP:\s*(.+)$/mi', $messageBody, $ipMatch)) {
        $ip = trim($ipMatch[1]);
    }

    return ['mac' => $mac, 'ip' => $ip];
}

function extract_message_username($title, $messageBody)
{
    if (preg_match('/^Username:\s*(.+)$/mi', (string) $messageBody, $match)) {
        return trim($match[1]);
    }

    if (preg_match('/^Message from\s+(.+)$/i', (string) $title, $match)) {
        return trim($match[1]);
    }

    return '';
}

switch ($action) {
    case 'list':
    default:
        $ui->assign('csrf_token', Csrf::generateAndStoreToken());

        // Get filter from query string
        $filter = _get('filter', 'unread');
        $ui->assign('filter', $filter);
        
        // Build query
        $query = ORM::for_table('tbl_admin_notifications');
        
        if ($filter == 'unread') {
            $query->where('status', 'unread');
        }
        // else show all
        
        $query->order_by_desc('created_date');
        
        $messages = Paginator::findMany($query);
        
        // Count unread messages
        $unread_count = ORM::for_table('tbl_admin_notifications')
            ->where('status', 'unread')
            ->count();
        
        $ui->assign('messages', $messages);
        $ui->assign('unread_count', $unread_count);
        $ui->display('admin/admin_messages/list.tpl');
        break;
        
    case 'view':
        $ui->assign('csrf_token', Csrf::generateAndStoreToken());

        $id = $routes['2'];
        $message = ORM::for_table('tbl_admin_notifications')->find_one($id);
        
        if (!$message) {
            r2(getUrl('admin_messages/list'), 'e', Lang::T('Message not found in notifications table'));
        }
        
        // Mark as read if unread
        if ($message['status'] == 'unread') {
            $message->status = 'read';
            $message->read_date = date('Y-m-d H:i:s');
            $message->save();
        }
        
        $ui->assign('message', $message->as_array());
        $ui->display('admin/admin_messages/view.tpl');
        break;

    case 'reply':
        // ID comes exclusively from POST body to avoid URL routing ambiguity
        $id = (int) _post('message_id', 0);
        if ($id <= 0) {
            // Fallback: try the URL segment (canonical mode) or GET
            $id = (int) (isset($routes['2']) && $routes['2'] !== '' ? $routes['2'] : _get('id', 0));
        }

        if ($id <= 0) {
            r2(getUrl('admin_messages/list'), 'e', Lang::T('Message not found'));
        }

        $csrf_token = _post('csrf_token');
        if (!Csrf::check($csrf_token)) {
            r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Invalid or Expired CSRF Token') . '.');
        }

        $message = ORM::for_table('tbl_admin_notifications')->find_one($id);
        if (!$message) {
            r2(getUrl('admin_messages/list'), 'e',
                'Reply failed: no record found with ID=' . $id . ' in tbl_admin_notifications');
        }

        $reply_text = trim((string) _post('reply_message'));
        if ($reply_text === '') {
            r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Reply message cannot be empty'));
        }

        if ($message['type'] === 'user_message' && !empty($message['related_id'])) {
            $target_customer = ORM::for_table('tbl_customers')->find_one($message['related_id']);
            if (!$target_customer) {
                r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Sender account not found'));
            }

            $subject = Lang::T('Reply from Admin');
            Message::addToInbox(
                $target_customer['id'],
                $subject,
                $reply_text,
                $admin['fullname'] ?: $admin['username']
            );
        } elseif ($message['type'] === 'user_message') {
            // Fallback for legacy records where related_id was not stored.
            $username = extract_message_username($message['title'], $message['message']);
            if ($username === '') {
                r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Sender account not found'));
            }

            $target_customer = ORM::for_table('tbl_customers')->where('username', $username)->find_one();
            if (!$target_customer) {
                r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Sender account not found'));
            }

            $subject = Lang::T('Reply from Admin');
            Message::addToInbox(
                $target_customer['id'],
                $subject,
                $reply_text,
                $admin['fullname'] ?: $admin['username']
            );

            // Backfill linkage so the next reply path is direct and reliable.
            $message->related_id = (int) $target_customer['id'];
        } elseif ($message['type'] === 'guest_message') {
            ensure_guest_reply_table();
            $identity = extract_guest_identity($message['message']);

            if ($identity['mac'] === '' && $identity['ip'] === '') {
                r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('Cannot find guest MAC/IP in the original message'));
            }

            $guestReply = ORM::for_table('tbl_guest_replies')->create();
            $guestReply->source_message_id = (int) $message['id'];
            $guestReply->mac = $identity['mac'];
            $guestReply->ip = $identity['ip'];
            $guestReply->reply_message = $reply_text;
            $guestReply->status = 'unread';
            $guestReply->created_date = date('Y-m-d H:i:s');
            $guestReply->admin_id = (int) $admin['id'];
            $guestReply->save();
        } else {
            r2(getUrl('admin_messages/view/', $id), 'e', Lang::T('This sender cannot receive replies'));
        }

        $message->status = 'read';
        if (empty($message['read_date'])) {
            $message->read_date = date('Y-m-d H:i:s');
        }
        $message->save();

        _log('Admin replied to message #' . $message['id'], 'Message', $admin['id']);

        r2(getUrl('admin_messages/list'), 's', Lang::T('Reply sent successfully'));
        break;
        
    case 'mark_read':
        $id = $routes['2'];
        $message = ORM::for_table('tbl_admin_notifications')->find_one($id);
        
        if ($message) {
            $message->status = 'read';
            $message->read_date = date('Y-m-d H:i:s');
            $message->save();
        }
        
        r2(getUrl('admin_messages/list'), 's', Lang::T('Message marked as read'));
        break;
        
    case 'mark_all_read':
        ORM::for_table('tbl_admin_notifications')
            ->where('status', 'unread')
            ->find_result_set()
            ->set('status', 'read')
            ->set('read_date', date('Y-m-d H:i:s'))
            ->save();
        
        r2(getUrl('admin_messages/list'), 's', Lang::T('All messages marked as read'));
        break;
        
    case 'delete':
        $id = $routes['2'];
        $message = ORM::for_table('tbl_admin_notifications')->find_one($id);
        
        if ($message) {
            $message->delete();
            r2(getUrl('admin_messages/list'), 's', Lang::T('Message deleted'));
        } else {
            r2(getUrl('admin_messages/list'), 'e', Lang::T('Message not found in notifications table for delete'));
        }
        break;
    
    case 'check_new':
        // AJAX endpoint to check for new admin messages
        header('Content-Type: application/json');
        
        // Get the last check timestamp from session or parameter
        $last_check = isset($_SESSION['last_message_check']) ? $_SESSION['last_message_check'] : _post('last_check', date('Y-m-d H:i:s', strtotime('-1 hour')));
        
        // Get count of new messages since last check
        $new_count = ORM::for_table('tbl_admin_notifications')
            ->where('status', 'unread')
            ->where_gte('created_date', $last_check)
            ->count();
        
        // Get total unread messages
        $total_unread = ORM::for_table('tbl_admin_notifications')
            ->where('status', 'unread')
            ->count();
        
        // Get latest message details if there's a new one
        $latest_message = null;
        if ($new_count > 0) {
            $message = ORM::for_table('tbl_admin_notifications')
                ->where('status', 'unread')
                ->where_gte('created_date', $last_check)
                ->order_by_desc('created_date')
                ->find_one();
            
            if ($message) {
                $latest_message = [
                    'id' => $message['id'],
                    'type' => $message['type'],
                    'title' => $message['title'],
                    'created_date' => $message['created_date']
                ];
            }
        }
        
        // Update last check timestamp in session
        $_SESSION['last_message_check'] = date('Y-m-d H:i:s');
        
        echo json_encode([
            'status' => 'success',
            'new_count' => $new_count,
            'total_unread' => $total_unread,
            'latest_message' => $latest_message,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        die();
}
