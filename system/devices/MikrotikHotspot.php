<?php

/**
 *  BrixNet - PHP Mikrotik Billing (https://github.com/brianbrix/brixnet/)
 *  by https://t.me/ibnux
 *
 * This is Core, don't modification except you want to contribute
 * better create new plugin
 **/

use PEAR2\Net\RouterOS;

class MikrotikHotspot
{

    // show Description
    function description()
    {
        return [
            'title' => 'Mikrotik Hotspot',
            'description' => 'To handle connection between BrixNet with Mikrotik Hotspot',
            'author' => 'ibnux',
            'url' => [
                'Github' => 'https://github.com/brianbrix/brixnet/',
                'Telegram' => 'https://t.me/brixnet',
                'Donate' => 'https://paypal.me/ibnux'
            ]
        ];
    }


    function add_customer($customer, $plan)
    {
        global $isChangePlan;
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $isExp = ORM::for_table('tbl_plans')->select("id")->where('plan_expired', $plan['id'])->find_one();
        $this->removeHotspotUser($client, $customer['username']);
        if ($isExp || (isset($isChangePlan) && $isChangePlan)) {
            $this->removeHotspotActiveUser($client, $customer['username']);
        }
        $this->addHotspotUser($client, $plan, $customer);
    }
	
	function sync_customer($customer, $plan)
	{
		global $isChangePlan;
		$mikrotik = $this->info($plan['routers']);
		$client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
		$t = ORM::for_table('tbl_user_recharges')->where('username', $customer['username'])->where('status', 'on')->find_one();
		if ($t) {
			$printRequest = new RouterOS\Request('/ip/hotspot/user/print');
			$printRequest->setArgument('.proplist', '.id,limit-uptime,limit-bytes-total');
			$printRequest->setQuery(RouterOS\Query::where('name', $customer['username']));
			$userInfo = $client->sendSync($printRequest);
			$id = $userInfo->getProperty('.id');
			$uptime = $userInfo->getProperty('limit-uptime');
			$data = $userInfo->getProperty('limit-bytes-total');
			if (!empty($id) && (!empty($uptime) || !empty($data))) {
				$setRequest = new RouterOS\Request('/ip/hotspot/user/set');
				$setRequest->setArgument('numbers', $id);
				$setRequest->setArgument('profile', $t['namebp']);
				$client->sendSync($setRequest);
				if (isset($isChangePlan) && $isChangePlan) {
					$this->removeHotspotActiveUser($client, $customer['username']);
				}
			} else {
				$this->add_customer($customer, $plan);
			}
		}
	}

    function pause_customer($customer, $plan)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $userState = $this->getHotspotUserState($client, $customer['username']);

        if (empty($userState['id'])) {
            throw new Exception('Hotspot user not found');
        }

        $remainingUptime = $this->getRemainingHotspotLimitUptime($client, $plan, $customer['username'], $userState);
        $this->removeHotspotActiveUser($client, $customer['username']);

        $setRequest = new RouterOS\Request('/ip/hotspot/user/set');
        $setRequest->setArgument('numbers', $userState['id']);
        if ($remainingUptime !== null) {
            $setRequest->setArgument('limit-uptime', $remainingUptime);
        }

        $client->sendSync(
            $setRequest
                ->setArgument('disabled', 'yes')
        );

