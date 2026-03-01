<?php

/**
 * Usage Analytics Helper Class
 * 
 * Provides methods to calculate and format bandwidth usage from FreeRADIUS radacct table
 */
class Usage
{
    /**
     * Get diagnostic info about which table is being used
     */
    public static function getTableInfo()
    {
        return [
            'table' => 'radacct',
            'connection' => 'default (nuxbill)',
            'input_column' => 'acctinputoctets',
            'output_column' => 'acctoutputoctets',
            'date_column' => 'acctstarttime'
        ];
    }

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
        
        try {
            // Use ORM query builder
            $query = ORM::for_table('radacct')
                ->select_expr('COALESCE(SUM(acctinputoctets), 0)', 'total_in')
                ->select_expr('COALESCE(SUM(acctoutputoctets), 0)', 'total_out')
                ->select_expr('COUNT(*)', 'total_sessions')
                ->where('username', $customer['username'])
                ->where_gte('acctstarttime', $date_from . ' 00:00:00')
                ->where_lte('acctstarttime', $date_to . ' 23:59:59')
                ->find_one();
            
            if (!$query) {
                return ['data_in' => 0, 'data_out' => 0, 'data_total' => 0, 'sessions' => 0];
            }
            
            $data_in = $query['total_in'] ?? 0;
            $data_out = $query['total_out'] ?? 0;
            
            return [
                'data_in' => (int)$data_in,
                'data_out' => (int)$data_out,
                'data_total' => (int)$data_in + (int)$data_out,
                'sessions' => $query['total_sessions'] ?? 0
            ];
        } catch (Exception $e) {
            return ['data_in' => 0, 'data_out' => 0, 'data_total' => 0, 'sessions' => 0];
        }
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
        
        try {
            $daily = ORM::for_table('radacct')
                ->select_expr('DATE(acctstarttime)', 'date')
                ->select_expr('COALESCE(SUM(acctinputoctets), 0)', 'data_in')
                ->select_expr('COALESCE(SUM(acctoutputoctets), 0)', 'data_out')
                ->select_expr('COALESCE(SUM(acctinputoctets), 0) + COALESCE(SUM(acctoutputoctets), 0)', 'total_bytes')
                ->select_expr('COUNT(*)', 'sessions')
                ->where('username', $customer['username'])
                ->where_gte('acctstarttime', $date_from . ' 00:00:00')
                ->where_lte('acctstarttime', $date_to . ' 23:59:59')
                ->group_by_expr('DATE(acctstarttime)')
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
        } catch (Exception $e) {
            return [];
        }
    }

    /**
     * Get hourly usage breakdown
     */
    public static function getHourlyUsage($customer_id, $date)
    {
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return [];
        }
        
        try {
            $hourly = ORM::for_table('radacct')
                ->select_expr('HOUR(acctstarttime)', 'hour')
                ->select_expr('SUM(acctinputoctets)', 'data_in')
                ->select_expr('SUM(acctoutputoctets)', 'data_out')
                ->select_expr('COUNT(*)', 'sessions')
                ->where('username', $customer['username'])
                ->where_raw('DATE(acctstarttime) = ?', [$date])
                ->group_by_expr('HOUR(acctstarttime)')
                ->order_by_asc('hour')
                ->find_many();
            
            $result = [];
            for ($i = 0; $i < 24; $i++) {
                $found = false;
                foreach ($hourly as $row) {
                    if ((int)$row['hour'] == $i) {
                        $data_in = (int)($row['data_in'] ?? 0);
                        $data_out = (int)($row['data_out'] ?? 0);
                        $result[] = [
                            'hour' => str_pad($i, 2, '0', STR_PAD_LEFT) . ':00',
                            'data_in' => $data_in,
                            'data_out' => $data_out,
                            'total' => $data_in + $data_out,
                            'sessions' => $row['sessions']
                        ];
                        $found = true;
                        break;
                    }
                }
                if (!$found) {
                    $result[] = [
                        'hour' => str_pad($i, 2, '0', STR_PAD_LEFT) . ':00',
                        'data_in' => 0,
                        'data_out' => 0,
                        'total' => 0,
                        'sessions' => 0
                    ];
                }
            }
            
            return $result;
        } catch (Exception $e) {
            return [];
        }
    }

    /**
     * Format bytes to human readable format
     */
    public static function formatBytes($bytes, $precision = 2)
    {
        $bytes = (int)$bytes;
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }

    /**
     * Get usage percentage
     */
    public static function getUsagePercentage($used, $total)
    {
        if ($total == 0) {
            return 0;
        }
        return round(($used / $total) * 100, 2);
    }

    /**
     * Get top customers by usage
     */
    public static function getTopCustomers($limit = 10, $date_from, $date_to)
    {
        try {
            $customers = ORM::for_table('radacct')
                ->select('username')
                ->select_expr('SUM(acctinputoctets)', 'data_in')
                ->select_expr('SUM(acctoutputoctets)', 'data_out')
                ->select_expr('SUM(acctinputoctets) + SUM(acctoutputoctets)', 'total_bytes')
                ->where_gte('acctstarttime', $date_from . ' 00:00:00')
                ->where_lte('acctstarttime', $date_to . ' 23:59:59')
                ->group_by('username')
                ->order_by_desc('total_bytes')
                ->limit($limit)
                ->find_many();
            
            $result = [];
            foreach ($customers as $row) {
                $result[] = [
                    'username' => $row['username'],
                    'data_in' => (int)$row['data_in'],
                    'data_out' => (int)$row['data_out'],
                    'total_bytes' => (int)$row['total_bytes'],
                    'data_in_formatted' => self::formatBytes($row['data_in']),
                    'data_out_formatted' => self::formatBytes($row['data_out']),
                    'total_formatted' => self::formatBytes($row['total_bytes'])
                ];
            }
            
            return $result;
        } catch (Exception $e) {
            return [];
        }
    }
}
