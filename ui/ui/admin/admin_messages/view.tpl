{include file="sections/header.tpl"}

<div class="row">
    <div class="col-sm-12">
        <div class="panel panel-hovered mb20 panel-primary">
            <div class="panel-heading">
                <h4>{Lang::T('Message Details')}</h4>
                <div class="btn-group pull-right">
                    <a href="{Text::url('admin_messages/list')}" class="btn btn-default btn-xs">
                        <i class="glyphicon glyphicon-arrow-left"></i> {Lang::T('Back')}
                    </a>
                    <a href="{Text::url('admin_messages/delete/', $message['id'])}" 
                       class="btn btn-danger btn-xs"
                       onclick="return confirm('{Lang::T('Delete this message')}?')">
                        <i class="glyphicon glyphicon-trash"></i> {Lang::T('Delete')}
                    </a>
                </div>
            </div>
            <div class="panel-body">
                <div class="row">
                    <div class="col-md-12">
                        <div class="table-responsive">
                            <table class="table table-bordered">
                                <tr>
                                    <th style="width: 180px;">{Lang::T('Date')}</th>
                                    <td>{Lang::dateTimeFormat($message['created_date'])}</td>
                                </tr>
                                <tr>
                                    <th>{Lang::T('Type')}</th>
                                    <td>
                                        {if $message['type'] == 'guest_message'}
                                            <span class="label label-warning">
                                                <i class="glyphicon glyphicon-comment"></i> {Lang::T('Guest Message')}
                                            </span>
                                        {elseif $message['type'] == 'user_message'}
                                            <span class="label label-primary">
                                                <i class="glyphicon glyphicon-user"></i> {Lang::T('Authenticated User Message')}
                                            </span>
                                        {elseif $message['type'] == 'recharge_request'}
                                            <span class="label label-info">
                                                <i class="glyphicon glyphicon-refresh"></i> {Lang::T('Recharge Request')}
                                            </span>
                                        {else}
                                            <span class="label label-default">
                                                <i class="glyphicon glyphicon-bell"></i> {Lang::T('Notification')}
                                            </span>
                                        {/if}
                                    </td>
                                </tr>
                                <tr>
                                    <th>{Lang::T('Status')}</th>
                                    <td>
                                        {if $message['status'] == 'unread'}
                                            <span class="label label-danger">{Lang::T('Unread')}</span>
                                        {else}
                                            <span class="label label-success">{Lang::T('Read')}</span>
                                        {/if}
                                        {if $message['read_date']}
                                            <small class="text-muted"> ({Lang::T('Read on')} {Lang::dateTimeFormat($message['read_date'])})</small>
                                        {/if}
                                    </td>
                                </tr>
                                <tr>
                                    <th>{Lang::T('Title')}</th>
                                    <td><strong>{$message['title']}</strong></td>
                                </tr>
                            </table>
                        </div>
                        
                        <div class="panel panel-default">
                            <div class="panel-heading">
                                <h4 class="panel-title">{Lang::T('Message')}</h4>
                            </div>
                            <div class="panel-body" style="background-color: #f9f9f9;">
                                <div style="white-space: pre-wrap; word-wrap: break-word; font-family: inherit;">
{$message['message']}
                                </div>
                            </div>
                        </div>
                        
                        {if $message['related_id']}
                            <div class="alert alert-info">
                                <i class="glyphicon glyphicon-link"></i> 
                                {Lang::T('Related ID')}: {$message['related_id']}
                                {if $message['type'] == 'recharge_request'}
                                    <a href="{Text::url('recharge_requests/view/', $message['related_id'])}" 
                                       class="btn btn-info btn-xs">
                                        {Lang::T('View Request')}
                                    </a>
                                {/if}
                            </div>
                        {/if}

                        {if ($message['type'] == 'user_message' && $message['related_id'] > 0) || $message['type'] == 'guest_message'}
                            <div class="panel panel-success">
                                <div class="panel-heading">
                                    <h4 class="panel-title">{Lang::T('Reply to Sender')}</h4>
                                </div>
                                <div class="panel-body">
                                    <form method="post" action="{Text::url('admin_messages/reply/', $message['id'])}">
                                        <input type="hidden" name="csrf_token" value="{$csrf_token}">
                                        <input type="hidden" name="message_id" value="{$message['id']}">
                                        <div class="form-group">
                                            <label for="reply_message">{Lang::T('Your Reply')}</label>
                                            <textarea class="form-control" name="reply_message" id="reply_message" rows="4" required placeholder="{Lang::T('Write your reply to the customer')}..."></textarea>
                                            {if $message['type'] == 'guest_message'}
                                                <small class="text-muted">{Lang::T('For guest users, this is delivered by MAC/IP on the public message page when they reconnect or refresh.')}</small>
                                            {else}
                                                <small class="text-muted">{Lang::T('This sends an inbox message and triggers a push-style notification in the customer portal.')}</small>
                                            {/if}
                                        </div>
                                        <button type="submit" class="btn btn-success">
                                            <i class="glyphicon glyphicon-send"></i> {Lang::T('Send Reply')}
                                        </button>
                                    </form>
                                </div>
                            </div>
                        {/if}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

{include file="sections/footer.tpl"}
