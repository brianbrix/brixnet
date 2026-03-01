{include file="admin/header.tpl"}

<div class="row">
    <div class="col-md-12">
        <div class="box box-primary">
            <div class="box-header with-border">
                <h3 class="box-title">
                    <i class="fa fa-bar-chart"></i> {Lang::T('Customer Usage Details')} - {$customer['username']}
                </h3>
                <div class="box-tools pull-right">
                    <a href="{Text::url('usage')}" class="btn btn-default btn-sm">
                        <i class="fa fa-arrow-left"></i> {Lang::T('Back')}
                    </a>
                </div>
            </div>
            
            <div class="box-body">
                <!-- Customer Info -->
                <div class="row" style="margin-bottom: 20px;">
                    <div class="col-md-6">
                        <h4>{Lang::T('Customer Information')}</h4>
                        <table class="table table-condensed">
                            <tr>
                                <td width="30%"><strong>{Lang::T('Username')}</strong></td>
                                <td>{$customer['username']}</td>
                            </tr>
                            <tr>
                                <td><strong>{Lang::T('Full Name')}</strong></td>
                                <td>{$customer['fullname']}</td>
                            </tr>
                            <tr>
                                <td><strong>{Lang::T('Email')}</strong></td>
                                <td>{$customer['email']}</td>
                            </tr>
                            <tr>
                                <td><strong>{Lang::T('Status')}</strong></td>
                                <td>
                                    {if $customer['status'] == 'Active'}
                                        <span class="label label-success">{Lang::T('Active')}</span>
                                    {elseif $customer['status'] == 'Banned'}
                                        <span class="label label-danger">{Lang::T('Banned')}</span>
                                    {else}
                                        <span class="label label-warning">{$customer['status']}</span>
                                    {/if}
                                </td>
                            </tr>
                        </table>
                    </div>
                    
                    <div class="col-md-6">
                        <h4>{Lang::T('Statistical Summary')}</h4>
                        <div class="row">
                            <div class="col-xs-6">
                                <div class="info-box" style="margin-bottom: 10px;">
                                    <span class="info-box-icon bg-blue" style="border-radius: 4px;"><i class="fa fa-cube"></i></span>
                                    <div class="info-box-content" style="margin-left: 50px;">
                                        <span class="info-box-text" style="color: #555;">{Lang::T('Total Data')}</span>
                                        <span class="info-box-number" style="font-size: 20px; color: #0066cc;">{$stats['total_data_formatted']}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="col-xs-6">
                                <div class="info-box" style="margin-bottom: 10px;">
                                    <span class="info-box-icon bg-green" style="border-radius: 4px;"><i class="fa fa-network"></i></span>
                                    <div class="info-box-content" style="margin-left: 50px;">
                                        <span class="info-box-text" style="color: #555;">{Lang::T('Sessions')}</span>
                                        <span class="info-box-number" style="font-size: 20px; color: #00cc00;">{$stats['sessions']}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Statistics Cards -->
                <div class="row" style="margin-bottom: 20px;">
                    <div class="col-md-2">
                        <div class="box" style="border-top: 3px solid #00a65a; margin: 0;">
                            <div class="box-body" style="padding: 10px;">
                                <div style="text-align: center;">
                                    <div style="font-size: 12px; color: #999;">{Lang::T('Download')}</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #00a65a; margin-top: 5px;">
                                        {$stats['data_in_formatted']}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="box" style="border-top: 3px solid #f39c12; margin: 0;">
                            <div class="box-body" style="padding: 10px;">
                                <div style="text-align: center;">
                                    <div style="font-size: 12px; color: #999;">{Lang::T('Upload')}</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #f39c12; margin-top: 5px;">
                                        {$stats['data_out_formatted']}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="box" style="border-top: 3px solid #3498db; margin: 0;">
                            <div class="box-body" style="padding: 10px;">
                                <div style="text-align: center;">
                                    <div style="font-size: 12px; color: #999;">{Lang::T('Avg/Day')}</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #3498db; margin-top: 5px;">
                                        {$stats['avg_per_day']}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Charts -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="box">
                            <div class="box-header with-border">
                                <h4 class="box-title">
                                    <i class="fa fa-line-chart"></i> {Lang::T('Daily Usage Trend')} ({$date_from} {Lang::T('to')} {$date_to})
                                </h4>
                            </div>
                            <div class="box-body">
                                <canvas id="dailyChart" height="80"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-6">
                        <div class="box">
                            <div class="box-header with-border">
                                <h4 class="box-title">
                                    <i class="fa fa-pie-chart"></i> {Lang::T('Download vs Upload')}
                                </h4>
                            </div>
                            <div class="box-body">
                                <canvas id="pieChart" width="400" height="300"></canvas>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-6">
                        <div class="box">
                            <div class="box-header with-border">
                                <h4 class="box-title">
                                    <i class="fa fa-bar-chart"></i> {Lang::T('Hourly Usage')} ({date('Y-m-d')})
                                </h4>
                            </div>
                            <div class="box-body">
                                <canvas id="hourlyChart" height="300"></canvas>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Daily Breakdown Table -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="box">
                            <div class="box-header with-border">
                                <h4 class="box-title">
                                    <i class="fa fa-table"></i> {Lang::T('Daily Breakdown')}
                                </h4>
                            </div>
                            <div class="box-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-striped table-hover">
                                        <thead>
                                            <tr>
                                                <th width="15%">{Lang::T('Date')}</th>
                                                <th width="20%">{Lang::T('Download')}</th>
                                                <th width="20%">{Lang::T('Upload')}</th>
                                                <th width="20%">{Lang::T('Total')}</th>
                                                <th width="15%">{Lang::T('Sessions')}</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {if count($daily_usage) == 0}
                                                <tr>
                                                    <td colspan="5" class="text-center text-muted">
                                                        {Lang::T('No usage data available')}
                                                    </td>
                                                </tr>
                                            {else}
                                                {foreach $daily_usage as $day}
                                                    <tr>
                                                        <td><strong>{$day['date']}</strong></td>
                                                        <td>
                                                            <span class="label label-info">{$day['data_in_formatted']}</span>
                                                        </td>
                                                        <td>
                                                            <span class="label label-warning">{$day['data_out_formatted']}</span>
                                                        </td>
                                                        <td>
                                                            <span class="label label-success">{$day['total_formatted']}</span>
                                                        </td>
                                                        <td>{$day['sessions']}</td>
                                                    </tr>
                                                {/foreach}
                                            {/if}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Include Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>

