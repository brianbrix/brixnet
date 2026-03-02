{if $_plans}
<div class="box box-primary box-solid">
    <div class="box-header with-border">
        <h3 class="box-title"><i class="glyphicon glyphicon-list-alt"></i> {Lang::T('Available Plans')}</h3>
    </div>
    <div class="box-body" style="padding:10px;">
        <style>
            .plan-card {
                border: 1px solid #ddd;
                border-radius: 10px;
                padding: 14px 12px;
                margin-bottom: 12px;
                background: #fff;
                box-shadow: 0 2px 6px rgba(0,0,0,0.07);
                position: relative;
                transition: box-shadow 0.2s;
            }
            .plan-card:hover { box-shadow: 0 4px 14px rgba(0,0,0,0.13); }
            .plan-card .plan-name {
                font-size: 15px;
                font-weight: 700;
                color: #333;
                margin-bottom: 4px;
            }
            .plan-card .plan-price {
                font-size: 22px;
                font-weight: 800;
                color: #1a73e8;
                margin-bottom: 6px;
            }
            .plan-card .plan-price small {
                font-size: 13px;
                font-weight: 400;
                color: #888;
            }
            .plan-price-old {
                text-decoration: line-through;
                color: #bbb;
                font-size: 13px;
                margin-left: 4px;
            }
            .plan-meta {
                font-size: 12px;
                color: #666;
                margin-bottom: 3px;
            }
            .plan-meta i { width: 14px; text-align: center; color: #1a73e8; }
            .plan-badges { margin-bottom: 6px; }
            .plan-badge {
                display: inline-block;
                font-size: 11px;
                padding: 2px 8px;
                border-radius: 20px;
                font-weight: 600;
                margin-right: 3px;
                margin-bottom: 3px;
            }
            .badge-primary { background: #1a73e8; color: #fff; }
            .badge-success { background: #28a745; color: #fff; }
            .badge-warning { background: #ffc107; color: #333; }
            .plan-buy-btn {
                display: block;
                text-align: center;
                margin-top: 10px;
                padding: 8px;
                border-radius: 6px;
                font-weight: 600;
                font-size: 14px;
                text-decoration: none !important;
                cursor: pointer;
            }
            .plan-buy-btn-pg { background: #1a73e8; color: #fff !important; }
            .plan-buy-btn-pg:hover { background: #1558c0; }
            .plan-buy-btn-req { background: #e67e22; color: #fff !important; border: none; width: 100%; }
            .plan-buy-btn-req:hover { background: #c0510a; }
            .plan-buy-btn-reg { background: #28a745; color: #fff !important; }
            .plan-buy-btn-reg:hover { background: #1e7e34; }
            .plans-grid { display: flex; flex-wrap: wrap; margin: -6px; }
            .plans-grid .plan-col { padding: 6px; box-sizing: border-box; width: 50%; }
            @media(max-width: 480px) { .plans-grid .plan-col { width: 100%; } }
        </style>

        <div class="plans-grid">
            {foreach $_plans as $plan}
            <div class="plan-col">
                <div class="plan-card">
                    {if $plan.badges}
                    <div class="plan-badges">
                        {foreach $plan.badges as $badge}
                        <span class="plan-badge {$badge.class}">{$badge.icon} {$badge.label}</span>
                        {/foreach}
                    </div>
                    {/if}

                    <div class="plan-name">{$plan.name_plan}</div>

                    <div class="plan-price">
                        {Lang::moneyFormat($plan.price)}
                        {if $plan.price_old neq ''}<span class="plan-price-old">{Lang::moneyFormat($plan.price_old)}</span>{/if}
                    </div>

                    {if $plan.speed neq ''}
                    <div class="plan-meta">
                        <i class="glyphicon glyphicon-signal"></i> {$plan.speed}
                    </div>
                    {/if}

                    <div class="plan-meta">
                        <i class="glyphicon glyphicon-time"></i> {$plan.validity_label}
                    </div>

                    {if $plan.data_label neq ''}
                    <div class="plan-meta">
                        <i class="glyphicon glyphicon-cloud-download"></i> {$plan.data_label}
                    </div>
                    {/if}

                    <div class="plan-meta">
                        <i class="glyphicon glyphicon-tag"></i> {$plan.type} &bull; {$plan.plan_type}
                    </div>

                    {* Subscribe button - 3 behaviors based on login state and payment gateway *}
                    {if !$_user}
                        {* Not logged in → Register *}
                        <a href="{Text::url('register')}#register-form" class="plan-buy-btn plan-buy-btn-reg" onclick="scrollToForm(event)">
                            <i class="glyphicon glyphicon-user"></i> {Lang::T('Register to Subscribe')}
                        </a>
                    {elseif $_c['payment_gateway'] neq ''}
                        {* Logged in + payment gateway available → Order page *}
                        <a href="{Text::url('order/package')}" class="plan-buy-btn plan-buy-btn-pg">
                            {Lang::T('Subscribe')} &rarr;
                        </a>
                    {else}
                        {* Logged in + no payment gateway → Request from admin *}
                        <button class="plan-buy-btn plan-buy-btn-req"
                            onclick="requestNewPlan('{$plan.id}', '{$plan.name_plan|escape:'html'}', '{Lang::moneyFormat($plan.price)}')">
                            <i class="glyphicon glyphicon-send"></i> {Lang::T('Request from Admin')}
                        </button>
                    {/if}
                </div>
            </div>
            {/foreach}
        </div>
    </div>
</div>

{* Modal for requesting a new plan from admin (shown when no payment gateway configured) *}
{if $_user && $_c['payment_gateway'] eq ''}
<div id="newPlanRequestModal" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><i class="glyphicon glyphicon-send"></i> {Lang::T('Request Plan Subscription')}</h4>
            </div>
            <div class="modal-body">
                <p>{Lang::T('You are requesting to subscribe to')}: <strong id="newPlanName"></strong></p>
                <p class="text-muted small">{Lang::T('Price')}: <strong><span id="newPlanPrice"></span></strong></p>

                <div class="panel-group" id="paymentAccordionNew">
                    <!-- M-Pesa -->
                    <div class="panel panel-success">
                        <div class="panel-heading" style="cursor:pointer" data-toggle="collapse" data-target="#mpesaStepsNew">
                            <strong><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/M-PESA_LOGO-01.svg/120px-M-PESA_LOGO-01.svg.png" height="18" style="vertical-align:middle;margin-right:6px" onerror="this.style.display='none'">
                            {Lang::T('Pay via M-Pesa Pochi La Biashara')}</strong>
                            <span class="glyphicon glyphicon-chevron-down pull-right"></span>
                        </div>
                        <div id="mpesaStepsNew" class="panel-collapse collapse in">
                            <div class="panel-body" style="font-size:13px">
                                <ol style="padding-left:18px;margin-bottom:0">
                                    <li>{Lang::T('Open M-Pesa on your phone')}</li>
                                    <li>{Lang::T('Select')} <strong>&ldquo;Lipa na M-Pesa&rdquo;</strong></li>
                                    <li>{Lang::T('Select')} <strong>&ldquo;Pochi La Biashara&rdquo;</strong></li>
                                    <li>{Lang::T('Enter business number')}: <strong>0745865323</strong></li>
                                    <li>{Lang::T('Enter amount')}: <strong><span class="new-plan-price-step"></span></strong></li>
                                    <li>{Lang::T('Enter your M-Pesa PIN and confirm')}</li>
                                    <li>{Lang::T('You will receive an SMS with a transaction code')}</li>
                                    <li>{Lang::T('Send your username and that transaction code via SMS/WhatsApp to')} <strong>0745865323</strong> <em>(Brian Mokandu)</em></li>
                                </ol>
                            </div>
                        </div>
                    </div>
                    <!-- Airtel Money -->
                    <div class="panel panel-danger">
                        <div class="panel-heading" style="cursor:pointer" data-toggle="collapse" data-target="#airtelStepsNew">
                            <strong><i class="glyphicon glyphicon-phone" style="margin-right:6px"></i>
                            {Lang::T('Pay via Airtel Money')}</strong>
                            <span class="glyphicon glyphicon-chevron-down pull-right"></span>
                        </div>
                        <div id="airtelStepsNew" class="panel-collapse collapse">
                            <div class="panel-body" style="font-size:13px">
                                <ol style="padding-left:18px;margin-bottom:0">
                                    <li>{Lang::T('Dial')} <strong>*185#</strong> {Lang::T('or open the Airtel Money app')}</li>
                                    <li>{Lang::T('Select')} <strong>&ldquo;Send Money&rdquo;</strong></li>
                                    <li>{Lang::T('Select')} <strong>&ldquo;To Mobile Number&rdquo;</strong></li>
                                    <li>{Lang::T('Enter number')}: <strong>0734459479</strong></li>
                                    <li>{Lang::T('Enter amount')}: <strong><span class="new-plan-price-step"></span></strong></li>
                                    <li>{Lang::T('Enter your Airtel PIN and confirm')}</li>
                                    <li>{Lang::T('You will receive an SMS with a transaction code')}</li>
                                    <li>{Lang::T('Send your username and that transaction code via SMS/WhatsApp to')} <strong>0745865323</strong> <em>(Brian Mokandu)</em></li>
                                </ol>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-group" style="margin-top:12px">
                    <label>{Lang::T('Quantity')}</label>
                    <input type="number" class="form-control" id="newPlanQuantity" value="1" min="1" max="100" style="text-align: center;">
                    <small class="text-muted">{Lang::T('Multiply plan benefits by quantity')}</small>
                </div>
                <div class="form-group">
                    <label>{Lang::T('Message to Admin')} ({Lang::T('Optional')})</label>
                    <textarea class="form-control" id="newPlanMessage" rows="2"
                        placeholder="{Lang::T('Add any special request or note')}"></textarea>
                </div>
                <div id="newPlanResult" style="display:none;" class="alert"></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">{Lang::T('Cancel')}</button>
                <button type="button" class="btn btn-warning" id="sendNewPlanBtn" onclick="sendNewPlanRequest()">
                    <i class="glyphicon glyphicon-send"></i> {Lang::T('Send Request')}
                </button>
            </div>
        </div>
    </div>
</div>
<script>
var _newPlanId = null;
function requestNewPlan(planId, planName, planPrice) {
    _newPlanId = planId;
    document.getElementById('newPlanName').textContent = planName;
    document.getElementById('newPlanPrice').textContent = planPrice;
    document.querySelectorAll('.new-plan-price-step').forEach(function(el){ el.textContent = planPrice; });
    document.getElementById('newPlanMessage').value = '';
    document.getElementById('newPlanQuantity').value = 1;
    document.getElementById('newPlanResult').style.display = 'none';
    document.getElementById('sendNewPlanBtn').disabled = false;
    jQuery('#newPlanRequestModal').modal('show');
}
function sendNewPlanRequest() {
    var message = document.getElementById('newPlanMessage').value;
    var quantity = parseInt(document.getElementById('newPlanQuantity').value) || 1;
    var btn = document.getElementById('sendNewPlanBtn');
    btn.disabled = true;
    jQuery.ajax({
        type: 'POST',
        url: '{Text::url('autoload_user/request_new_plan')}',
        data: { plan_id: _newPlanId, message: message, quantity: quantity },
        dataType: 'json',
        success: function(resp) {
            var el = document.getElementById('newPlanResult');
            el.style.display = 'block';
            if (resp.status === 'success') {
                el.className = 'alert alert-success';
                el.textContent = resp.message;
                setTimeout(function(){ jQuery('#newPlanRequestModal').modal('hide'); }, 2500);
            } else {
                el.className = 'alert alert-danger';
                el.textContent = resp.message;
                btn.disabled = false;
            }
        },
        error: function() {
            document.getElementById('newPlanResult').className = 'alert alert-danger';
            document.getElementById('newPlanResult').textContent = 'Request failed. Please try again.';
            document.getElementById('newPlanResult').style.display = 'block';
            btn.disabled = false;
        }
    });
}
</script>
{/if}
{/if}
