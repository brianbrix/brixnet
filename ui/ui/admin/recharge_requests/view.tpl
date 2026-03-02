{include file="sections/header.tpl"}

<div class="row">
    <div class="col-md-8">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <h4>{Lang::T('Recharge Request Details')}</h4>
            </div>
            <div class="panel-body">
                <div class="row">
                    <div class="col-md-6">
                        <h5><strong>{Lang::T('Request Information')}</strong></h5>
                        <table class="table table-striped table-bordered">
                            <tr>
                                <td>{Lang::T('Request ID')}</td>
                                <td>#{$request['id']}</td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Status')}</td>
                                <td>
                                    {if $request['status'] == 'pending'}
                                        <span class="label label-warning">{Lang::T('Pending')}</span>
                                    {elseif $request['status'] == 'completed'}
                                        <span class="label label-success">{Lang::T('Completed')}</span>
                                    {else}
                                        <span class="label label-danger">{Lang::T('Rejected')}</span>
                                    {/if}
                                </td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Requested Date')}</td>
                                <td>{Lang::dateTimeFormat($request['requested_date'])}</td>
                            </tr>
                            {if !empty($request['processed_date'])}
                                <tr>
                                    <td>{Lang::T('Processed Date')}</td>
                                    <td>{Lang::dateTimeFormat($request['processed_date'])}</td>
                                </tr>
                            {/if}
                        </table>
                    </div>
                    
                    <div class="col-md-6">
                        <h5><strong>{Lang::T('Customer Information')}</strong></h5>
                        <table class="table table-striped table-bordered">
                            <tr>
                                <td>{Lang::T('Username')}</td>
                                <td>
                                    <a href="{Text::url('customers/view/', $customer['id'])}">
                                        {$customer['username']}
                                    </a>
                                </td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Full Name')}</td>
                                <td>{$customer['fullname']}</td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Phone')}</td>
                                <td>{$customer['phone']}</td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Email')}</td>
                                <td>{$customer['email']}</td>
                            </tr>
                        </table>
                    </div>
                </div>
                
                <hr>
                
                <div class="row">
                    <div class="col-md-12">
                        <h5><strong>{Lang::T('Plan Information')}</strong></h5>
                        <table class="table table-striped table-bordered">
                            <tr>
                                <td>{Lang::T('Plan Name')}</td>
                                <td>{$plan['name_plan']}</td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Plan Type')}</td>
                                <td>{$plan['type']}</td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Quantity')}</td>
                                <td><strong>{if isset($request['quantity']) && $request['quantity'] > 0}{$request['quantity']}{else}1{/if}</strong></td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Price')}</td>
                                <td><strong>{Lang::moneyFormat($plan['price'])}</strong></td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Total Price')}</td>
                                <td><strong>{Lang::moneyFormat($plan['price'] * (isset($request['quantity']) && $request['quantity'] > 0 ? $request['quantity'] : 1))}</strong></td>
                            </tr>
                            <tr>
                                <td>{Lang::T('Validity')}</td>
                                <td>
                                    {if isset($request['quantity']) && $request['quantity'] > 1}
                                        <strong>{$plan['validity'] * $request['quantity']} {$plan['validity_unit']}</strong> 
                                        <small class="text-muted">({$plan['validity']} × {$request['quantity']})</small>
                                    {else}
                                        {$plan['validity']} {$plan['validity_unit']}
                                    {/if}
                                </td>
                            </tr>
                        </table>
                    </div>
                </div>
                
                <hr>
                
                {if !empty($request['message'])}
                    <div class="row">
                        <div class="col-md-12">
                            <h5><strong>{Lang::T('Customer Message')}</strong></h5>
                            <div class="panel panel-default">
                                <div class="panel-body" style="background-color: #f9f9f9;">
                                    {nl2br($request['message'])}
                                </div>
                            </div>
                        </div>
                    </div>
                {/if}
                
                {if !empty($request['admin_response'])}
                    <div class="row">
                        <div class="col-md-12">
                            <h5><strong>{Lang::T('Admin Response')}</strong></h5>
                            <div class="panel panel-{if $request['status'] == 'completed'}success{else}danger{/if}">
                                <div class="panel-body">
                                    {nl2br($request['admin_response'])}
                                </div>
                            </div>
                        </div>
                    </div>
                {/if}
            </div>
        </div>
    </div>
    
    <div class="col-md-4">
        <div class="panel panel-hovered mb20 panel-info">
            <div class="panel-heading">
                <h4>{Lang::T('Actions')}</h4>
            </div>
            <div class="panel-body">
                {if $request['status'] == 'pending'}
                    <a href="{Text::url('recharge_requests/approve/', $request['id'])}" class="btn btn-success btn-block" 
                       onclick="return confirm('Approve this recharge request?')">
                        <i class="glyphicon glyphicon-ok"></i> {Lang::T('Approve & Recharge')}
                    </a>
                    <a href="javascript:void(0)" onclick="showRejectForm()" class="btn btn-danger btn-block">
                        <i class="glyphicon glyphicon-remove"></i> {Lang::T('Reject')}
                    </a>
                {/if}
                <a href="{Text::url('recharge_requests/list')}" class="btn btn-default btn-block">
                    <i class="glyphicon glyphicon-arrow-left"></i> {Lang::T('Back to List')}
                </a>
                <a href="{Text::url('customers/view/', $customer['id'])}" class="btn btn-info btn-block">
                    <i class="glyphicon glyphicon-user"></i> {Lang::T('View Customer')}
                </a>
            </div>
        </div>
    </div>
</div>

<!-- Reject Form Modal -->
<div class="modal fade" id="rejectFormModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <form method="post" action="{Text::url('recharge_requests/reject/', $request['id'])}">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                    <h4 class="modal-title">{Lang::T('Reject Request')}</h4>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label>{Lang::T('Reason for rejection')}</label>
                        <textarea class="form-control" name="reason" rows="4" required placeholder="Enter reason..."></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">{Lang::T('Cancel')}</button>
                    <button type="submit" class="btn btn-danger">{Lang::T('Reject')}</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function showRejectForm() {
    if (typeof jQuery !== 'undefined') {
        jQuery('#rejectFormModal').modal('show');
    } else {
        document.getElementById('rejectFormModal').style.display = 'block';
    }
}
</script>

{include file="sections/footer.tpl"}