<script>
{literal}
// Daily Trend Chart
if (document.getElementById('dailyChart')) {
    const dailyCtx = document.getElementById('dailyChart').getContext('2d');
    new Chart(dailyCtx, {
        type: 'line',
        data: {
            labels: {/literal}{$chart_labels}{literal},
            datasets: [
                {
                    label: 'Usage (MB)',
                    data: {/literal}{$chart_data}{literal},
                    borderColor: '#3498db',
                    backgroundColor: 'rgba(52, 152, 219, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointBackgroundColor: '#3498db',
                    pointHoverRadius: 6
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    display: true,
                    position: 'top'
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return value + ' MB';
                        }
                    }
                }
            }
        }
    });
}

// Pie Chart (Download vs Upload)
if (document.getElementById('pieChart')) {
    const pieCtx = document.getElementById('pieChart').getContext('2d');
    new Chart(pieCtx, {
        type: 'doughnut',
        data: {
            labels: ['Download', 'Upload'],
            datasets: [{
                data: [{/literal}{$stats['data_in']}{literal}, {/literal}{$stats['data_out']}{literal}],
                backgroundColor: [
                    '#3498db',
                    '#f39c12'
                ],
                borderColor: [
                    '#2980b9',
                    '#d68910'
                ],
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'bottom'
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            let label = context.label || '';
                            if (label) {
                                label += ': ';
                            }
                            const bytes = context.parsed;
                            const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
                            let i = 0;
                            let value = bytes;
                            while (value > 1024 && i < sizes.length - 1) {
                                value /= 1024;
                                i++;
                            }
                            label += value.toFixed(2) + ' ' + sizes[i];
                            return label;
                        }
                    }
                }
            }
        }
    });
}

// Hourly Chart
if (document.getElementById('hourlyChart')) {
    const hourlyCtx = document.getElementById('hourlyChart').getContext('2d');
    new Chart(hourlyCtx, {
        type: 'bar',
        data: {
            labels: {/literal}{$hourly_labels}{literal},
            datasets: [{
                label: 'Usage (MB)',
                data: {/literal}{$hourly_data}{literal},
                backgroundColor: '#27ae60',
                borderColor: '#229954',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            indexAxis: 'x',
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return value + ' MB';
                        }
                    }
                }
            }
        }
    });
}
{/literal}
</script>

{include file="admin/footer.tpl"}
