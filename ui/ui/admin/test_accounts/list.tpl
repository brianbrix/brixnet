{include file="sections/header.tpl"}

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <div class="btn-group pull-right">
                    <a href="{Text::url('test_accounts/statistics')}" class="btn btn-info btn-xs">
                        <i class="glyphicon glyphicon-stats"></i> {Lang::T('View Statistics')}
                    </a>
                </div>
                <h4>{Lang::T('Test Accounts Management')}
                    {if $excluded_count > 0}
                        <span class="badge badge-warning" style="margin-left: 10px;">{$excluded_count} {Lang::T('Excluded')}</span>
                    {/if}
                </h4>
            </div>
            <div class="panel-body">
                <div class="alert alert-info">
                    <i class="glyphicon glyphicon-info-sign"></i> 
                    <strong>{Lang::T('What is this?')}</strong><br>
                    {Lang::T('Use this page to exclude test accounts, demo users, or internal accounts from dashboard statistics and revenue calculations. Excluded users will still function normally but won\'t affect your metrics.')}
                </div>
                
                <form method="post" action="" class="form-inline" style="margin-bottom: 15px;">
                    <div class="form-group">
                        <input type="text" name="search" class="form-control" placeholder="{Lang::T('Search customers')}..." value="{$search}">
                    </div>
                    <button type="submit" class="btn btn-primary">
                        <i class="glyphicon glyphicon-search"></i> {Lang::T('Search')}
                    </button>
                    {if !empty($search)}
                        <a href="{Text::url('test_accounts/list')}" class="btn btn-default">
                            <i class="glyphicon glyphicon-remove"></i> {Lang::T('Clear')}
                        </a>
                    {/if}
                </form>
                
                {if Lang::arrayCount($customers) == 0}
                    <div class="alert alert-warning">
                        <i class="glyphicon glyphicon-warning-sign"></i> {Lang::T('No customers found')}
                    </div>
                {else}
                    <form method="post" action="{Text::url('test_accounts/toggle_multiple')}" id="bulkForm">
                        <input type="hidden" name="csrf_token" value="{$csrf_token}">
                        <div class="form-group" style="margin-bottom: 10px;">
                            <button type="button" class="btn btn-warning btn-sm" onclick="bulkAction('exclude')">
                                <i class="glyphicon glyphicon-ban-circle"></i> {Lang::T('Exclude Selected')}
                            </button>
                            <button type="button" class="btn btn-success btn-sm" onclick="bulkAction('include')">
                                <i class="glyphicon glyphicon-ok-circle"></i> {Lang::T('Include Selected')}
                            </button>
                            <input type="hidden" name="action_type" id="action_type">
                        </div>
                        
                        <div class="table-responsive">
                            <table class="table table-bordered table-striped table-hover">
                                <thead>
                                    <tr>
                                        <th width="30">
                                            <input type="checkbox" id="selectAll">
                                        </th>
                                        <th>{Lang::T('Status')}</th>
                                        <th>{Lang::T('Username')}</th>
                                        <th>{Lang::T('Full Name')}</th>
                                        <th>{Lang::T('Email')}</th>
                                        <th>{Lang::T('Balance')}</th>
                                        <th>{Lang::T('Action')}</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {foreach $customers as $c}
                                        <tr class="{if $c['exclude_from_stats'] == 1}warning{/if}">
                                            <td>
                                                <input type="checkbox" name="customer_ids[]" value="{$c['id']}" class="customer-checkbox">
                                            </td>
                                            <td>
                                                {if $c['exclude_from_stats'] == 1}
                                                    <span class="label label-warning">
                                                        <i class="glyphicon glyphicon-ban-circle"></i> {Lang::T('Excluded')}
                                                    </span>
                                                {else}
                                                    <span class="label label-success">
                                                        <i class="glyphicon glyphicon-ok"></i> {Lang::T('Included')}
                                                    </span>
                                                {/if}
                                            </td>
                                            <td>
                                                <a href="{Text::url('customers/view/',$c['id'])}">{$c['username']}</a>
                                            </td>
                                            <td>{$c['fullname']}</td>
                                            <td>{$c['email']}</td>
                                            <td>{Lang::moneyFormat($c['balance'])}</td>
                                            <td>
                                                {if $c['exclude_from_stats'] == 1}
                                                    <a href="{Text::url('test_accounts/toggle/',$c['id'])}" 
                                                       class="btn btn-success btn-xs"
                                                       onclick="return confirm('{Lang::T('Include this customer in statistics?')}')">
                                                        <i class="glyphicon glyphicon-ok"></i> {Lang::T('Include')}
                                                    </a>
                                                {else}
                                                    <a href="{Text::url('test_accounts/toggle/',$c['id'])}" 
                                                       class="btn btn-warning btn-xs"
                                                       onclick="return confirm('{Lang::T('Exclude this customer from statistics?')}')">
                                                        <i class="glyphicon glyphicon-ban-circle"></i> {Lang::T('Exclude')}
                                                    </a>
                                                {/if}
                                                <a href="{Text::url('customers/view/',$c['id'])}" class="btn btn-info btn-xs">
                                                    <i class="glyphicon glyphicon-eye-open"></i> {Lang::T('View')}
                                                </a>
                                            </td>
                                        </tr>
                                    {/foreach}
                                </tbody>
                            </table>
                        </div>
                    </form>
                    
                    {include file="pagination.tpl"}
                {/if}
            </div>
        </div>
    </div>
</div>

<script>
// Select all checkbox functionality
document.getElementById('selectAll').addEventListener('change', function() {
    var checkboxes = document.querySelectorAll('.customer-checkbox');
    checkboxes.forEach(function(checkbox) {
        checkbox.checked = document.getElementById('selectAll').checked;
    });
});

// Bulk action handler
function bulkAction(action) {
    var checkedBoxes = document.querySelectorAll('.customer-checkbox:checked');
    if (checkedBoxes.length === 0) {
        alert('{Lang::T('Please select at least one customer')}');
        return false;
    }
    
    var message = action === 'exclude' 
        ? '{Lang::T('Exclude selected customers from statistics?')}'
        : '{Lang::T('Include selected customers in statistics?')}';
    
    if (confirm(message)) {
        document.getElementById('action_type').value = action;
        document.getElementById('bulkForm').submit();
    }
}
</script>

{include file="sections/footer.tpl"}
