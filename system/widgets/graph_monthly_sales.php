<?php

class graph_monthly_sales
{
    public function getWidget()
    {
        global $CACHE_PATH, $ui, $config;

        $cacheMSfile = $CACHE_PATH . File::pathFixer('/monthlySales.temp');
        //Cache for 12 hours
        if (file_exists($cacheMSfile) && time() - filemtime($cacheMSfile) < 43200) {
            $monthlySales = json_decode(file_get_contents($cacheMSfile), true);
        } else {
            // Query to retrieve monthly data - Fixed and enhanced query
            $results = ORM::for_table('tbl_transactions')
                ->select_expr('MONTH(recharged_on)', 'month')
                ->select_expr('SUM(tbl_transactions.price)', 'total')
                ->where_raw("YEAR(recharged_on) = YEAR(CURRENT_DATE())")
                ->where_raw('recharged_on IS NOT NULL')
                ->where_raw('recharged_on != "0000-00-00"')
                ->where_not_equal('method', 'Customer - Balance')
                ->where_not_equal('method', 'Recharge Balance - Administrator')
                ->where_not_equal('method', 'Admin')
                ->inner_join('tbl_customers', ['tbl_transactions.user_id', '=', 'tbl_customers.id'])
                ->where('tbl_customers.exclude_from_stats', 0)
                ->where('tbl_customers.status', 'Active')
                ->group_by_expr('MONTH(recharged_on)')
                ->order_by_expr('MONTH(recharged_on)')
                ->find_many();

            // Create an array to hold the monthly sales data
            $monthlySales = array();

            // Iterate over the results and populate the array
            foreach ($results as $result) {
                $month = $result->month;
                $totalSales = $result->total;

                $monthlySales[$month] = array(
                    'month' => $month,
                    'totalSales' => floatval($totalSales)
                );
            }

            // Fill in missing months with zero sales
            for ($month = 1; $month <= 12; $month++) {
                if (!isset($monthlySales[$month])) {
                    $monthlySales[$month] = array(
                        'month' => $month,
                        'totalSales' => 0
                    );
                }
            }

            // Sort the array by month
            ksort($monthlySales);

            // Reindex the array
            $monthlySales = array_values($monthlySales);
            file_put_contents($cacheMSfile, json_encode($monthlySales));
        }

        // Pass currency configuration to template
        $ui->assign('currency_code', isset($config['currency_code']) ? $config['currency_code'] : '$');
        $ui->assign('dec_point', isset($config['dec_point']) ? $config['dec_point'] : '.');
        $ui->assign('thousands_sep', isset($config['thousands_sep']) ? $config['thousands_sep'] : ',');
        $ui->assign('monthlySales', $monthlySales);
        
        return $ui->fetch('widget/graph_monthly_sales.tpl');
    }
}
