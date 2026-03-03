{if $_bills}
    {* === TOP SUMMARY BAR: one line per active plan === *}
    {assign var="_active_count" value=0}
    {foreach $_bills as $_b}{if $_b['status'] == 'on'}{assign var="_active_count" value=$_active_count+1}{/if}{/foreach}

    <div style="margin-bottom:8px;">
        {foreach $_bills as $_b}
            {if $_b['status'] == 'on'}
            <div style="display:flex; align-items:center; background:#e8f5e9; border-left:4px solid #28a745; border-radius:6px; padding:7px 12px; margin-bottom:5px; font-size:13px;">
                <span style="background:#28a745; color:#fff; border-radius:50%; width:20px; height:20px; display:inline-flex; align-items:center; justify-content:center; font-size:10px; margin-right:8px; flex-shrink:0;">✓</span>
                <strong style="flex:1;">{$_b['namebp']}</strong>
                <span style="color:#555; margin-left:8px;">{$_b['type']}</span>
                <span style="color:#e74c3c; margin-left:12px; white-space:nowrap;">
                    {Lang::T('Expires')}: {Lang::dateAndTimeFormat($_b['expiration'],$_b['time'])}
                </span>
            </div>
            {/if}
        {/foreach}
        {if $_active_count == 0}
            <div style="background:#fff3cd; border-left:4px solid #ffc107; border-radius:6px; padding:7px 12px; font-size:13px; color:#856404;">
                <i class="glyphicon glyphicon-warning-sign"></i> {Lang::T('No active plan')}
            </div>
        {/if}
    </div>

    <div class="box box-primary box-solid">
        {if $_active_count > 1}
        <div style="background:#d1ecf1; padding:6px 12px; font-size:12px; color:#0c5460; border-bottom:1px solid #bee5eb;">
            <i class="glyphicon glyphicon-info-sign"></i>
            {$_active_count} {Lang::T('active plans')} — {Lang::T('each plan runs independently on its own router/session')}
        </div>
        {/if}
        {foreach $_bills as $_bill}
            {if $_bill['routers'] != 'radius'}
                <div class="box-header">
                    <h3 class="box-title">{$_bill['routers']}</h3>
                    <div class="btn-group pull-right">
                        {if $_bill['type'] == 'Hotspot'}
                            {if $_c['hotspot_plan']==''}Hotspot Plan{else}{$_c['hotspot_plan']}{/if}
                        {else if $_bill['type'] == 'PPPOE'}
                            {if $_c['pppoe_plan']==''}PPPOE Plan{else}{$_c['pppoe_plan']}{/if}
                        {else if $_bill['type'] == 'VPN'}
                            {if $_c['pppoe_plan']==''}VPN Plan{else}{$_c['vpn_plan']}{/if}
                        {/if}
                    </div>
                </div>
            {else}
                <div class="box-header">
                    <h3 class="box-title">{if $_c['radius_plan']==''}Radius Plan{else}{$_c['radius_plan']}{/if}</h3>
                </div>
            {/if}
            <div style="margin-left: 5px; margin-right: 5px;">
                <table class="table table-bordered table-striped table-bordered table-hover" style="margin-bottom: 0px;">
                    <tr>
                        <td class="small text-primary text-uppercase text-normal">{Lang::T('Package Name')}</td>
                        <td class="small mb15">
                            {$_bill['namebp']}
                            {if $_bill['status'] != 'on'}
                                <a class="label label-danger pull-right"
                                    href="{Text::url('order/package')}">{Lang::T('Expired')}</a>
                            {/if}
                        </td>
                    </tr>
                    {if $_c['show_bandwidth_plan'] == 'yes'}
                        <tr>
                            <td class="small text-primary text-uppercase text-normal">{Lang::T('Bandwidth')}</td>
                            <td class="small mb15">
                                {$_bill['name_bw']}
                            </td>
                        </tr>
                    {/if}
                    <tr>
                        <td class="small text-info text-uppercase text-normal">{Lang::T('Created On')}</td>
                        <td class="small mb15">
                            {if $_bill['time'] ne ''}
                                {Lang::dateAndTimeFormat($_bill['recharged_on'],$_bill['recharged_time'])}
                            {/if}
                            &nbsp;</td>
                    </tr>
                    <tr>
                        <td class="small text-danger text-uppercase text-normal">{Lang::T('Expires On')}</td>
                        <td class="small mb15 text-danger">
                            {if $_bill['time'] ne ''}
                                {Lang::dateAndTimeFormat($_bill['expiration'],$_bill['time'])}
                            {/if}&nbsp;
                        </td>
                    </tr>
                    <tr>
                        <td class="small text-success text-uppercase text-normal">{Lang::T('Type')}</td>
                        <td class="small mb15 text-success">
                            <b>{if $_bill['prepaid'] eq yes}Prepaid{else}Postpaid{/if}</b>
                            {$_bill['plan_type']}
                        </td>
                    </tr>
                    {if $_bill['type'] == 'VPN' && $_bill['routers'] == $vpn['routers']}
                        <tr>
                            <td class="small text-success text-uppercase text-normal">{Lang::T('Public IP')}</td>
                            <td class="small mb15">{$vpn['public_ip']} / {$vpn['port_name']}</td>
                        </tr>
                        <tr>
                            <td class="small text-success text-uppercase text-normal">{Lang::T('Private IP')}</td>
                            <td class="small mb15">{$_user['pppoe_ip']}</td>
                        </tr>
                        {foreach $cf as $tcf}
                            <tr>
                                {if $tcf['field_name'] == 'Winbox' or $tcf['field_name'] == 'Api' or $tcf['field_name'] == 'Web'}
                                    <td class="small text-info text-uppercase text-normal">{$tcf['field_name']} - Port</td>
                                    <td class="small mb15"><a href="http://{$vpn['public_ip']}:{$tcf['field_value']}"
                                            target="_blank">{$tcf['field_value']}</a></td>
                                </tr>
                            {/if}
                        {/foreach}
                    {/if}

                    {if $nux_ip neq ''}
                        <tr>
                            <td class="small text-primary text-uppercase text-normal">{Lang::T('Current IP')}</td>
                            <td class="small mb15">{$nux_ip}</td>
                        </tr>
                    {/if}
                    {if $nux_mac neq ''}
                        <tr>
                            <td class="small text-primary text-uppercase text-normal">{Lang::T('Current MAC')}</td>
                            <td class="small mb15">{$nux_mac}</td>
                        </tr>
                    {/if}
                    {if $_bill['type'] == 'Hotspot' && $_bill['status'] == 'on' && $_bill['routers'] != 'radius' && $_c['hs_auth_method'] != 'hchap'}
                        <tr>
                            <td class="small text-primary text-uppercase text-normal">{Lang::T('Login Status')}</td>
                            <td class="small mb15" id="login_status_{$_bill['id']}">
                                <img src="{$app_url}/ui/ui/images/loading.gif">
                            </td>
                        </tr>
                    {/if}
                    {if $_bill['type'] == 'Hotspot' && $_bill['status'] == 'on' && $_c['hs_auth_method'] == 'hchap'}
                        <tr>
                            <td class="small text-primary text-uppercase text-normal">{Lang::T('Login Status')}</td>
                            <td class="small mb15">
                                {if $logged == '1'}
                                    <a href="http://{$hostname}/status" class="btn btn-success btn-xs btn-block">
                                        {Lang::T('You are Online, Check Status')}</a>
                                {else}
                                    <a href="{Text::url('home&mikrotik=login')}"
                                        onclick="return ask(this, '{Lang::T('Connect to Internet')}')"
                                        class="btn btn-danger btn-xs btn-block">{Lang::T('Not Online, Login now?')}</a>
                                {/if}
                            </td>
                        </tr>
                    {/if}
                    <tr>
                        <td class="small text-primary text-uppercase text-normal">
                            {if $_bill['status'] == 'on' && $_bill['prepaid'] != 'YES'}
                                {* Postpaid: deactivate (permanent disconnect) *}
                                <a href="{Text::url('home&deactivate=', $_bill['id'])}"
                                    onclick="return ask(this, '{Lang::T('Deactivate')}?')" class="btn btn-danger btn-xs"><i
                                        class="glyphicon glyphicon-trash"></i></a>
                            {/if}
                            {if $_bill['status'] == 'on' && $_bill['prepaid'] == 'yes'}
                                {* Prepaid: cancel (stop internet, plan goes inactive) *}
                                <a href="{Text::url('home&deactivate=', $_bill['id'])}"
                                    onclick="return ask(this, '{Lang::T('Cancel this plan? Your internet access will stop immediately.')}?')"
                                    class="btn btn-danger btn-xs">
                                    <i class="glyphicon glyphicon-ban-circle"></i> {Lang::T('Cancel')}
                                </a>
                            {/if}
                            {if $_bill['status'] != 'on'}
                                <a href="{Text::url('home&forget=', $_bill['id'], '&stoken=', App::getToken())}"
                                    onclick="return ask(this, '{Lang::T('Hide this plan')}?')" class="btn btn-secondary btn-xs" style="background-color: #999; color: white;"><i
                                        class="glyphicon glyphicon-eye-close"></i> {Lang::T('Forget')}</a>
                            {/if}
                        </td>
                        <td class="small row">
                            {if $_bill['status'] != 'on' && $_bill['prepaid'] != 'yes' && $_c['extend_expired']}
                                <a class="btn btn-warning text-black btn-sm"
                                    href="{Text::url('home&extend=', $_bill['id'], '&stoken=', App::getToken())}"
                                    onclick="return ask(this, '{Text::toHex($_c['extend_confirmation'])}')">{Lang::T('Extend')}</a>
                            {/if}
                            <a class="btn btn-primary pull-right btn-sm"
                                href="{Text::url('home&recharge=', $_bill['id'], '&stoken=', App::getToken())}"
                                onclick="return ask(this, '{Lang::T('Recharge')}?')">{Lang::T('Recharge')}</a>
                            <a class="btn btn-info pull-right btn-sm" style="margin-right: 5px;" id="requestRechargeBtn_{$_bill['id']}" data-bill-id="{$_bill['id']}" data-plan-name="{$_bill['namebp']|escape:'html'}" data-plan-price="{$_bill['price']}">
                                <i class="glyphicon glyphicon-plus"></i> {Lang::T('Request')}
                            </a>
                            <a class="btn btn-warning text-black pull-right btn-sm"
                                href="{Text::url('home&sync=', $_bill['id'], '&stoken=', App::getToken())}"
                                onclick="return ask(this, '{Lang::T('Sync account if you failed login to internet')}?')"
                                data-toggle="tooltip" data-placement="top"
                                title="{Lang::T('Sync account if you failed login to internet')}"><span
                                    class="glyphicon glyphicon-refresh" aria-hidden="true"></span> {Lang::T('Sync')}</a>
                        </td>
                    </tr>
                </table>
            </div>
            &nbsp;&nbsp;
        {/foreach}
    </div>
    {foreach $_bills as $_bill}
        {if $_bill['type'] == 'Hotspot' && $_bill['status'] == 'on' && $_c['hs_auth_method'] != 'hchap'}
            <script>
                setTimeout(() => {
                    $.ajax({
                        url: "{Text::url('autoload_user/isLogin/')}{$_bill['id']}",
                        cache: false,
                        success: function(msg) {
                            $("#login_status_{$_bill['id']}").html(msg);
                        }
                    });
                }, 2000);
            </script>
        {/if}
    {/foreach}

    <!-- Recharge Request Modal HTML -->
    <div id="rechargeRequestModal" class="modal fade" tabindex="-1" role="dialog">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title">{Lang::T('Request Plan Recharge')}</h4>
                </div>
                <div class="modal-body">
                    <p>{Lang::T('You are requesting a recharge for')}: <strong id="recharge_plan_name"></strong></p>
                    
                    <div class="form-group">
                        <label><strong>{Lang::T('Base Price')}: <span id="recharge_base_price" style="color: #d9534f;"></span></strong></label>
                    </div>

                    <div class="form-group">
                        <label>{Lang::T('Quantity')}</label>
                        <div class="input-group">
                            <input type="number" class="form-control" id="recharge_quantity" value="1" min="1" max="100" style="text-align: center;">
                            <span class="input-group-addon">{Lang::T('times')}</span>
                        </div>
                        <small class="text-muted">{Lang::T('Multiply plan benefits by quantity')}</small>
                    </div>

                    <div class="form-group">
                        <div class="panel panel-info">
                            <div class="panel-body" style="padding: 8px 12px; margin: 0;">
                                <strong>{Lang::T('Total Amount to Pay')}: <span id="recharge_total_price" style="color: #d9534f; font-size: 16px;"></span></strong>
                            </div>
                        </div>
                    </div>

                    <div class="panel-group" id="paymentAccordionRecharge">
                        <!-- M-Pesa -->
                        <div class="panel panel-success">
                            <div class="panel-heading" style="cursor:pointer" data-toggle="collapse" data-target="#mpesaStepsRecharge">
                                <strong><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/M-PESA_LOGO-01.svg/120px-M-PESA_LOGO-01.svg.png" height="18" style="vertical-align:middle;margin-right:6px" onerror="this.style.display='none'">
                                {Lang::T('Pay via M-Pesa Pochi La Biashara')}</strong>
                                <span class="glyphicon glyphicon-chevron-down pull-right"></span>
                            </div>
                            <div id="mpesaStepsRecharge" class="panel-collapse collapse in">
                                <div class="panel-body" style="font-size:13px">
                                    <ol style="padding-left:18px;margin-bottom:0">
                                        <li>{Lang::T('Open M-Pesa on your phone')}</li>
                                        <li>{Lang::T('Select')} <strong>&ldquo;Lipa na M-Pesa&rdquo;</strong></li>
                                        <li>{Lang::T('Select')} <strong>&ldquo;Pochi La Biashara&rdquo;</strong></li>
                                        <li>{Lang::T('Enter business number')}: <strong>0745865323</strong></li>
                                        <li>{Lang::T('Enter amount')}: <strong><span id="recharge_plan_price_mpesa"></span></strong></li>
                                        <li>{Lang::T('Enter your M-Pesa PIN and confirm')}</li>
                                        <li>{Lang::T('You will receive an SMS with a transaction code')}</li>
                                        <li>{Lang::T('Send your username and that transaction code via SMS/WhatsApp to')} <strong>0745865323</strong> <em>(Brian Mokandu)</em></li>
                                    </ol>
                                </div>
                            </div>
                        </div>
                        <!-- Airtel Money -->
                        <div class="panel panel-danger">
                            <div class="panel-heading" style="cursor:pointer" data-toggle="collapse" data-target="#airtelStepsRecharge">
                                <strong><i class="glyphicon glyphicon-phone" style="margin-right:6px"></i>
                                {Lang::T('Pay via Airtel Money')}</strong>
                                <span class="glyphicon glyphicon-chevron-down pull-right"></span>
                            </div>
                            <div id="airtelStepsRecharge" class="panel-collapse collapse">
                                <div class="panel-body" style="font-size:13px">
                                    <ol style="padding-left:18px;margin-bottom:0">
                                        <li>{Lang::T('Dial')} <strong>*185#</strong> {Lang::T('or open the Airtel Money app')}</li>
                                        <li>{Lang::T('Select')} <strong>&ldquo;Send Money&rdquo;</strong></li>
                                        <li>{Lang::T('Select')} <strong>&ldquo;To Mobile Number&rdquo;</strong></li>
                                        <li>{Lang::T('Enter number')}: <strong>0734459479</strong></li>
                                        <li>{Lang::T('Enter amount')}: <strong><span id="recharge_plan_price_airtel"></span></strong></li>
                                        <li>{Lang::T('Enter your Airtel PIN and confirm')}</li>
                                        <li>{Lang::T('You will receive an SMS with a transaction code')}</li>
                                        <li>{Lang::T('Send your username and that transaction code via SMS/WhatsApp to')} <strong>0745865323</strong> <em>(Brian Mokandu)</em></li>
                                    </ol>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="form-group" style="margin-top:12px">
                        <label>{Lang::T('Message')} ({Lang::T('Optional')})</label>
                        <textarea class="form-control" id="recharge_message" rows="2" placeholder="{Lang::T('Add any special request or note')}"></textarea>
                    </div>
                    <div class="form-group">
                        <button type="button" class="btn btn-primary btn-block" id="submitRechargeBtn">{Lang::T('Send Request to Admin')}</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Recharge Request JavaScript -->
    <script>
    console.log('Recharge modal script loaded');
    
    // Store currently selected bill ID
    var currentBillId = null;
    
    // Wait for jQuery to be available
    function initRechargeModal() {
        if (typeof jQuery === 'undefined') {
            console.warn('jQuery not yet loaded, retrying...');
            setTimeout(initRechargeModal, 100);
            return;
        }
        
        console.log('jQuery available, initializing recharge modal');
        
        // Handle Request button clicks
        document.addEventListener('DOMContentLoaded', function() {
        console.log('DOM loaded, setting up recharge request listeners');
        
        // Store base price for calculations
        var rechargeBasePrice = 0;
        
        // Find all request buttons and attach listeners
        var requestBtns = document.querySelectorAll('[id^="requestRechargeBtn_"]');
        console.log('Found ' + requestBtns.length + ' request buttons');
        
        requestBtns.forEach(function(btn) {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                var billId = this.getAttribute('data-bill-id');
                var planName = this.getAttribute('data-plan-name');
                var planPrice = this.getAttribute('data-plan-price');
                console.log('Request button clicked - billId:', billId, 'planName:', planName, 'raw price:', planPrice, 'type:', typeof planPrice);
                
                currentBillId = billId;
                rechargeBasePrice = planPrice ? parseFloat(planPrice.toString().replace(/[^\d.]/g, '')) : 0;
                console.log('Parsed rechargeBasePrice:', rechargeBasePrice);
                
                document.getElementById('recharge_plan_name').textContent = planName;
                document.getElementById('recharge_base_price').textContent = rechargeBasePrice.toFixed(2);
                document.getElementById('recharge_message').value = '';
                document.getElementById('recharge_quantity').value = 1;
                
                // Update prices for initial display
                updateRechargePrices();
                
                // Show modal
                if (typeof jQuery !== 'undefined') {
                    jQuery('#rechargeRequestModal').modal('show');
                    console.log('Modal shown via jQuery');
                } else {
                    console.warn('jQuery not available');
                }
            });
        });
        
        // Handle quantity changes
        function updateRechargePrices() {
            console.log('updateRechargePrices called, rechargeBasePrice:', rechargeBasePrice);
            var quantity = parseInt(document.getElementById('recharge_quantity').value) || 1;
            console.log('Quantity:', quantity);
            if (quantity < 1) quantity = 1;
            if (quantity > 100) quantity = 100;
            
            var totalPrice = (rechargeBasePrice * quantity).toFixed(2);
            console.log('Calculated totalPrice:', totalPrice);
            
            document.getElementById('recharge_plan_price_mpesa').textContent = totalPrice;
            document.getElementById('recharge_plan_price_airtel').textContent = totalPrice;
            document.getElementById('recharge_total_price').textContent = totalPrice;
        }
        
        // Add listener to quantity input
        var quantityInput = document.getElementById('recharge_quantity');
        if (quantityInput) {
            quantityInput.addEventListener('change', updateRechargePrices);
            quantityInput.addEventListener('keyup', updateRechargePrices);
            quantityInput.addEventListener('input', updateRechargePrices);
        }
        
        // Handle submit button
        document.getElementById('submitRechargeBtn').addEventListener('click', function() {
            console.log('Submit button clicked, currentBillId:', currentBillId);
            submitRechargeRequest();
        });
    });
    
    window.submitRechargeRequest = function() {
        console.log('submitRechargeRequest called');
        const billId = currentBillId;
        const message = document.getElementById('recharge_message').value;
        const quantity = parseInt(document.getElementById('recharge_quantity').value) || 1;
        
        console.log('Sending recharge request - billId:', billId, 'message:', message, 'quantity:', quantity);
        
        if (!billId) {
            alert('Bill ID is missing!');
            console.error('No bill ID set');
            return;
        }
        
        document.getElementById('submitRechargeBtn').disabled = true;
        
        if (typeof jQuery !== 'undefined') {
            console.log('Making AJAX POST to: {Text::url('autoload_user/request_recharge')}');
            jQuery.ajax({
                type: 'POST',
                url: '{Text::url('autoload_user/request_recharge')}',
                data: {
                    bill_id: billId,
                    message: message,
                    quantity: quantity
                },
                dataType: 'json',
                success: function(resp) {
                    console.log('AJAX success, response:', resp);
                    if (resp.status === 'success') {
                        alert('Recharge request sent successfully!');
                        jQuery('#rechargeRequestModal').modal('hide');
                        setTimeout(() => location.reload(), 1500);
                    } else {
                        alert('Error: ' + (resp.message || 'Failed to send request'));
                        document.getElementById('submitRechargeBtn').disabled = false;
                    }
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    console.error('AJAX error - textStatus:', textStatus, 'errorThrown:', errorThrown);
                    console.error('Response text:', jqXHR.responseText);
                    alert('Error: ' + textStatus);
                    document.getElementById('submitRechargeBtn').disabled = false;
                }
            });
        } else {
            alert('jQuery is not loaded!');
            document.getElementById('submitRechargeBtn').disabled = false;
        }
    };
    
    // Initialize when document is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initRechargeModal);
    } else {
        initRechargeModal();
    }
    </script>
{/if}