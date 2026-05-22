{include file="sections/header.tpl"}

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-primary">
            <div class="panel-heading">
                <h3 class="panel-title">Edit Plan</h3>
            </div>
            <div class="panel-body">
                <form class="form-horizontal" method="post" role="form" action="{Text::url('')}plan/edit-post">
                    <input type="hidden" name="id" value="{$d['id']}">
                    <div class="form-group">
                        <label class="col-md-2 control-label">{Lang::T('Select Account')}</label>
                        <div class="col-md-6">
                            <input type="text" class="form-control" id="username" name="username"
                                value="{$d['username']}" readonly>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="col-md-2 control-label">{Lang::T('Service Plan')}</label>
                        <div class="col-md-6">

                            <select id="id_plan" name="id_plan" class="form-control select2">
                                {foreach $p as $ps}
                                    <option value="{$ps['id']}" {if $d['plan_id'] eq $ps['id']} selected {/if}>
                                        {if $ps['enabled'] neq 1}DISABLED PLAN &bull; {/if}
                                        {$ps['name_plan']} &bull;
                                        {Lang::moneyFormat($ps['price'])}
                                        {if $ps['prepaid'] neq 'yes'} &bull; POSTPAID {/if}
                                    </option>
                                {/foreach}
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-2 control-label">{Lang::T('Created On')}</label>
                        <div class="col-md-4">
                            <input type="date" class="form-control" readonly
                                value="{if $d['transaction_created_at']}{date('Y-m-d', strtotime($d['transaction_created_at']))}{else}{$d['recharged_on']}{/if}">
                        </div>
                        <div class="col-md-2">
                            <input type="text" class="form-control" placeholder="00:00:00" readonly
                                value="{if $d['transaction_created_at']}{date('H:i', strtotime($d['transaction_created_at']))}{else}{$d['recharged_time']}{/if}">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-2 control-label">{Lang::T('Starts On')}</label>
                        <div class="col-md-4">
                            <input type="date" class="form-control" id="recharged_on" name="recharged_on"
                                value="{$d['recharged_on']}">
                        </div>
                        <div class="col-md-2">
                            <input type="text" class="form-control" id="recharged_time" name="recharged_time" placeholder="00:00:00"
                                value="{$d['recharged_time']}">
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-2 control-label">{Lang::T('Expires On')}</label>
                        <div class="col-md-4">
                            <input type="date" class="form-control" id="expiration" name="expiration"
                                value="{$d['expiration']}">
                        </div>
                        <div class="col-md-2">
                            <input type="text" class="form-control" id="time" name="time" placeholder="00:00:00"
                                value="{$d['time']}">
                        </div>
                    </div>

                    <div class="form-group">
                        <div class="col-lg-offset-2 col-lg-10">
                            <button class="btn btn-success" onclick="return ask(this, '{Lang::T('Continue the package change process')}?')" type="submit">{Lang::T('Edit')}</button>
                            Or <a href="{Text::url('')}plan/list">{Lang::T('Cancel')}</a>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
$(function() {
    var planData = {$plan_data_json};
    var periodDayExp = {$period_day_exp};
    var planMap = {};
    $.each(planData, function(i, p) { planMap[p.id] = p; });

    $('#id_plan').on('change', function() {
        var plan = planMap[$(this).val()];
        if (!plan) return;

        var exp = new Date();
        switch (plan.validity_unit) {
            case 'Days':
                exp.setDate(exp.getDate() + plan.validity);
                break;
            case 'Months':
                exp.setMonth(exp.getMonth() + plan.validity);
                break;
            case 'Period':
                exp.setMonth(exp.getMonth() + plan.validity);
                exp.setDate(periodDayExp);
                exp.setHours(23, 59, 0, 0);
                break;
            case 'Hrs':
                exp.setHours(exp.getHours() + plan.validity);
                break;
            case 'Mins':
                exp.setMinutes(exp.getMinutes() + plan.validity);
                break;
        }

        function pad(n) { return String(n).padStart(2, '0'); }
        $('#expiration').val(
            exp.getFullYear() + '-' + pad(exp.getMonth() + 1) + '-' + pad(exp.getDate())
        );
        if (plan.validity_unit === 'Hrs' || plan.validity_unit === 'Mins' || plan.validity_unit === 'Period') {
            $('#time').val(pad(exp.getHours()) + ':' + pad(exp.getMinutes()) + ':' + pad(exp.getSeconds()));
        }
    });
});
</script>

{include file="sections/footer.tpl"}
