<?php

/**
 * Usage Analytics Helper Class
 * 
 * Provides methods to calculate and format bandwidth usage
 * Supports both FreeRADIUS (radacct) and RadiusRest (rad_acct) accounting systems
 */
class Usage
{
    private static $table_name = null;
    private static $input_column = null;
    private static $output_column = null;
    private static $date_column = null;
    private static $db_connection = null;

    /**
     * Initialize accounting table configuration based on available tables
     */
    private static function initializeTable()
    {
        if (self::$table_name !== null) {
            return;
        }

        // Try FreeRADIUS radacct table first (with radius DB connection)
        try {
            $result = ORM::for_table('radacct', 'radius')->limit(1)->find_many();
            if (!empty($result)) {
                self::$table_name = 'radacct';
                self::$db_connection = 'radius';
                self::$input_column = 'acctinputoctets';
                self::$output_column = 'acctoutputoctets';
                self::$date_column = 'acctstarttime';
                return;
            }
        } catch (Exception $e) {
            // FreeRADIUS not available
        }

        // Try RadiusRest rad_acct table  
        try {
            $result = ORM::for_table('rad_acct')->limit(1)->find_many();
            if (!empty($result)) {
                self::$table_name = 'rad_acct';
                self::$db_connection = null;
                self::$input_column = 'acctInputOctets';
                self::$output_column = 'acctOutputOctets';
                self::$date_column = 'dateAdded';
                return;
            }
        } catch (Exception $e) {
            // RadiusRest not available
        }

        // Default to RadiusRest if nothing found (most likely scenario)
        self::$table_name = 'rad_acct';
        self::$db_connection = null;
        self::$input_column = 'acctInputOctets';
        self::$output_column = 'acctOutputOctets';
        self::$date_column = 'dateAdded';
    }

    /**
     * Get total usage for a customer within date range
     */
    public static function getCustomerUsage($customer_id, $date_from, $date_to)
    {
        self::initializeTable();
        
        // Get customer username
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return ['data_in' => 0, 'data_out' => 0, 'data_total' => 0, 'sessions' => 0];
        }
        
        try {
            $table_obj = ORM::for_table(self::$table_name, self::$db_connection);
            $query = $table_obj
                ->where('username', $customer['username'])
                ->where_gte('DATE(' . self::$date_column . ')', $date_from)
                ->where_lte('DATE(' . self::$date_column . ')', $date_to)
                ->select_raw('SUM(' . self::$input_column . ') as total_in')
                ->select_raw('SUM(' . self::$output_column . ') as total_out')
                ->select_raw('COUNT(*) as total_sessions')
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
        self::initializeTable();
        
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return [];
        }
        
        try {
            $daily = ORM::for_table(self::$table_name, self::$db_connection)
                ->select_raw('DATE(' . self::$date_column . ') as date')
                ->select_raw('SUM(' . self::$input_column . ') as data_in')
                ->select_raw('SUM(' . self::$output_column . ') as data_out')
                ->select_raw('SUM(' . self::$input_column . ') + SUM(' . self::$output_column . ') as total_bytes')
                ->select_raw('COUNT(*) as sessions')
                ->where('username', $customer['username'])
                ->where_gte('DATE(' . self::$date_column . ')', $date_from)
                ->where_lte('DATE(' . self::$date_column . ')', $date_to)
                ->group_by_expr('DATE(' . self::$date_column . ')')
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
        self::initializeTable();
        
        $customer = ORM::for_table('tbl_customers')->find_one($customer_id);
        if (!$customer) {
            return [];
        }
        
        try {
            $hourly = ORM::for_table(self::$table_name, self::$db_connection)
                ->select_raw('HOUR(' . self::$date_column . ') as hour')
                ->select_raw('SUM(' . self::$input_column . ') as data_in')
                ->select_raw('SUM(' . self::$output_column . ') as data_out')
                ->select_raw('COUNT(*) as sessions')
                ->where('username', $customer['username'])
                ->where_gte('DATE(' . self::$date_column . ')', $date)
                ->where_lte('DATE(' . self::$date_column . ')', $date)
                ->group_by_expr('HOUR(' . self::$date_column . ')')
                ->order_by_asc('hour')
                ->find_many();
            
            $result = [];
            for ($i = 0; $i < 24; $i++) {
                $found = false;
                foreach ($hourly as $row) {
                    if ((int)$row['hour'] == $i) {
                        $result[] = [
                            'hour' => str_pad($i, 2, '0', STR_PAD_LEFT) . ':00',
                            'data_in' => (int)$row['data_in'],
                            'data_out' => (int)$row['data_out'],
                            'total' => (int)$row['data_in'] + (int)$row['data_out'],
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
        self::initializeTable();
        
        try {
            $customers = ORM::for_table(self::$table_name, self::$db_connection)
                ->select_raw('username')
                ->select_raw('SUM(' . self::$input_column . ') as data_in')
                ->select_raw('SUM(' . self::$output_column . ') as data_out')
                ->select_raw('SUM(' . self::$input_column . ') + SUM(' . self::$output_column . ') as total_bytes')
                ->where_gte('DATE(' . self::$date_column . ')', $date_from)
                ->where_lte('DATE(' . self::$date_column . ')', $date_to)
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
