{include file="sections/header.tpl"}

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <h4>{Lang::T('Recharge Requests History')} 
                    <span class="badge badge-primary" style="margin-left: 10px;">{Lang::arrayCount($requests)}</span>
                </h4>
                <div class="btn-group pull-right">
                    <a href="{Text::url('recharge_requests/list')}" class="btn btn-default btn-xs">
                        <i class="glyphicon glyphicon-list"></i> {Lang::T('Pending Requests')}
                    </a>
                </div>
            </div>
            <div class="panel-body">
                {if Lang::arrayCount($requests) == 0}
                    <div class="alert alert-info">
                        <i class="glyphicon glyphicon-info-sign"></i> {Lang::T('No recharge requests history')}
                    </div>
                {else}
                    <div class="table-responsive">
                        <table class="table table-bordered table-striped table-hover">
                            <thead>
                                <tr>
                                    <th>{Lang::T('Request Date')}</th>
                                    <th>{Lang::T('Customer')}</th>
                                    <th>{Lang::T('Plan')}</th>
                                    <th>{Lang::T('Qty')}</th>
                                    <th>{Lang::T('Status')}</th>
                                    <th>{Lang::T('Processed')}</th>
                                    <th style="width: 100px;">{Lang::T('Action')}</th>
                                </tr>
                            </thead>
                            <tbody>
                                {foreach $requests as $req}
                                    <tr>
                                        <td>
                                            {Lang::dateTimeFormat($req['requested_date'])}
                                        </td>
                                        <td>
                                            <strong>{$req['username']}</strong><br>
                                            <small>{$req['plan_name']}</small>
                                        </td>
                                        <td>
                                            {$req['plan_name']}
                                        </td>
                                        <td>
                                            <span class="badge badge-info">
                                                {if isset($req['quantity']) && $req['quantity'] > 0}{$req['quantity']}{else}1{/if}
                                            </span>
                                        </td>
                                        <td>
                                            {if $req['status'] == 'completed'}
                                                <span class="label label-success">{Lang::T('Completed')}</span>
                                            {elseif $req['status'] == 'rejected'}
                                                <span class="label label-danger">{Lang::T('Rejected')}</span>
                                            {else}
                                                <span class="label label-warning">{$req['status']}</span>
                                            {/if}
                                        </td>
                                        <td>
                                            {if !empty($req['processed_date'])}
                                                {Lang::dateTimeFormat($req['processed_date'])}
                                            {else}
                                                -
                                            {/if}
                                        </td>
                                        <td>
                                            <a href="{Text::url('recharge_requests/view/', $req['id'])}" class="btn btn-info btn-xs">
                                                <i class="glyphicon glyphicon-eye-open"></i> {Lang::T('View')}
                                            </a>
                                        </td>
                                    </tr>
                                {/foreach}
                            </tbody>
                        </table>
                    </div>
                {/if}
            </div>
        </div>
    </div>
</div>

{include file="sections/footer.tpl"}
