{include file="sections/header.tpl"}

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <h4>{Lang::T('Recharge Requests')} 
                    <span class="badge badge-primary" style="margin-left: 10px;">{Lang::arrayCount($requests)}</span>
                </h4>
                <div class="btn-group pull-right">
                    <a href="{Text::url('recharge_requests/history')}" class="btn btn-default btn-xs">
                        <i class="glyphicon glyphicon-th-list"></i> {Lang::T('History')}
                    </a>
                </div>
            </div>
            <div class="panel-body">
                {if Lang::arrayCount($requests) == 0}
                    <div class="alert alert-info">
                        <i class="glyphicon glyphicon-info-sign"></i> {Lang::T('No pending recharge requests')}
                    </div>
                {else}
                    <div class="table-responsive">
                        <table class="table table-bordered table-striped table-hover">
                            <thead>
                                <tr>
                                    <th>{Lang::T('Date')}</th>
                                    <th>{Lang::T('Customer')}</th>
                                    <th>{Lang::T('Plan')}</th>
                                    <th>{Lang::T('Qty')}</th>
                                    <th>{Lang::T('Status')}</th>
                                    <th style="width: 180px;">{Lang::T('Action')}</th>
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
                                            {if $req['status'] == 'pending'}
                                                <span class="label label-warning">{Lang::T('Pending')}</span>
                                            {elseif $req['status'] == 'approved'}
                                                <span class="label label-info">{Lang::T('Approved')}</span>
                                            {elseif $req['status'] == 'completed'}
                                                <span class="label label-success">{Lang::T('Completed')}</span>
                                            {else}
                                                <span class="label label-danger">{Lang::T('Rejected')}</span>
                                            {/if}
                                        </td>
                                        <td>
                                            <a href="{Text::url('recharge_requests/view/', $req['id'])}" class="btn btn-info btn-xs">
                                                <i class="glyphicon glyphicon-eye-open"></i> {Lang::T('View')}
                                            </a>
                                            {if $req['status'] == 'pending'}
                                                <a href="{Text::url('recharge_requests/approve/', $req['id'])}" class="btn btn-success btn-xs" 
                                                   onclick="return confirm('Approve this recharge request?')">
                                                    <i class="glyphicon glyphicon-ok"></i> {Lang::T('Approve')}
                                                </a>
                                                <a href="javascript:void(0)" onclick="rejectRequest({$req['id']})" class="btn btn-danger btn-xs">
                                                    <i class="glyphicon glyphicon-remove"></i> {Lang::T('Reject')}
                                                </a>
                                            {/if}
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

<!-- Reject Modal -->
<div class="modal fade" id="rejectModal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
                <h4 class="modal-title">{Lang::T('Reject Recharge Request')}</h4>
            </div>
            <form method="post" action="">
                <div class="modal-body">
                    <div class="form-group">
                        <label>{Lang::T('Reason for rejection')}</label>
                        <textarea class="form-control" name="reason" rows="4" required placeholder="Enter reason..."></textarea>
                    </div>
                    <input type="hidden" id="reject_id" name="reject_id">
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">{Lang::T('Cancel')}</button>
                    <button type="submit" class="btn btn-danger">{Lang::T('Reject Request')}</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
function rejectRequest(id) {
    $('#reject_id').val(id);
    $('#rejectModal').modal('show');
}

// Wait for jQuery to be available
if (typeof jQuery !== 'undefined') {
    jQuery('#rejectModal form').on('submit', function(e) {
        e.preventDefault();
        const id = jQuery('#reject_id').val();
        const reason = jQuery('[name="reason"]').val();
        window.location.href = '{Text::url('recharge_requests/reject/')}' + id + '&reason=' + encodeURIComponent(reason);
    });
} else {
    // Fallback without jQuery
    document.addEventListener('DOMContentLoaded', function() {
        const form = document.querySelector('#rejectModal form');
        if (form) {
            form.addEventListener('submit', function(e) {
                e.preventDefault();
                const id = document.getElementById('reject_id').value;
                const reason = document.querySelector('[name="reason"]').value;
                window.location.href = '{Text::url('recharge_requests/reject/')}' + id + '&reason=' + encodeURIComponent(reason);
            });
        }
    });
}
</script>

{include file="sections/footer.tpl"}
