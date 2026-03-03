{include file="customer/header-public.tpl"}

<div class="hidden-xs" style="height:100px"></div>
<div class="row">
    <div class="col-sm-6 col-sm-offset-3">
        <div class="panel panel-primary">
            <div class="panel-heading">{Lang::T('Log in to Member Panel')}</div>
            <div class="panel-body">
                <form action="{Text::url('login/post')}" method="post">
                    <input type="hidden" name="csrf_token" value="{$csrf_token}">
                    <div class="form-group">
                        <label>
                            {if $_c['registration_username'] == 'phone'}
                                {Lang::T('Phone Number')} <span style="color: red;">*</span>
                            {elseif $_c['registration_username'] == 'email'}
                                {Lang::T('Email')} <span style="color: red;">*</span>
                            {else}
                                {Lang::T('Username')} <span style="color: red;">*</span>
                            {/if}
                        </label>
                        <div class="input-group">
                            {if $_c['registration_username'] == 'phone'}
                                <span class="input-group-addon" id="basic-addon1"><i
                                        class="glyphicon glyphicon-phone-alt"></i></span>
                            {elseif $_c['registration_username'] == 'email'}
                                <span class="input-group-addon" id="basic-addon1"><i
                                        class="glyphicon glyphicon-envelope"></i></span>
                            {else}
                                <span class="input-group-addon" id="basic-addon1"><i
                                        class="glyphicon glyphicon-user"></i></span>
                            {/if}
                            <input type="text" class="form-control" name="username" required
                                placeholder="{if $_c['country_code_phone']!= '' || $_c['registration_username'] == 'phone'}{$_c['country_code_phone']} {Lang::T('Phone Number')}{elseif $_c['registration_username'] == 'email'}{Lang::T('Email')}{else}johndoe{/if}">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>{Lang::T('Password')} <span style="color: red;">*</span></label>
                        <div class="input-group">
                            <span class="input-group-addon" id="basic-addon2"><i
                                    class="glyphicon glyphicon-lock"></i></span>
                            <input type="password" class="form-control" name="password"
                                placeholder="{Lang::T('Password')}">
                        </div>
                    </div>

                    <div class="form-group">
                        <button type="submit" class="btn btn-primary btn-block" style="margin-bottom: 10px; padding: 12px 20px; font-weight: bold; font-size: 16px;">
                            <i class="glyphicon glyphicon-log-in"></i> {Lang::T('Login')}
                        </button>
                    </div>
                    {if $_c['disable_registration'] != 'noreg'}
                        <div class="form-group">
                            <a href="{Text::url('register')}" class="btn btn-success btn-block" style="padding: 12px 20px; font-weight: bold; font-size: 16px;">
                                <i class="glyphicon glyphicon-user"></i> {Lang::T('Create Account')}
                            </a>
                        </div>
                    {/if}
                    <div style="margin-top: 15px; padding-top: 15px; border-top: 1px solid #ddd;">
                    <center>
                        <a href="{Text::url('forgot')}" class="btn btn-link">{Lang::T('Forgot Password')}</a>
                        <br>
                        <a href="javascript:showPrivacy()">Privacy</a>
                        &bull;
                        <a href="javascript:showTaC()">T &amp; C</a>
                    </center>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Modal -->
<div class="modal fade" id="HTMLModal" tabindex="-1" role="dialog">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span
                        aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body" id="HTMLModal_konten"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">&times;</button>
            </div>
        </div>
    </div>
</div>

{include file="customer/footer-public.tpl"}