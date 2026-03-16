<div class="box box-solid ">
    <div class="box-header">
        <i class="fa fa-inbox"></i>

        <h3 class="box-title">{Lang::T('Total Monthly Sales')}</h3>

        <div class="box-tools pull-right">
            <button type="button" class="btn bg-teal btn-sm" data-widget="collapse"><i class="fa fa-minus"></i>
            </button>
            <a href="{Text::url('dashboard&refresh')}" class="btn bg-teal btn-sm"><i class="fa fa-refresh"></i>
            </a>
        </div>
    </div>
    <div class="box-body border-radius-none">
        <canvas class="chart" id="salesChart" style="height: 250px;"></canvas>
    </div>
</div>

<script type="text/javascript">
    {literal}
        document.addEventListener("DOMContentLoaded", function() {
            var monthlySales = JSON.parse('{/literal}{$monthlySales|json_encode}{literal}');
            var currencyCode = '{/literal}{$currency_code}{literal}';
            var decPoint = '{/literal}{$dec_point}{literal}';
            var thousandsSep = '{/literal}{$thousands_sep}{literal}';

            var monthNames = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];

            var labels = [];
            var data = [];

            for (var i = 1; i <= 12; i++) {
                var month = findMonthData(monthlySales, i);
                labels.push(month ? monthNames[i - 1] : monthNames[i - 1].substring(0, 3));
                data.push(month ? month.totalSales : 0);
            }

            // Format currency function
            function formatCurrency(amount) {
                var formattedAmount = amount.toFixed(2).replace('.', decPoint);
                var parts = formattedAmount.split(decPoint);
                parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, thousandsSep);
                return currencyCode + ' ' + parts.join(decPoint);
            }

            var ctx = document.getElementById('salesChart').getContext('2d');
            var chart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Monthly Sales',
                        data: data,
                        backgroundColor: 'rgba(54, 162, 235, 0.5)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        x: {
                            grid: {
                                display: false
                            }
                        },
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(0, 0, 0, 0.1)'
                            },
                            ticks: {
                                callback: function(value) {
                                    return formatCurrency(value);
                                }
                            }
                        }
                    },
                    plugins: {
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return 'Sales: ' + formatCurrency(context.parsed.y);
                                }
                            }
                        },
                        legend: {
                            display: true,
                            labels: {
                                generateLabels: function(chart) {
                                    return [{
                                        text: 'Monthly Sales (' + currencyCode + ')',
                                        fillStyle: 'rgba(54, 162, 235, 0.5)',
                                        strokeStyle: 'rgba(54, 162, 235, 1)',
                                        lineWidth: 1
                                    }];
                                }
                            }
                        }
                    }
                }
            });
        });

        function findMonthData(monthlySales, month) {
            for (var i = 0; i < monthlySales.length; i++) {
                if (monthlySales[i].month === month) {
                    return monthlySales[i];
                }
            }
            return null;
        }
    {/literal}
</script>