        return true;
    }

    function resume_customer($customer, $plan)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $userState = $this->getHotspotUserState($client, $customer['username']);

        if (empty($userState['id'])) {
            throw new Exception('Hotspot user not found');
        }

        $setRequest = new RouterOS\Request('/ip/hotspot/user/set');
        $client->sendSync(
            $setRequest
                ->setArgument('numbers', $userState['id'])
                ->setArgument('disabled', 'no')
        );

        return true;
    }


    function remove_customer($customer, $plan)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        if (!empty($plan['plan_expired'])) {
            $p = ORM::for_table("tbl_plans")->find_one($plan['plan_expired']);
            if($p){
                $this->add_customer($customer, $p);
                $this->removeHotspotActiveUser($client, $customer['username']);
                return;
            }
        }
        $this->removeHotspotUser($client, $customer['username']);
        $this->removeHotspotActiveUser($client, $customer['username']);
    }

    // customer change username
    public function change_username($plan, $from, $to)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        //check if customer exists
        $printRequest = new RouterOS\Request('/ip/hotspot/user/print');
        $printRequest->setArgument('.proplist', '.id');
        $printRequest->setQuery(RouterOS\Query::where('name', $from));
        $id = $client->sendSync($printRequest)->getProperty('.id');

        if (!empty($cid)) {
            $setRequest = new RouterOS\Request('/ip/hotspot/user/set');
            $setRequest->setArgument('numbers', $id);
            $setRequest->setArgument('name', $to);
            $client->sendSync($setRequest);
            //disconnect then
            $this->removeHotspotActiveUser($client, $from);
        }
    }

    function add_plan($plan)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $bw = ORM::for_table("tbl_bandwidth")->find_one($plan['id_bw']);
        if ($bw['rate_down_unit'] == 'Kbps') {
            $unitdown = 'K';
        } else {
            $unitdown = 'M';
        }
        if ($bw['rate_up_unit'] == 'Kbps') {
            $unitup = 'K';
        } else {
            $unitup = 'M';
        }
        $rate = $bw['rate_up'] . $unitup . "/" . $bw['rate_down'] . $unitdown;
        if (!empty(trim($bw['burst']))) {
            $rate .= ' ' . $bw['burst'];
        }
        if ($bw['rate_up'] == '0' || $bw['rate_down'] == '0') {
            $rate = '';
        }

        // Check if the profile already exists — if so, update it (upsert).
        // Simply calling /add when the profile exists fails silently, leaving
        // the old shared-users value in place and breaking the device limit.
        $printRequest = new RouterOS\Request('/ip/hotspot/user/profile/print');
        $printRequest->setArgument('.proplist', '.id');
        $printRequest->setQuery(RouterOS\Query::where('name', $plan['name_plan']));
        $profileID = $client->sendSync($printRequest)->getProperty('.id');

        list($keepaliveTimeout, $idleTimeout) = $this->getProfileTimeouts($plan);

        if (!empty($profileID)) {
            $setRequest = new RouterOS\Request('/ip/hotspot/user/profile/set');
            $client->sendSync(
                $setRequest
                    ->setArgument('numbers', $profileID)
                    ->setArgument('shared-users', $plan['shared_users'])
                    ->setArgument('rate-limit', $rate)
                    ->setArgument('keepalive-timeout', $keepaliveTimeout)
                    ->setArgument('idle-timeout', $idleTimeout)
                    ->setArgument('on-login', (string)$plan['on_login'])
                    ->setArgument('on-logout', (string)$plan['on_logout'])
            );
        } else {
            $addRequest = new RouterOS\Request('/ip/hotspot/user/profile/add');
            $client->sendSync(
                $addRequest
                    ->setArgument('name', $plan['name_plan'])
                    ->setArgument('shared-users', $plan['shared_users'])
                    ->setArgument('rate-limit', $rate)
                    ->setArgument('keepalive-timeout', $keepaliveTimeout)
                    ->setArgument('idle-timeout', $idleTimeout)
                    ->setArgument('on-login', (string)$plan['on_login'])
                    ->setArgument('on-logout', (string)$plan['on_logout'])
            );
        }
    }

    function online_customer($customer, $router_name)
    {
        $mikrotik = $this->info($router_name);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $printRequest = new RouterOS\Request(
            '/ip hotspot active print',
            RouterOS\Query::where('user', $customer['username'])
        );
        $id =  $client->sendSync($printRequest)->getProperty('.id');
        return $id;
    }

    function connect_customer($customer, $ip, $mac_address, $router_name)
    {
        $mikrotik = $this->info($router_name);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $addRequest = new RouterOS\Request('/ip/hotspot/active/login');
        $client->sendSync(
            $addRequest
                ->setArgument('user', $customer['username'])
                ->setArgument('password', $customer['password'])
                ->setArgument('ip', $ip)
                ->setArgument('mac-address', $mac_address)
        );
    }

    function disconnect_customer($customer, $router_name)
    {
        $mikrotik = $this->info($router_name);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $printRequest = new RouterOS\Request(
            '/ip hotspot active print',
            RouterOS\Query::where('user', $customer['username'])
        );
        $id = $client->sendSync($printRequest)->getProperty('.id');
        $removeRequest = new RouterOS\Request('/ip/hotspot/active/remove');
        $client->sendSync(
            $removeRequest
                ->setArgument('numbers', $id)
        );
    }


    function update_plan($old_plan, $new_plan)
    {
        $mikrotik = $this->info($new_plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);

        $printRequest = new RouterOS\Request(
            '/ip hotspot user profile print .proplist=.id',
            RouterOS\Query::where('name', $old_plan['name_plan'])
        );
        $profileID = $client->sendSync($printRequest)->getProperty('.id');
        if (empty($profileID)) {
            $this->add_plan($new_plan);
        } else {
            $bw = ORM::for_table("tbl_bandwidth")->find_one($new_plan['id_bw']);
            if ($bw['rate_down_unit'] == 'Kbps') {
                $unitdown = 'K';
            } else {
                $unitdown = 'M';
            }
            if ($bw['rate_up_unit'] == 'Kbps') {
                $unitup = 'K';
            } else {
                $unitup = 'M';
            }
            $rate = $bw['rate_up'] . $unitup . "/" . $bw['rate_down'] . $unitdown;
            if (!empty(trim($bw['burst']))) {
                $rate .= ' ' . $bw['burst'];
            }
			if ($bw['rate_up'] == '0' || $bw['rate_down'] == '0') {
				$rate = '';
			}
            list($keepaliveTimeout, $idleTimeout) = $this->getProfileTimeouts($new_plan);

            $setRequest = new RouterOS\Request('/ip/hotspot/user/profile/set');
            $client->sendSync(
                $setRequest
                    ->setArgument('numbers', $profileID)
                    ->setArgument('name', $new_plan['name_plan'])
                    ->setArgument('shared-users', $new_plan['shared_users'])
                    ->setArgument('rate-limit', $rate)
                    ->setArgument('keepalive-timeout', $keepaliveTimeout)
                    ->setArgument('idle-timeout', $idleTimeout)
                    ->setArgument('on-login', $new_plan['on_login'])
                    ->setArgument('on-logout', $new_plan['on_logout'])
            );
        }
    }

    protected function getProfileTimeouts($plan)
    {
        $keepaliveTimeout = '';
        $idleTimeout = '';

        if (isset($plan['keepalive_timeout'])) {
            $keepaliveTimeout = trim((string) $plan['keepalive_timeout']);
        }
        if (isset($plan['idle_timeout'])) {
            $idleTimeout = trim((string) $plan['idle_timeout']);
        }

        $isTimeLimited = ($plan['typebp'] == 'Limited'
            && in_array($plan['limit_type'], ['Time_Limit', 'Both_Limit']));

        if ($keepaliveTimeout === '') {
            $keepaliveTimeout = $isTimeLimited ? '00:02:00' : 'none';
        }
        if ($idleTimeout === '') {
            $idleTimeout = $isTimeLimited ? '00:05:00' : 'none';
        }

        return [$keepaliveTimeout, $idleTimeout];
    }

    function remove_plan($plan)
    {
        $mikrotik = $this->info($plan['routers']);
        $client = $this->getClient($mikrotik['ip_address'], $mikrotik['username'], $mikrotik['password']);
        $printRequest = new RouterOS\Request(
            '/ip hotspot user profile print .proplist=.id',
            RouterOS\Query::where('name', $plan['name_plan'])
        );
        $profileID = $client->sendSync($printRequest)->getProperty('.id');
        $removeRequest = new RouterOS\Request('/ip/hotspot/user/profile/remove');
        $client->sendSync(
            $removeRequest
                ->setArgument('numbers', $profileID)
        );
    }

    function info($name)
    {
        return ORM::for_table('tbl_routers')->where('name', $name)->find_one();
    }

    function getClient($ip, $user, $pass)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        list($host, $port) = $this->parseRouterAddress($ip);
        $tries = [];

        if ($port !== null) {
            $port = (int) $port;
            if ($port === 8729) {
                foreach ($this->getTlsContexts() as $context) {
                    $tries[] = [$port, \PEAR2\Net\Transmitter\NetworkStream::CRYPTO_TLS, $context];
                }
            } else {
                $tries[] = [$port, \PEAR2\Net\Transmitter\NetworkStream::CRYPTO_OFF, null];
            }
        } else {
            $tries[] = [8728, \PEAR2\Net\Transmitter\NetworkStream::CRYPTO_OFF, null];
            foreach ($this->getTlsContexts() as $context) {
                $tries[] = [8729, \PEAR2\Net\Transmitter\NetworkStream::CRYPTO_TLS, $context];
            }
        }

        $lastException = null;
        foreach ($tries as $try) {
            try {
                return new RouterOS\Client($host, $user, $pass, $try[0], false, null, $try[1], $try[2]);
            } catch (\Exception $e) {
                $lastException = $e;
            }
        }

        if ($lastException !== null) {
            throw $lastException;
        }

        throw new \Exception('Unable to connect to MikroTik API');
    }

    protected function getTlsContexts()
    {
        $contexts = [];
        $cipherSets = [
            'DEFAULT:@SECLEVEL=0',
            'ADH:@SECLEVEL=0',
            'ADH',
        ];

        foreach ($cipherSets as $cipherSet) {
            $contexts[] = stream_context_create([
                'ssl' => [
                    'ciphers' => $cipherSet,
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true,
                ],
            ]);
        }

        return $contexts;
    }

    function parseRouterAddress($ip)
    {
        $ip = trim((string) $ip);
        if ($ip === '') {
            return ['', null];
        }

        if (preg_match('/^\[(.+)\](?::(\d+))?$/', $ip, $matches)) {
            return [$matches[1], isset($matches[2]) ? (int) $matches[2] : null];
        }

        if (preg_match('/^([^:]+):(\d+)$/', $ip, $matches)) {
            return [$matches[1], (int) $matches[2]];
        }

        return [$ip, null];
    }

    function removeHotspotUser($client, $username)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $printRequest = new RouterOS\Request(
            '/ip hotspot user print .proplist=.id',
            RouterOS\Query::where('name', $username)
        );
        $userID = $client->sendSync($printRequest)->getProperty('.id');
        $removeRequest = new RouterOS\Request('/ip/hotspot/user/remove');
        $client->sendSync(
            $removeRequest
                ->setArgument('numbers', $userID)
        );
    }

    function addHotspotUser($client, $plan, $customer)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $addRequest = new RouterOS\Request('/ip/hotspot/user/add');
        if ($plan['typebp'] == "Limited") {
            if ($plan['limit_type'] == "Time_Limit") {
                if ($plan['time_unit'] == 'Hrs')
                    $timelimit = $plan['time_limit'] . ":00:00";
                else
                    $timelimit = "00:" . $plan['time_limit'] . ":00";
                $client->sendSync(
                    $addRequest
                        ->setArgument('name', $customer['username'])
                        ->setArgument('profile', $plan['name_plan'])
                        ->setArgument('password', $customer['password'])
                        ->setArgument('comment', $customer['fullname'] . ' | ' . implode(', ', User::getBillNames($customer['id'])))
                        ->setArgument('email', $customer['email'])
                        ->setArgument('limit-uptime', $timelimit)
                );
            } else if ($plan['limit_type'] == "Data_Limit") {
                if ($plan['data_unit'] == 'GB')
                    $datalimit = $plan['data_limit'] . "000000000";
                else
                    $datalimit = $plan['data_limit'] . "000000";
                $client->sendSync(
                    $addRequest
                        ->setArgument('name', $customer['username'])
                        ->setArgument('profile', $plan['name_plan'])
                        ->setArgument('password', $customer['password'])
                        ->setArgument('comment', $customer['fullname'] . ' | ' . implode(', ', User::getBillNames($customer['id'])))
                        ->setArgument('email', $customer['email'])
                        ->setArgument('limit-bytes-total', $datalimit)
                );
            } else if ($plan['limit_type'] == "Both_Limit") {
                if ($plan['time_unit'] == 'Hrs')
                    $timelimit = $plan['time_limit'] . ":00:00";
                else
                    $timelimit = "00:" . $plan['time_limit'] . ":00";
                if ($plan['data_unit'] == 'GB')
                    $datalimit = $plan['data_limit'] . "000000000";
                else
                    $datalimit = $plan['data_limit'] . "000000";
                $client->sendSync(
                    $addRequest
                        ->setArgument('name', $customer['username'])
                        ->setArgument('profile', $plan['name_plan'])
                        ->setArgument('password', $customer['password'])
                        ->setArgument('comment', $customer['fullname'] . ' | ' . implode(', ', User::getBillNames($customer['id'])))
                        ->setArgument('email', $customer['email'])
                        ->setArgument('limit-uptime', $timelimit)
                        ->setArgument('limit-bytes-total', $datalimit)
                );
            }
        } else {
            $client->sendSync(
                $addRequest
                    ->setArgument('name', $customer['username'])
                    ->setArgument('profile', $plan['name_plan'])
                    ->setArgument('comment', $customer['fullname'] . ' | ' . implode(', ', User::getBillNames($customer['id'])))
                    ->setArgument('email', $customer['email'])
                    ->setArgument('password', $customer['password'])
            );
        }
    }

    function setHotspotUser($client, $user, $pass)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $printRequest = new RouterOS\Request('/ip/hotspot/user/print');
        $printRequest->setArgument('.proplist', '.id');
        $printRequest->setQuery(RouterOS\Query::where('name', $user));
        $id = $client->sendSync($printRequest)->getProperty('.id');

        $setRequest = new RouterOS\Request('/ip/hotspot/user/set');
        $setRequest->setArgument('numbers', $id);
        $setRequest->setArgument('password', $pass);
        $client->sendSync($setRequest);
    }

    function setHotspotUserPackage($client, $username, $plan_name)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $printRequest = new RouterOS\Request('/ip/hotspot/user/print');
        $printRequest->setArgument('.proplist', '.id');
        $printRequest->setQuery(RouterOS\Query::where('name', $username));
        $id = $client->sendSync($printRequest)->getProperty('.id');

        $setRequest = new RouterOS\Request('/ip/hotspot/user/set');
        $setRequest->setArgument('numbers', $id);
        $setRequest->setArgument('profile', $plan_name);
        $client->sendSync($setRequest);
    }

    protected function getHotspotUserId($client, $username)
    {
        $printRequest = new RouterOS\Request('/ip/hotspot/user/print');
        $printRequest->setArgument('.proplist', '.id');
        $printRequest->setQuery(RouterOS\Query::where('name', $username));

        return $client->sendSync($printRequest)->getProperty('.id');
    }

    protected function getHotspotUserState($client, $username)
    {
        $printRequest = new RouterOS\Request('/ip/hotspot/user/print');
        $printRequest->setArgument('.proplist', '.id,limit-uptime,limit-bytes-total,uptime');
        $printRequest->setQuery(RouterOS\Query::where('name', $username));

        $response = $client->sendSync($printRequest);

        return [
            'id' => $response->getProperty('.id'),
            'limit_uptime' => trim((string) $response->getProperty('limit-uptime')),
            'limit_bytes_total' => trim((string) $response->getProperty('limit-bytes-total')),
            'uptime' => trim((string) $response->getProperty('uptime')),
        ];
    }

    protected function getRemainingHotspotLimitUptime($client, $plan, $username, array $userState)
    {
        if ($plan['typebp'] !== 'Limited' || !in_array($plan['limit_type'], ['Time_Limit', 'Both_Limit'])) {
            return null;
        }

        $sessionTimeLeft = $this->getHotspotActiveSessionTimeLeft($client, $username);
        if ($sessionTimeLeft !== null) {
            return $sessionTimeLeft;
        }

        $limitSeconds = $this->routerOsTimeToSeconds($userState['limit_uptime']);
        if ($limitSeconds <= 0) {
            return null;
        }

        $usedSeconds = $this->routerOsTimeToSeconds($userState['uptime']);
        $remainingSeconds = max($limitSeconds - $usedSeconds, 0);

        if ($remainingSeconds <= 0) {
            return null;
        }

        return $this->secondsToRouterOsTime($remainingSeconds);
    }

    protected function getHotspotActiveSessionTimeLeft($client, $username)
    {
        $onlineRequest = new RouterOS\Request('/ip/hotspot/active/print');
        $onlineRequest->setArgument('.proplist', 'session-time-left');
        $onlineRequest->setQuery(RouterOS\Query::where('user', $username));

        $sessions = $client->sendSync($onlineRequest);
        $remainingSeconds = null;

        foreach ($sessions as $session) {
            if ($session->getType() !== RouterOS\Response::TYPE_DATA) {
                continue;
            }

            $sessionTimeLeft = trim((string) $session->getProperty('session-time-left'));
            if ($sessionTimeLeft === '') {
                continue;
            }

            $sessionSeconds = $this->routerOsTimeToSeconds($sessionTimeLeft);
            if ($sessionSeconds <= 0) {
                continue;
            }

            if ($remainingSeconds === null || $sessionSeconds < $remainingSeconds) {
                $remainingSeconds = $sessionSeconds;
            }
        }

        if ($remainingSeconds === null) {
            return null;
        }

        return $this->secondsToRouterOsTime($remainingSeconds);
    }

    protected function routerOsTimeToSeconds($value)
    {
        $value = trim((string) $value);
        if ($value === '' || $value === '0') {
            return 0;
        }

        if (preg_match('/^(?:(\d+)w)?(?:(\d+)d)?(?:(\d+):(\d{2}):(\d{2}))$/', $value, $matches)) {
            return ((int) ($matches[1] ?: 0) * 7 * 24 * 60 * 60)
                + ((int) ($matches[2] ?: 0) * 24 * 60 * 60)
                + ((int) $matches[3] * 60 * 60)
                + ((int) $matches[4] * 60)
                + (int) $matches[5];
        }

        if (preg_match('/^(\d+):(\d{2}):(\d{2})$/', $value, $matches)) {
            return ((int) $matches[1] * 60 * 60)
                + ((int) $matches[2] * 60)
                + (int) $matches[3];
        }

        if (preg_match_all('/(\d+)([wdhms])/', $value, $matches, PREG_SET_ORDER)) {
            $seconds = 0;
            foreach ($matches as $match) {
                switch ($match[2]) {
                    case 'w':
                        $seconds += (int) $match[1] * 7 * 24 * 60 * 60;
                        break;
                    case 'd':
                        $seconds += (int) $match[1] * 24 * 60 * 60;
                        break;
                    case 'h':
                        $seconds += (int) $match[1] * 60 * 60;
                        break;
                    case 'm':
                        $seconds += (int) $match[1] * 60;
                        break;
                    case 's':
                        $seconds += (int) $match[1];
                        break;
                }
            }
            return $seconds;
        }

        return 0;
    }

    protected function secondsToRouterOsTime($seconds)
    {
        $seconds = max(0, (int) $seconds);
        $weeks = intdiv($seconds, 7 * 24 * 60 * 60);
        $seconds -= $weeks * 7 * 24 * 60 * 60;
        $days = intdiv($seconds, 24 * 60 * 60);
        $seconds -= $days * 24 * 60 * 60;
        $hours = intdiv($seconds, 60 * 60);
        $seconds -= $hours * 60 * 60;
        $minutes = intdiv($seconds, 60);
        $seconds -= $minutes * 60;

        $prefix = '';
        if ($weeks > 0) {
            $prefix .= $weeks . 'w';
        }
        if ($days > 0) {
            $prefix .= $days . 'd';
        }

        return $prefix . sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);
    }

    function removeHotspotActiveUser($client, $username)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $onlineRequest = new RouterOS\Request('/ip/hotspot/active/print');
        $onlineRequest->setArgument('.proplist', '.id');
        $onlineRequest->setQuery(RouterOS\Query::where('user', $username));
        $sessions = $client->sendSync($onlineRequest);

        foreach ($sessions as $session) {
            if ($session->getType() !== RouterOS\Response::TYPE_DATA) {
                continue;
            }

            $id = $session->getProperty('.id');
            if (empty($id)) {
                continue;
            }

            $removeRequest = new RouterOS\Request('/ip/hotspot/active/remove');
            $removeRequest->setArgument('numbers', $id);
            $client->sendSync($removeRequest);
        }
    }

    function getIpHotspotUser($client, $username)
    {
        global $_app_stage;
        if ($_app_stage == 'Demo') {
            return null;
        }
        $printRequest = new RouterOS\Request(
            '/ip hotspot active print',
            RouterOS\Query::where('user', $username)
        );
        return $client->sendSync($printRequest)->getProperty('address');
    }
}
