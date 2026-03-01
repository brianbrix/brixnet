{include file="admin/header.tpl"}

<div class="row">
    <div class="col-md-12">
        <div class="alert alert-warning">
            <h4>Debug Information</h4>
            <table class="table table-condensed">
                <tr>
                    <td><strong>Table:</strong></td>
                    <td><code>{$table_info.table}</code></td>
                </tr>
                <tr>
                    <td><strong>Connection:</strong></td>
                    <td><code>{$table_info.connection|default:'default'}</code></td>
                </tr>
                <tr>
                    <td><strong>Input Column:</strong></td>
                    <td><code>{$table_info.input_column}</code></td>
                </tr>
                <tr>
                    <td><strong>Output Column:</strong></td>
                    <td><code>{$table_info.output_column}</code></td>
                </tr>
                <tr>
                    <td><strong>Date Column:</strong></td>
                    <td><code>{$table_info.date_column}</code></td>
                </tr>
                <tr style="background-color: #ffffcc;">
                    <td><strong>Total Records in Table:</strong></td>
                    <td><strong>{$table_count}</strong></td>
                </tr>
                <tr>
                    <td><strong>Date Range:</strong></td>
                    <td>{$date_from} to {$date_to}</td>
                </tr>
                {if $test_customer}
                <tr style="background-color: #ffffcc;">
                    <td><strong>Test Customer:</strong></td>
                    <td>{$test_customer.username} - {$test_customer.fullname}</td>
                </tr>
                {/if}
                {if $test_usage}
                <tr style="background-color: #ffffcc;">
                    <td><strong>Test Usage (Sample):</strong></td>
                    <td>In: {$test_usage.data_in|default:'0'} bytes | Out: {$test_usage.data_out|default:'0'} bytes | Total: {Usage::formatBytes($test_usage.data_total)}</td>
                </tr>
                {/if}
            </table>
            {if $sample_record}
                <hr style="margin: 10px 0;">
                <strong>Sample Record Columns:</strong><br>
                <pre style="background: #f5f5f5; padding: 10px; overflow-x: auto;">{foreach from=$sample_record key=col item=val}{$col}: {$val|default:'-'}{"\n"}{/foreach}</pre>
            {else}
                <hr style="margin: 10px 0;">
                <strong style="color: red;">No data found in accounting table!</strong>
            {/if}
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-12">
        <div class="box box-primary">
            <div class="box-header with-border">
                <h3 class="box-title">
                    <i class="fa fa-bar-chart"></i> {Lang::T('Customer Usage Analytics')}
                </h3>
            </div>
            
            <div class="box-body">
                <!-- Date Range Filter -->
                <form method="get" class="form-inline" style="margin-bottom: 20px;">
                    <div class="form-group" style="margin-right: 10px;">
                        <label for="date_from">{Lang::T('From')}</label>
                        <input type="date" name="date_from" id="date_from" class="form-control" value="{$date_from}" style="margin-left: 5px;">
                    </div>
                    <div class="form-group" style="margin-right: 10px;">
                        <label for="date_to">{Lang::T('To')}</label>
                        <input type="date" name="date_to" id="date_to" class="form-control" value="{$date_to}" style="margin-left: 5px;">
                    </div>
                    <div class="form-group" style="margin-right: 10px;">
                        <input type="text" name="search" class="form-control" placeholder="{Lang::T('Search username or name')}" value="{$search}">
                    </div>
                    <button type="submit" class="btn btn-primary">
                        <i class="fa fa-search"></i> {Lang::T('Filter')}
                    </button>
                    <a href="{Text::url('usage')}" class="btn btn-default" style="margin-left: 5px;">
                        {Lang::T('Reset')}
                    </a>
                </form>
                
                <!-- Summary Stats -->
                <div class="row" style="margin-bottom: 20px;">
                    <div class="col-md-3">
                        <div class="info-box">
                            <span class="info-box-icon bg-aqua"><i class="fa fa-users"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">{Lang::T('Total Customers')}</span>
                                <span class="info-box-number">{count($customer_usage)}</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="info-box">
                            <span class="info-box-icon bg-green"><i class="fa fa-download"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">{Lang::T('Total Download')}</span>
                                <span class="info-box-number">{Usage::formatBytes(array_sum(array_column($customer_usage, 'data_in')))}</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="info-box">
                            <span class="info-box-icon bg-red"><i class="fa fa-upload"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">{Lang::T('Total Upload')}</span>
                                <span class="info-box-number">{Usage::formatBytes(array_sum(array_column($customer_usage, 'data_out')))}</span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="info-box">
                            <span class="info-box-icon bg-yellow"><i class="fa fa-exchange"></i></span>
                            <div class="info-box-content">
                                <span class="info-box-text">{Lang::T('Total Data')}</span>
                                <span class="info-box-number">{Usage::formatBytes(array_sum(array_column($customer_usage, 'data_total')))}</span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Customers Table -->
                <div class="table-responsive">
                    <table class="table table-bordered table-striped table-hover">
                        <thead>
                            <tr>
                                <th width="20%">{Lang::T('Username')}</th>
                                <th width="25%">{Lang::T('Full Name')}</th>
                                <th width="15%">{Lang::T('Download')}</th>
                                <th width="15%">{Lang::T('Upload')}</th>
                                <th width="15%">{Lang::T('Total')}</th>
                                <th width="10%">{Lang::T('Actions')}</th>
                            </tr>
                        </thead>
                        <tbody>
                            {if count($customer_usage) == 0}
                                <tr>
                                    <td colspan="6" class="text-center text-muted">
                                        <i class="fa fa-info-circle"></i> {Lang::T('No data found')}
                                    </td>
                                </tr>
                            {else}
                                {foreach $customer_usage as $usage}
                                    <tr>
                                        <td>
                                            <strong>{$usage['username']}</strong>
                                        </td>
                                        <td>{$usage['fullname']}</td>
                                        <td>
                                            <span class="label label-info">
                                                <i class="fa fa-download"></i> {$usage['data_in_formatted']}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="label label-warning">
                                                <i class="fa fa-upload"></i> {$usage['data_out_formatted']}
                                            </span>
                                        </td>
                                        <td>
                                            <span class="label label-success" style="font-size: 12px;">
                                                {$usage['data_total_formatted']}
                                            </span>
                                        </td>
                                        <td>
                                            <a href="{Text::url('usage/detail')}/{$usage['id']}?date_from={$date_from}&date_to={$date_to}" 
                                               class="btn btn-xs btn-primary" title="{Lang::T('View Details')}">
                                                <i class="fa fa-eye"></i> {Lang::T('View')}
                                            </a>
                                        </td>
                                    </tr>
                                {/foreach}
                            {/if}
                        </tbody>
                    </table>
                </div>
                
                <!-- Legend -->
                <div class="alert alert-info" style="margin-top: 20px;">
                    <strong><i class="fa fa-info-circle"></i> {Lang::T('Information')}:</strong><br>
                    • {Lang::T('Download')}: {Lang::T('Data received from internet')} (Input Octets)<br>
                    • {Lang::T('Upload')}: {Lang::T('Data sent to internet')} (Output Octets)<br>
                    • {Lang::T('Total')}: {Lang::T('Combined download and upload')} ({Lang::T('Download')} + {Lang::T('Upload')})<br>
                    • {Lang::T('Date Range')}: {$date_from} {Lang::T('to')} {$date_to}
                </div>
            </div>
        </div>
    </div>
</div>

{include file="admin/footer.tpl"}
