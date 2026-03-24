{include file="sections/header.tpl"}

<div class="row">
    <div class="col-md-6 col-sm-12 col-md-offset-3">
        <div class="panel panel-hovered panel-info panel-stacked mb30">
            <div class="panel-heading">{Lang::T('Voucher Details')}</div>
            <div class="panel-body">
                <div class="row">
                    <div class="col-sm-6" style="margin-bottom: 12px;">
                        <img src="{$voucher_qr_src}" alt="QR Code" style="max-width: 180px; width: 100%; border: 1px solid #ddd; padding: 8px; border-radius: 6px;">
                    </div>
                    <div class="col-sm-6">
                        <p><b>{Lang::T('Voucher ID')}:</b> {$voucher['id']}</p>
                        <p><b>{Lang::T('Code')}:</b> {$voucher['code']}</p>
                        <p><b>{Lang::T('Plan')}:</b> {$plan['name_plan']}</p>
                        <p><b>{Lang::T('Type')}:</b> {$voucher['type']}</p>
                        <p><b>{Lang::T('Router')}:</b> {$voucher['routers']}</p>
                        <p><b>{Lang::T('Status')}:</b> {if $voucher['status'] eq '1'}Used{else}Not Use{/if}</p>
                        <p><b>{Lang::T('Created')}:</b> {if $voucher['created_at']}{Lang::dateTimeFormat($voucher['created_at'])}{/if}</p>
                        <p><b>{Lang::T('Used Date')}:</b> {if $voucher['used_date']}{Lang::dateTimeFormat($voucher['used_date'])}{else}-{/if}</p>
                    </div>
                </div>
                <div class="row" style="margin-top: 10px;">
                    <div class="col-sm-12">
                        <label>{Lang::T('Voucher Login URL')}</label>
                        <input type="text" class="form-control" value="{$voucher_login_url}" readonly onclick="this.select();">
                    </div>
                </div>
            </div>
        </div>

        <div class="panel panel-hovered panel-primary panel-stacked mb30">
            <div class="panel-body">
                <form class="form-horizontal" method="post" action="{Text::url('')}plan/print" target="_blank">
                    <pre id="content"></pre>
                    <textarea class="hidden" id="formcontent" name="content">{$print}</textarea>
                    <input type="hidden" name="id" value="{$in['id']}">
                    <a href="{Text::url('')}plan/voucher" class="btn btn-default btn-sm"><i
                            class="ion-reply-all"></i>{Lang::T('Finish')}</a>
                    <a href="https://api.whatsapp.com/send/?text={$whatsapp}" target="_blank"
                        class="btn btn-primary btn-sm">
                        <i class="glyphicon glyphicon-share"></i> WhatsApp</a>
                    <button type="submit" class="btn btn-info text-black btn-sm"><i
                            class="glyphicon glyphicon-print"></i>
                        Print</button>
                    <a href="nux://print?text={urlencode($print)}"
                        class="btn btn-success text-black btn-sm hidden-md hidden-lg">
                        <i class="glyphicon glyphicon-phone"></i>
                        NuxPrint
                    </a>
                    <a href="https://github.com/hotspotbilling/android-printer"
                        class="btn btn-success text-black btn-sm hidden-xs hidden-sm" target="_blank">
                        <i class="glyphicon glyphicon-phone"></i>
                        NuxPrint
                    </a>
                </form>
                <javascript type="text/javascript">
                </javascript>
            </div>
        </div>
    </div>
</div>
<script type="text/javascript">
    document.getElementById('content').innerHTML = document.getElementById('formcontent').innerHTML;
</script>
{include file="sections/footer.tpl"}