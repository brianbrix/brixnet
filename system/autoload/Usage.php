<?php

/**
 * Usage Analytics Helper Class
 * Provides methods to calculate and format bandwidth usage from rad_acct table
 */

class Usage
{
    /**
     * Get total usage for a customer within date range
     */
    public static function getCustomerUsage($customer_id, $date_from, $date_to)
    {
        // Get customer username
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return ['data_in' => 0, 'data_out' => 0, 'data_total' => 0, 'sessions' => 0];
        }
        
        $query = ORM::for_table('rad_acct')
            ->where('username', $customer['username'])
            ->where_gte('DATE(dateAdded)', $date_from)
            ->where_lte('DATE(dateAdded)', $date_to)
            ->raw_query('SELECT SUM(acctinputoctets) as total_in, SUM(acctoutputoctets) as total_out, COUNT(*) as total_sessions')
            ->find_one();
        
        $data_in = $query ? ($query['total_in'] ?? 0) : 0;
        $data_out = $query ? ($query['total_out'] ?? 0) : 0;
        
        return [
            'data_in' => (int)$data_in,
            'data_out' => (int)$data_out,
            'data_total' => (int)$data_in + (int)$data_out,
            'sessions' => $query ? ($query['total_sessions'] ?? 0) : 0
        ];
    }
    
    /**
     * Get daily usage breakdown for a customer
     */
    public static function getDailyUsage($customer_id, $date_from, $date_to)
    {
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return [];
        }
        
        $daily = ORM::for_table('rad_acct')
            ->select_raw('DATE(dateAdded) as date')
            ->select_raw('SUM(acctinputoctets) as data_in')
            ->select_raw('SUM(acctoutputoctets) as data_out')
            ->select_raw('SUM(acctinputoctets) + SUM(acctoutputoctets) as total_bytes')
            ->select_raw('COUNT(*) as sessions')
            ->where('username', $customer['username'])
            ->where_gte('DATE(dateAdded)', $date_from)
            ->where_lte('DATE(dateAdded)', $date_to)
            ->group_by_expr('DATE(dateAdded)')
            ->order_by_desc('date')
            ->find_many();
        
        $result = [];
        foreach ($daily as $row) {
            $result[] = [
                'date' => $row['date'],
                'data_in' => (int)$row['data_in'],
                'data_out' => (int)$row['data_out'],
                'total_bytes' => (int)$row['total_bytes'],
                'sessions' => $row['sessions'],
                'data_in_formatted' => self::formatBytes($row['data_in']),
                'data_out_formatted' => self::formatBytes($row['data_out']),
                'total_formatted' => self::formatBytes($row['total_bytes'])
            ];
        }
        
        return $result;
    }
    
    /**
     * Get hourly usage for last 24 hours
     */
    public static function getHourlyUsage($customer_id, $date = null)
    {
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return [];
        }
        
        if (!$date) {
            $date = date('Y-m-d');
        }
        
        $hourly = ORM::for_table('rad_acct')
            ->select_raw('HOUR(dateAdded) as hour')
            ->select_raw('SUM(acctinputoctets) as data_in')
            ->select_raw('SUM(acctoutputoctets) as data_out')
            ->select_raw('SUM(acctinputoctets) + SUM(acctoutputoctets) as total_bytes')
            ->select_raw('COUNT(*) as sessions')
            ->where('username', $customer['username'])
            ->where_raw("DATE(dateAdded) = ?", [$date])
            ->group_by_expr('HOUR(dateAdded)')
            ->order_by_asc('hour')
            ->find_many();
        
        $result = [];
        foreach ($hourly as $row) {
            $result[] = [
                'hour' => str_pad($row['hour'], 2, '0', STR_PAD_LEFT),
                'data_in' => (int)$row['data_in'],
                'data_out' => (int)$row['data_out'],
                'total_bytes' => (int)$row['total_bytes'],
                'sessions' => $row['sessions'],
                'data_in_formatted' => self::formatBytes($row['data_in']),
                'data_out_formatted' => self::formatBytes($row['data_out']),
                'total_formatted' => self::formatBytes($row['total_bytes'])
            ];
        }
        
        return $result;
    }
    
    /**
     * Format bytes to human readable format (B, KB, MB, GB, TB)
     */
    public static function formatBytes($bytes, $precision = 2)
    {
        $bytes = (int)$bytes;
        $units = array('B', 'KB', 'MB', 'GB', 'TB');
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
    
    /**
     * Get percentage of plan usage (if plan has limit)
     */
    public static function getUsagePercentage($usage_bytes, $plan_limit_bytes)
    {
        if ($plan_limit_bytes <= 0) {
            return 0; // Unlimited
        }
        
        $percentage = ($usage_bytes / $plan_limit_bytes) * 100;
        return min($percentage, 100);
    }
    
    /**
     * Get top customers by usage
     */
    public static function getTopCustomers($limit = 10, $date_from = null, $date_to = null)
    {
        if (!$date_from) {
            $date_from = date('Y-m-d', strtotime('-30 days'));
        }
        if (!$date_to) {
            $date_to = date('Y-m-d');
        }
        
        $customers = ORM::for_table('rad_acct')
            ->select_raw('username')
            ->select_raw('SUM(acctinputoctets) + SUM(acctoutputoctets) as total_bytes')
            ->where_gte('DATE(dateAdded)', $date_from)
            ->where_lte('DATE(dateAdded)', $date_to)
            ->group_by('username')
            ->order_by_desc('total_bytes')
            ->limit($limit)
            ->find_many();
        
        $result = [];
        foreach ($customers as $row) {
            $cust = ORM::for_table('tbl_customers')->where('username', $row['username'])->find_one();
            if ($cust) {
                $result[] = [
                    'id' => $cust['id'],
                    'username' => $row['username'],
                    'fullname' => $cust['fullname'],
                    'total_bytes' => (int)$row['total_bytes'],
                    'total_formatted' => self::formatBytes($row['total_bytes'])
                ];
            }
        }
        
        return $result;
    }
}
