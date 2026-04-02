{include file="sections/header.tpl"}
<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <i class="fa fa-shield"></i>&nbsp; {Lang::T('Active Login Sessions')}
                <span class="badge pull-right">{count($sessions)}</span>
            </div>
            <div class="panel-body">
                {if count($sessions) == 0}
                    <div class="alert alert-info">{Lang::T('No active sessions found.')}</div>
                {else}
                <div class="table-responsive">
                    <table class="table table-bordered table-striped table-condensed">
                        <thead>
                            <tr>
                                <th><i class="fa fa-user"></i> {Lang::T('User')}</th>
                                <th><i class="fa fa-tag"></i> {Lang::T('Type')}</th>
                                <th><i class="fa fa-desktop"></i> {Lang::T('Device')}</th>
                                <th><i class="fa fa-globe"></i> {Lang::T('IP Address')}</th>
                                <th><i class="fa fa-sign-in"></i> {Lang::T('Login Time')}</th>
                                <th><i class="fa fa-clock-o"></i> {Lang::T('Last Seen')}</th>
                                <th>{Lang::T('Action')}</th>
                            </tr>
                        </thead>
                        <tbody>
                            {foreach $sessions as $s}
                            <tr>
                                <td>
                                    <strong>{$s['fullname']}</strong><br>
                                    <small class="text-muted">{$s['username']}</small>
                                </td>
                                <td>
                                    {if $s['user_type'] == 'SuperAdmin'}
                                        <span class="label label-danger">{$s['user_type']}</span>
                                    {elseif $s['user_type'] == 'Admin'}
                                        <span class="label label-warning">{$s['user_type']}</span>
                                    {else}
                                        <span class="label label-info">{$s['user_type']}</span>
                                    {/if}
                                </td>
                                <td>
                                    <i class="fa {$s['device']['icon']}"></i>
                                    {$s['device']['browser']} &mdash; {$s['device']['os']}
                                </td>
                                <td><code>{$s['ip']}</code></td>
                                <td>{Lang::dateTimeFormat($s['login_time'])}</td>
                                <td>
                                    {assign var="diff" value=time()-strtotime($s['last_seen'])}
                                    {if $diff < 60}
                                        <span class="text-success"><i class="fa fa-circle"></i> {Lang::T('Just now')}</span>
                                    {elseif $diff < 3600}
                                        <span class="text-warning"><i class="fa fa-circle"></i> {floor($diff/60)}m ago</span>
                                    {else}
                                        <span class="text-muted"><i class="fa fa-circle-o"></i> {floor($diff/3600)}h ago</span>
                                    {/if}
                                </td>
                                <td>
                                    {if $s['token_hash']}
                                    <form method="post" action="{Text::url('logs/sessions-revoke')}" style="display:inline">
                                        <input type="hidden" name="token_hash" value="{$s['token_hash']}">
                                        <button type="submit" class="btn btn-danger btn-xs"
                                            onclick="return ask(this, '{Lang::T('Revoke this session?')}')" title="Revoke">
                                            <i class="fa fa-ban"></i> {Lang::T('Revoke')}
                                        </button>
                                    </form>
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
{include file="sections/footer.tpl"}
