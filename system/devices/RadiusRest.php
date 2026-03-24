<?php

class RadiusRest {

    // show Description
    function description()
    {
        return [
            'title' => 'Radius Rest API',
            'description' => 'This devices will handle Radius Connection using Rest API',
            'author' => 'ibnu maksum',
            'url' => [
                'Wiki Tutorial' => 'https://github.com/brianbrix/brixnet/wiki/FreeRadius-Rest',
                'Telegram' => 'https://t.me/brixnet',
                'Donate' => 'https://paypal.me/ibnux'
            ]
        ];
    }

    // Add Customer to Mikrotik/Device
    function add_customer($customer, $plan)
    {
    }
	
	function sync_customer($customer, $plan)
    {	
        $this->add_customer($customer, $plan);
    }

    // Remove Customer to Mikrotik/Device
    function remove_customer($customer, $plan)
    {
        // set zero data usage
        if ($plan['typebp'] == "Limited" && ($plan['limit_type'] == "Data_Limit" || $plan['limit_type'] == "Both_Limit")) {
            $cs = ORM::for_table("radacct")->where('username', $customer['username'])->findMany();
            foreach ($cs as $c) {
                $c->acctoutputoctets = 0;
                $c->acctinputoctets = 0;
                $c->save();
            }
        }
    }

    // customer change username
    public function change_username($plan, $from, $to)
    {
    }

    // Add Plan to Mikrotik/Device
    function add_plan($plan)
    {
    }

    // Update Plan to Mikrotik/Device
    function update_plan($old_name, $plan)
    {
    }

    // Remove Plan from Mikrotik/Device
    function remove_plan($plan)
    {
    }

    // check if customer is online
    function online_customer($customer, $router_name)
    {
        // Active sessions are radacct rows without acctstoptime.
        // Cron closes stale sessions by setting acctstoptime.
        global $config;

        $acct = ORM::for_table('radacct')
            ->where('username', $customer['username'])
            ->where_raw("(acctstoptime IS NULL OR acctstoptime = '0000-00-00 00:00:00')")
            ->order_by_desc('acctupdatetime')
            ->order_by_desc('acctstarttime')
            ->find_one();

        if (empty($acct)) {
            return false;
        }

        // Use the configured interim-update interval (minutes) as the freshness window.
        // If not set, default to 30 minutes. Double it as tolerance for one full cycle.
        $interim_minutes = (!empty($config['frrest_interim_update']) && $config['frrest_interim_update'] > 0)
            ? (int)$config['frrest_interim_update']
            : 30;
        $stale_threshold = $interim_minutes * 60 * 2;

        $updateTime = $acct['acctupdatetime'];
        if (!empty($updateTime) && $updateTime !== '0000-00-00 00:00:00') {
            $lastUpdate = strtotime($updateTime);
            if ($lastUpdate !== false) {
                return (time() - $lastUpdate) < $stale_threshold;
            }
        }

        $startTime = $acct['acctstarttime'];
        if (!empty($startTime) && $startTime !== '0000-00-00 00:00:00') {
            $lastUpdate = strtotime($startTime);
            if ($lastUpdate !== false) {
                return (time() - $lastUpdate) < $stale_threshold;
            }
        }

        return true;
    }

    // make customer online
    function connect_customer($customer, $ip, $mac_address, $router_name)
    {
    }

    // make customer disconnect
    function disconnect_customer($customer, $router_name)
    {
    }

}