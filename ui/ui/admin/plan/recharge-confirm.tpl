{include file="sections/header.tpl"}

<div class="row">
    <div class="col-md-6 col-md-offset-3">
        <div class="panel panel-primary panel-hovered panel-stacked mb30">
            <div class="panel-heading">{Lang::T('Confirm')}</div>
            <div class="panel-body">
                <form class="form-horizontal" method="post" role="form" action="{Text::url('')}plan/recharge-post">
                    <center><b>{Lang::T('Customer')}</b></center>
                    <ul class="list-group list-group-unbordered">
                        <li class="list-group-item">
                            <b>{Lang::T('Username')}</b> <span class="pull-right">{$cust['username']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Name')}</b> <span class="pull-right">{$cust['fullname']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Phone Number')}</b> <span class="pull-right">{$cust['phonenumber']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Email')}</b> <span class="pull-right">{$cust['email']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Address')}</b> <span class="pull-right">{$cust['address']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Balance')}</b> <span
                                class="pull-right">{Lang::moneyFormat($cust['balance'])}</span>
                        </li>
                    </ul>
                    <center><b>{Lang::T('Plan')}</b></center>
                    <ul class="list-group list-group-unbordered">
                        <li class="list-group-item">
                            <b>{Lang::T('Plan Name')}</b> <span class="pull-right">{$plan['name_plan']}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Location')}</b> <span
                                class="pull-right">{if $plan['is_radius']}Radius{else}{$plan['routers']}{/if}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Type')}</b> <span
                                class="pull-right">{if $plan['prepaid'] eq 'yes'}Prepaid{else}Postpaid{/if}
                                {$plan['type']}</span>
                        </li>
                        <tr>
                            <td>{Lang::T('Bandwidth')}</td>
                            <td api-get-text="{Text::url('')}autoload/bw_name/{$plan['id_bw']}"></td>
                        </tr>
                        <li class="list-group-item">
                            <b>{Lang::T('Plan Price')}</b> <span
                                class="pull-right">{if $using eq 'zero'}{Lang::moneyFormat(0)}{else}{Lang::moneyFormat($plan['price'])}{/if}</span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Plan Validity')}</b> <span class="pull-right">
                                {if $quantity && $quantity > 1}
                                    {$plan['validity'] * $quantity} {$plan['validity_unit']} 
                                    <small class="text-muted">({$plan['validity']} × {$quantity})</small>
                                {else}
                                    {$plan['validity']} {$plan['validity_unit']}
                                {/if}
                            </span>
                        </li>
                        <li class="list-group-item">
                            <b>{Lang::T('Start Date & Time')}</b> <span class="pull-right">
                                {if $start_date && $start_time}
                                    {Lang::dateAndTimeFormat($start_date, $start_time)}
                                {else}
                                    {Lang::T('Immediately')}
                                {/if}
                            </span>
                        </li>
                        {if $quantity && $quantity > 1}
                        <li class="list-group-item">
                            <b>{Lang::T('Quantity')}</b> <span class="pull-right">{$quantity}x</span>
                        </li>
                        {/if}
                        <li class="list-group-item">
                            <b>{Lang::T('Payment via')}</b> <span class="pull-right">
                                <select name="using"
                                    style="background-color: white;outline: 1px;border: 1px solid #b7b7b7;">
                                    {foreach $usings as $us}
                                        <option value="{trim($us)}" {if $using eq trim($us)}selected{/if}>
                                            {trim(ucWords($us))}</option>
                                    {/foreach}
                                    {if $_c['enable_balance'] eq 'yes'}
                                        <option value="balance" {if $using eq 'balance'}selected{/if}>
                                            {Lang::T('Customer Balance')}</option>
                                    {/if}
                                    {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                                        <option value="zero" {if $using eq 'zero'}selected{/if}>{$_c['currency_code']} 0
                                        </option>
                                    {/if}
                                </select>
                            </span>
                        </li>
                    </ul>
                    <center><b>{Lang::T('Total')}</b></center>
                    <ul class="list-group list-group-unbordered">
                        {if $tax}
                            <li class="list-group-item">
                                <b>{Lang::T('Tax')}</b> <span class="pull-right">{Lang::moneyFormat($tax)}</span>
                            </li>
                            {if $using neq 'zero' and $add_cost != 0}
                                {foreach $abills as $k => $v}

                                    {if strpos($v, ':') === false}
                                        <li class="list-group-item">
                                            <b>{$k}</b> <span class="pull-right">
                                                {Lang::moneyFormat($v)}
                                                <sup title="recurring">∞</sup>
                                                {assign var="total" value=$v+$total}
                                            </span>
                                        </li>
                                    {else}
                                        {assign var="exp" value=explode(':',$v)}
                                        {if $exp[1]>0}
                                            <li class="list-group-item">
                                                <b>{$k}</b> <span class="pull-right">
                                                    <sup title="{$exp[1]} more times">({$exp[1]}x) </sup>
                                                    {Lang::moneyFormat($exp[0])}
                                                </span>
                                            </li>
                                        {/if}
                                    {/if}
                                {/foreach}
                                <li class="list-group-item">
                                    <b>{Lang::T('Additional Cost')}</b> <span
                                        class="pull-right"><b>{Lang::moneyFormat($add_cost)}</b></span>
                                </li>
                                <li class="list-group-item">
                                    <b>{$plan['name_plan']}</b> <span
                                        class="pull-right">{if $using eq 'zero'}{Lang::moneyFormat(0)}{else}{Lang::moneyFormat($plan['price'])}{/if}</span>
                                </li>
                                <li class="list-group-item">
                                    <b>{Lang::T('Total')}</b> <small>({Lang::T('Plan Price')}
                                        +{Lang::T('Additional Cost')}){if $quantity && $quantity > 1} × {$quantity}{/if}</small><span class="pull-right"
                                        style="font-size: large; font-weight:bolder; font-family: 'Courier New', Courier, monospace; ">{Lang::moneyFormat(($plan['price']+$add_cost+$tax) * (($quantity)?$quantity:1))}</span>
                                </li>
                            {else}
                                <li class="list-group-item">
                                    <b>{Lang::T('Total')}</b> <small>({Lang::T('Plan Price')} + {Lang::T('Tax')}){if $quantity && $quantity > 1} × {$quantity}{/if}</small><span
                                        class="pull-right"
                                        style="font-size: large; font-weight:bolder; font-family: 'Courier New', Courier, monospace; ">{if $using eq 'zero'}{Lang::moneyFormat(0)}{else}{Lang::moneyFormat(($plan['price']+$tax) * (($quantity)?$quantity:1))}{/if}</span>
                                </li>
                            {/if}
                        {else}
                            {if $using neq 'zero' and $add_cost != 0}
                                {foreach $abills as $k => $v}

                                    {if strpos($v, ':') === false}
                                        <li class="list-group-item">
                                            <b>{$k}</b> <span class="pull-right">
                                                {Lang::moneyFormat($v)}
                                                <sup title="recurring">∞</sup>
                                                {assign var="total" value=$v+$total}
                                            </span>
                                        </li>
                                    {else}
                                        {assign var="exp" value=explode(':',$v)}
                                        {if $exp[1]>0}
                                            <li class="list-group-item">
                                                <b>{$k}</b> <span class="pull-right">
                                                    <sup title="{$exp[1]} more times">({$exp[1]}x) </sup>
                                                    {Lang::moneyFormat($exp[0])}
                                                </span>
                                            </li>
                                        {/if}
                                    {/if}
                                {/foreach}
                                <li class="list-group-item">
                                    <b>{Lang::T('Additional Cost')}</b> <span
                                        class="pull-right"><b>{Lang::moneyFormat($add_cost)}</b></span>
                                </li>
                                <li class="list-group-item">
                                    <b>{$plan['name_plan']}</b> <span
                                        class="pull-right">{if $using eq 'zero'}{Lang::moneyFormat(0)}{else}{Lang::moneyFormat($plan['price'])}{/if}</span>
                                </li>
                                <li class="list-group-item">
                                    <b>{Lang::T('Total')}</b> <small>({Lang::T('Plan Price')}
                                        +{Lang::T('Additional Cost')}){if $quantity && $quantity > 1} × {$quantity}{/if}</small><span class="pull-right"
                                        style="font-size: large; font-weight:bolder; font-family: 'Courier New', Courier, monospace; ">{Lang::moneyFormat(($plan['price']+$add_cost) * (($quantity)?$quantity:1))}</span>
                                </li>
                            {else}
                                <li class="list-group-item">
                                    <b>{Lang::T('Total')}</b> {if $quantity && $quantity > 1}<small>× {$quantity}</small>{/if}<span class="pull-right"
                                        style="font-size: large; font-weight:bolder; font-family: 'Courier New', Courier, monospace; ">{if $using eq 'zero'}{Lang::moneyFormat(0)}{else}{Lang::moneyFormat($plan['price'] * (($quantity)?$quantity:1))}{/if}</span>
                                </li>
                            {/if}
                        {/if}
                    </ul>
                    <input type="hidden" name="id_customer" value="{$cust['id']}">
                    <input type="hidden" name="plan" value="{$plan['id']}">
                    <input type="hidden" name="server" value="{$server}">
                    <input type="hidden" name="quantity" value="{if $quantity}{$quantity}{else}1{/if}">
                    <input type="hidden" name="start_date" value="{if $start_date}{$start_date}{/if}">
                    <input type="hidden" name="start_time" value="{if $start_time}{$start_time}{/if}">
                    <input type="hidden" name="stoken" value="{App::getToken()}">
                    <center>
                        <button class="btn btn-success" type="submit">{Lang::T('Recharge')}</button><br>
                        <a class="btn btn-link" href="{Text::url('')}plan/recharge">{Lang::T('Cancel')}</a>
                    </center>
                </form>
            </div>
        </div>
    </div>
</div>

{include file="sections/footer.tpl"}
