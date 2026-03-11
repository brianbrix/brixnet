<?php

/**
 * Public message form for hotspot users (no login required)
 * Also allows logged-in users to send messages
 */

$ui->assign('_title', 'Send Message');

$action = $routes['1'];
$mac = trim((string) _get('nux-mac', isset($_SESSION['nux-mac']) ? $_SESSION['nux-mac'] : ''));
$ip = trim((string) _get('nux-ip', isset($_SESSION['nux-ip']) ? $_SESSION['nux-ip'] : ''));

// Check if user is logged in
$current_user_id = (int) User::getID();
$is_authenticated = $current_user_id > 0;
$logged_in_user = $is_authenticated ? User::_info($current_user_id) : null;

function find_guest_reply($mac, $ip)
{
    if ($mac === '' && $ip === '') {
        return null;
    }

    try {
        // Security rule:
        // 1) Prefer MAC identity.
        // 2) Allow IP-only delivery only when stored reply has no MAC.
        // 3) Expire old replies to avoid delivery after IP reuse.
        $expiryMinutes = 120;
        $query = ORM::for_table('tbl_guest_replies')
            ->where('status', 'unread')
            ->where_gte('created_date', date('Y-m-d H:i:s', strtotime('-' . $expiryMinutes . ' minutes')));

        if ($mac !== '' && $ip !== '') {
            $query->where_raw('(
                (mac = ? AND ip = ?)
                OR (mac = ? AND (ip IS NULL OR ip = ""))
            )', [$mac, $ip, $mac]);
        } elseif ($mac !== '') {
            $query->where('mac', $mac);
        } else {
            $query->where('ip', $ip)
                ->where_raw('(mac IS NULL OR mac = "")');
        }

        return $query->order_by_desc('created_date')->find_one();
    } catch (Throwable $e) {
        return null;
    }
}

switch ($action) {
    case 'send':
        // Show the message form
        $ui->assign('mac', htmlspecialchars($mac));
        $ui->assign('ip', htmlspecialchars($ip));
        $ui->assign('is_authenticated', $is_authenticated);

        $guest_reply = null;
        if (!$is_authenticated) {
            $reply = find_guest_reply($mac, $ip);
            if ($reply) {
                $guest_reply = $reply->as_array();
                $reply->status = 'read';
                $reply->read_date = date('Y-m-d H:i:s');
                $reply->save();
            }
        }

        $ui->assign('guest_reply', $guest_reply);
        if ($is_authenticated) {
            $ui->assign('logged_in_user', $logged_in_user);
        }
        $ui->display('message_public.tpl');
        break;

    case 'check_reply':
        header('Content-Type: application/json');
        $mac = trim((string) _get('nux-mac', isset($_SESSION['nux-mac']) ? $_SESSION['nux-mac'] : ''));
        $ip = trim((string) _get('nux-ip', isset($_SESSION['nux-ip']) ? $_SESSION['nux-ip'] : ''));

        if ($is_authenticated) {
            echo json_encode(['status' => 'success', 'has_reply' => false]);
            die();
        }

        $reply = find_guest_reply($mac, $ip);
        if (!$reply) {
            echo json_encode(['status' => 'success', 'has_reply' => false]);
            die();
        }

        $reply->status = 'read';
        $reply->read_date = date('Y-m-d H:i:s');
        $reply->save();

        echo json_encode([
            'status' => 'success',
            'has_reply' => true,
            'reply' => [
                'id' => $reply['id'],
                'message' => $reply['reply_message'],
                'created_date' => $reply['created_date']
            ]
        ]);
        die();

    case 'submit':
        // Process the message submission
        $mac = trim((string) _post('nux-mac', _get('nux-mac', isset($_SESSION['nux-mac']) ? $_SESSION['nux-mac'] : '')));
        $ip = trim((string) _post('nux-ip', _get('nux-ip', isset($_SESSION['nux-ip']) ? $_SESSION['nux-ip'] : '')));

        if ($_app_stage == 'Demo') {
            r2(getUrl('message_public/send') . '?nux-mac=' . urlencode($mac) . '&nux-ip=' . urlencode($ip), 'e', 'Demo mode - message not sent');
        }

        $sender_name = _post('sender_name');
        $sender_contact = _post('sender_contact');
        $message_text = _post('message');

        if (empty($message_text) || strlen(trim($message_text)) < 1) {
            r2(getUrl('message_public/send') . '?nux-mac=' . urlencode($mac) . '&nux-ip=' . urlencode($ip), 'e', Lang::T('Message cannot be empty'));
        }

        // Use authenticated user details if logged in
        if ($is_authenticated) {
            $sender_username = !empty($logged_in_user['username']) ? $logged_in_user['username'] : ('uid-' . $current_user_id);
            $sender_name = !empty($logged_in_user['fullname']) ? $logged_in_user['fullname'] : $sender_username;
            $sender_contact = !empty($logged_in_user['email']) ? $logged_in_user['email'] : 'Not provided';
            $title = "Message from " . $sender_username;
            $message_type = 'user_message';
            $redirect_url = getUrl('home');
        } else {
            $title = "Guest Message from " . ($sender_name ?: 'Hotspot User');
            $message_type = 'guest_message';
            // Redirect guests back to where they came from (hotspot login page)
            $redirect_url = !empty($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : getUrl('message_public/send') . '?nux-mac=' . urlencode($mac) . '&nux-ip=' . urlencode($ip);
        }

        // Save to database
        $notif = ORM::for_table('tbl_admin_notifications')->create();
        $notif->admin_id = 0; // No specific admin - all see it
        $notif->title = $title;
        $notif->message = "**" . ($is_authenticated ? "Authenticated User" : "Guest") . " Message from Hotspot**\n\n" .
            "Name: " . $sender_name . "\n" .
            "Contact: " . $sender_contact . "\n" .
            "MAC: " . $mac . "\n" .
            "IP: " . $ip . "\n" .
            ($is_authenticated ? "Username: " . $sender_username . "\n" : "") .
            "\nMessage:\n" . $message_text;
        $notif->type = $message_type;
        $notif->related_id = $is_authenticated ? $current_user_id : 0;
        $notif->status = 'unread';
        $notif->created_date = date('Y-m-d H:i:s');
        $notif->save();

        // Send Telegram notification to admins
        Message::sendTelegram(
            ($is_authenticated ? "👤 *Authenticated User Message*" : "📩 *Guest Message from Hotspot*") . "\n\n" .
            "Name: " . $sender_name . "\n" .
            "Contact: " . $sender_contact . "\n" .
            "MAC: `" . $mac . "`\n" .
            "IP: `" . $ip . "`\n" .
            ($is_authenticated ? "Username: `" . $sender_username . "`\n" : "") .
            "\nMessage:\n_" . substr($message_text, 0, 300) . "_"
        );

        _log('[' . ($is_authenticated ? $sender_username : 'Guest') . ']: Message sent from MAC: ' . $mac . ', IP: ' . $ip, 'Message', $is_authenticated ? $current_user_id : 0);

        r2($redirect_url, 's', Lang::T('Message sent successfully! An admin will contact you soon.'));
        break;

    default:
        r2(getUrl('message_public/send'));
        break;
}
