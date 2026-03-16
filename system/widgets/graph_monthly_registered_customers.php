<?php

class graph_monthly_registered_customers
{
    public function getWidget()
    {
        global $CACHE_PATH,$ui;

        $cacheMRfile = $CACHE_PATH . File::pathFixer('/monthlyRegistered.temp');
        //Compatibility for old path
        if (file_exists($oldCacheMRfile = str_replace($CACHE_PATH, '', $cacheMRfile))) {
            rename($oldCacheMRfile, $cacheMRfile);
        }
        
        //Cache for 1 hour
        if (file_exists($cacheMRfile) && time() - filemtime($cacheMRfile) < 3600) {
            $monthlyRegistered = json_decode(file_get_contents($cacheMRfile), true);
        } else {
            //Monthly Registered Customers - Fixed query
            $result = ORM::for_table('tbl_customers')
                ->select_expr('MONTH(created_at)', 'month')
                ->select_expr('COUNT(*)', 'count')
                ->where_raw('YEAR(created_at) = YEAR(NOW())')
                ->where_raw('created_at IS NOT NULL')
                ->where_raw('created_at != "0000-00-00 00:00:00"')
                ->where('exclude_from_stats', 0)
                ->group_by_expr('MONTH(created_at)')
                ->order_by_expr('MONTH(created_at)')
                ->find_many();

            $monthlyRegistered = [];
            
            // Ensure all months are represented with 0 if no data
            for ($month = 1; $month <= 12; $month++) {
                $count = 0;
                foreach ($result as $row) {
                    if ($row->month == $month) {
                        $count = $row->count;
                        break;
                    }
                }
                $monthlyRegistered[] = [
                    'date' => $month,
                    'count' => $count
                ];
            }
            
            file_put_contents($cacheMRfile, json_encode($monthlyRegistered));
        }
        $ui->assign('monthlyRegistered', $monthlyRegistered);
        return $ui->fetch('widget/graph_monthly_registered_customers.tpl');
    }
}