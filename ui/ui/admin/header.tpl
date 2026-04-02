<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <title>{$_title} - {$_c['CompanyName']}</title>
    <link rel="shortcut icon" href="{$app_url}/ui/ui/images/logo.png" type="image/x-icon" />

    <script>
        var appUrl = '{$app_url}';
    </script>

    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/bootstrap.min.css">
    <link rel="stylesheet" href="{$app_url}/ui/ui/fonts/ionicons/css/ionicons.min.css">
    <link rel="stylesheet" href="{$app_url}/ui/ui/fonts/font-awesome/css/font-awesome.min.css">
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/modern-AdminLTE.min.css">
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/select2.min.css" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/select2-bootstrap.min.css" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/sweetalert2.min.css" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/plugins/pace.css" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/summernote/summernote.min.css" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/phpnuxbill.css?2025.2.4" />
    <link rel="stylesheet" href="{$app_url}/ui/ui/styles/7.css" />
    
    {if !empty($_c['theme']) && $_c['theme'] neq 'default'}
        <link rel="stylesheet" href="{$app_url}/ui/ui/styles/theme-{$_c['theme']}.css?2025.2.4" />
    {/if}

    <script src="{$app_url}/ui/ui/scripts/sweetalert2.all.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.5.1/dist/chart.min.js"></script>
    <style>

    </style>
    {if isset($xheader)}
        {$xheader}
    {/if}

</head>

<body class="hold-transition modern-skin-dark sidebar-mini {if $_kolaps}sidebar-collapse{/if}">
    <div class="wrapper">
        <header class="main-header">
            <a href="{Text::url('dashboard')}" class="logo">
                <span class="logo-mini"><b>B</b>N</span>
                <span class="logo-lg">{$_c['CompanyName']}</span>
            </a>
            <nav class="navbar navbar-static-top">
                <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button" onclick="return setKolaps()">
                    <span class="sr-only">Toggle navigation</span>
                </a>
                <div class="navbar-custom-menu">
                    <ul class="nav navbar-nav">
                        <div class="wrap">
                            <div class="">
                                <button id="openSearch" class="search"><i class="fa fa-search x2"></i></button>
                            </div>
                        </div>
                        <div id="searchOverlay" class="search-overlay">
                            <div class="search-container">
                                <input type="text" id="searchTerm" class="searchTerm"
                                    placeholder="{Lang::T('Search Users')}" autocomplete="off">
                                <div id="searchResults" class="search-results">
                                    <!-- Search results will be displayed here -->
                                </div>
                                <button type="button" id="closeSearch" class="cancelButton">{Lang::T('Cancel')}</button>
                            </div>
                        </div>
                        <li>
                            <a class="toggle-container" href="#">
                                <i class="toggle-icon" id="toggleIcon">🌜</i>
                            </a>
                        </li>
                        <li class="dropdown user user-menu">
                            <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                                <img src="{$app_url}/{$UPLOAD_PATH}{$_admin['photo']}.thumb.jpg"
                                    onerror="this.src='{$app_url}/{$UPLOAD_PATH}/admin.default.png'" class="user-image"
                                    alt="Avatar">
                                <span class="hidden-xs">{$_admin['fullname']}</span>
                            </a>
                            <ul class="dropdown-menu">
                                <li class="user-header">
                                    <img src="{$app_url}/{$UPLOAD_PATH}{$_admin['photo']}.thumb.jpg"
                                        onerror="this.src='{$app_url}/{$UPLOAD_PATH}/admin.default.png'" class="img-circle"
                                        alt="Avatar">
                                    <p>
                                        {$_admin['fullname']}
                                        <small>{Lang::T($_admin['user_type'])}</small>
                                    </p>
                                </li>
                                <li class="user-body">
                                    <div class="row">
                                        <div class="col-xs-7 text-center text-sm">
                                            <a href="{Text::url('settings/change-password')}"><i
                                                    class="ion ion-settings"></i>
                                                {Lang::T('Change Password')}</a>
                                        </div>
                                        <div class="col-xs-5 text-center text-sm">
                                            <a href="{Text::url('settings/users-view/', $_admin['id'])}">
                                                <i class="ion ion-person"></i> {Lang::T('My Account')}</a>
                                        </div>
                                    </div>
                                </li>
                                <li class="user-footer">
                                    <div class="pull-right">
                                        <a href="{Text::url('logout')}" class="btn btn-default btn-flat"><i
                                                class="ion ion-power"></i> {Lang::T('Logout')}</a>
                                    </div>
                                </li>
                            </ul>
                        </li>
                    </ul>
                </div>
            </nav>
        </header>
        <aside class="main-sidebar">
            <section class="sidebar">
                <ul class="sidebar-menu" data-widget="tree">
                    <li {if $_system_menu eq 'dashboard' }class="active" {/if}>
                        <a href="{Text::url('dashboard')}">
                            <i class="ion ion-monitor"></i>
                            <span>{Lang::T('Dashboard')}</span>
                        </a>
                    </li>
                    {$_MENU_AFTER_DASHBOARD}
                    <li {if $_system_menu eq 'customers' }class="active" {/if}>
                        <a href="{Text::url('customers')}">
                            <i class="fa fa-user"></i>
                            <span>{Lang::T('Customer')}</span>
                        </a>
                    </li>
                    {$_MENU_AFTER_CUSTOMERS}
                    {if !in_array($_admin['user_type'],['Report'])}
                        <li class="{if $_routes[0] eq 'plan' || $_routes[0] eq 'coupons' || $_routes[0] eq 'recharge_requests' || $_routes[0] eq 'admin_messages'}active{/if} treeview">
                            <a href="#">
                                <i class="fa fa-ticket"></i> <span>{Lang::T('Services')}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                            <ul class="treeview-menu">
                                <li {if $_routes[1] eq 'list' }class="active" {/if}><a
                                        href="{Text::url('plan/list')}">{Lang::T('Active Customers')}</a></li>
                                {if $_c['disable_voucher'] != 'yes'}
                                    <li {if $_routes[1] eq 'refill' }class="active" {/if}><a
                                            href="{Text::url('plan/refill')}">{Lang::T('Refill Customer')}</a></li>
                                {/if}
                                {if $_c['disable_voucher'] != 'yes'}
                                    <li {if $_routes[1] eq 'voucher' }class="active" {/if}><a
                                            href="{Text::url('plan/voucher')}">{Lang::T('Vouchers')}</a></li>
                                {/if}
                                {if $_c['enable_coupons'] == 'yes'}
                                    <li {if $_routes[0] eq 'coupons' }class="active" {/if}><a
                                            href="{Text::url('coupons')}">{Lang::T('Coupons')}</a></li>
                                {/if}
                                <li {if $_routes[1] eq 'recharge' }class="active" {/if}><a
                                        href="{Text::url('plan/recharge')}">{Lang::T('Recharge Customer')}</a></li>
                                <li {if $_routes[0] eq 'recharge_requests' }class="active" {/if}><a
                                        href="{Text::url('recharge_requests')}">{Lang::T('Recharge Requests')}</a></li>
                                <li {if $_routes[0] eq 'admin_messages' }class="active" {/if}><a
                                        href="{Text::url('admin_messages')}">{Lang::T('Admin Messages')}</a></li>
                                {if $_c['enable_balance'] == 'yes'}
                                    <li {if $_routes[1] eq 'deposit' }class="active" {/if}><a
                                            href="{Text::url('plan/deposit')}">{Lang::T('Refill Balance')}</a></li>
                                {/if}
                                {$_MENU_SERVICES}
                            </ul>
                        </li>
                    {/if}
                    {$_MENU_AFTER_SERVICES}
                    {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                        <li class="{if $_system_menu eq 'services'}active{/if} treeview">
                            <a href="#">
                                <i class="ion ion-cube"></i> <span>{Lang::T('Internet Plan')}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                            <ul class="treeview-menu">
                                <li {if $_routes[1] eq 'hotspot' }class="active" {/if}><a
                                        href="{Text::url('services/hotspot')}">Hotspot</a></li>
                                <li {if $_routes[1] eq 'pppoe' }class="active" {/if}><a
                                        href="{Text::url('services/pppoe')}">PPPOE</a></li>
                                <li {if $_routes[1] eq 'vpn' }class="active" {/if}><a href="{Text::url('services/vpn')}">VPN</a>
                                </li>
                                <li {if $_routes[1] eq 'list' }class="active" {/if}><a
                                        href="{Text::url('bandwidth/list')}">Bandwidth</a></li>
                                {if $_c['enable_balance'] == 'yes'}
                                    <li {if $_routes[1] eq 'balance' }class="active" {/if}><a
                                            href="{Text::url('services/balance')}">{Lang::T('Customer Balance')}</a></li>
                                {/if}
                                {$_MENU_PLANS}
                            </ul>
                        </li>
                    {/if}
                    {$_MENU_AFTER_PLANS}
                    <li class="{if in_array($_routes[0], ['maps'])}active{/if} treeview">
                        <a href="#">
                            <i class="fa fa-map-marker"></i> <span>{Lang::T('Maps')}</span>
                            <span class="pull-right-container">
                                <i class="fa fa-angle-left pull-right"></i>
                            </span>
                        </a>
                        <ul class="treeview-menu">
                            <li {if $_routes[1] eq 'customer' }class="active" {/if}><a
                                    href="{Text::url('maps/customer')}">{Lang::T('Customer')}</a></li>
                            <li {if $_routes[1] eq 'routers' }class="active" {/if}><a
                                    href="{Text::url('maps/routers')}">{Lang::T('Routers')}</a></li>
                            <li {if $_routes[1] eq 'odp' }class="active" {/if}><a
                                    href="{Text::url('maps/odp')}">{Lang::T('ODPs')}</a></li>
                            {$_MENU_MAPS}
                        </ul>
                    </li>
                    <li class="{if $_system_menu eq 'reports'}active{/if} treeview">
                        {if in_array($_admin['user_type'],['SuperAdmin','Admin', 'Report'])}
                            <a href="#">
                                <i class="ion ion-clipboard"></i> <span>{Lang::T('Reports')}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                        {/if}
                        <ul class="treeview-menu">
                            <li {if $_routes[1] eq 'reports' }class="active" {/if}><a
                                    href="{Text::url('reports')}">{Lang::T('Daily Reports')}</a></li>
                            <li {if $_routes[1] eq 'activation' }class="active" {/if}><a
                                    href="{Text::url('reports/activation')}">{Lang::T('Activation History')}</a></li>
                            <li {if $_system_menu eq 'usage'}class="active" {/if}><a
                                    href="{Text::url('usage')}">{Lang::T('Usage Analytics')}</a></li>
                            {$_MENU_REPORTS}
                        </ul>
                    </li>
                    {$_MENU_AFTER_REPORTS}
                    <li class="{if $_system_menu eq 'message'}active{/if} treeview">
                        <a href="#">
                            <i class="ion ion-android-chat"></i> <span>{Lang::T('Send Message')}</span>
                            <span class="pull-right-container">
                                <i class="fa fa-angle-left pull-right"></i>
                            </span>
                        </a>
                        <ul class="treeview-menu">
                            <li {if $_routes[1] eq 'send' }class="active" {/if}><a
                                    href="{Text::url('message/send')}">{Lang::T('Single Customer')}</a></li>
                            <li {if $_routes[1] eq 'send_bulk' }class="active" {/if}><a
                                    href="{Text::url('message/send_bulk')}">{Lang::T('Bulk Customers')}</a></li>
                            {$_MENU_MESSAGE}
                        </ul>
                    </li>
                    {$_MENU_AFTER_MESSAGE}
                    {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                        <li class="{if $_system_menu eq 'network'}active{/if} treeview">
                            <a href="#">
                                <i class="ion ion-network"></i> <span>{Lang::T('Network')}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                            <ul class="treeview-menu">
                                <li {if $_routes[0] eq 'routers' and $_routes[1] eq '' }class="active" {/if}><a
                                        href="{Text::url('routers')}">Routers</a></li>
                                <li {if $_routes[0] eq 'pool' and $_routes[1] eq 'list' }class="active" {/if}><a
                                        href="{Text::url('pool/list')}">IP Pool</a></li>
                                <li {if $_routes[0] eq 'pool' and $_routes[1] eq 'port' }class="active" {/if}><a
                                        href="{Text::url('pool/port')}">Port Pool</a></li>
                                <li {if $_routes[0] eq 'odp' and $_routes[1] eq '' }class="active" {/if}><a
                                        href="{Text::url('odp')}">ODP List</a></li>
                                {$_MENU_NETWORK}
                            </ul>
                        </li>
                        {$_MENU_AFTER_NETWORKS}
                        {if $_c['radius_enable']}
                            <li class="{if $_system_menu eq 'radius'}active{/if} treeview">
                                <a href="#">
                                    <i class="fa fa-database"></i> <span>{Lang::T('Radius')}</span>
                                    <span class="pull-right-container">
                                        <i class="fa fa-angle-left pull-right"></i>
                                    </span>
                                </a>
                                <ul class="treeview-menu">
                                    <li {if $_routes[0] eq 'radius' and $_routes[1] eq 'nas-list' }class="active" {/if}><a
                                            href="{Text::url('radius/nas-list')}">{Lang::T('Radius NAS')}</a></li>
                                    {$_MENU_RADIUS}
                                </ul>
                            </li>
                        {/if}
                        {$_MENU_AFTER_RADIUS}
                        <li class="{if $_system_menu eq 'pages'}active{/if} treeview">
                            <a href="#">
                                <i class="ion ion-document"></i> <span>{Lang::T("Static Pages")}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                            <ul class="treeview-menu">
                                <li {if $_routes[1] eq 'Order_Voucher' }class="active" {/if}><a
                                        href="{Text::url('pages/Order_Voucher')}">{Lang::T('Order Voucher')}</a></li>
                                <li {if $_routes[1] eq 'Voucher' }class="active" {/if}><a
                                        href="{Text::url('pages/Voucher')}">{Lang::T('Theme Voucher')}</a></li>
                                <li {if $_routes[1] eq 'Announcement' }class="active" {/if}><a
                                        href="{Text::url('pages/Announcement')}">{Lang::T('Announcement')}</a></li>
                                <li {if $_routes[1] eq 'Announcement_Customer' }class="active" {/if}><a
                                        href="{Text::url('pages/Announcement_Customer')}">{Lang::T('Customer Announcement')}</a>
                                </li>
                                <li {if $_routes[1] eq 'Registration_Info' }class="active" {/if}><a
                                        href="{Text::url('pages/Registration_Info')}">{Lang::T('Registration Info')}</a></li>
                                <li {if $_routes[1] eq 'Payment_Info' }class="active" {/if}><a
                                        href="{Text::url('pages/Payment_Info')}">{Lang::T('Payment Info')}</a></li>
                                <li {if $_routes[1] eq 'Privacy_Policy' }class="active" {/if}><a
                                        href="{Text::url('pages/Privacy_Policy')}">{Lang::T('Privacy Policy')}</a></li>
                                <li {if $_routes[1] eq 'Terms_and_Conditions' }class="active" {/if}><a
                                        href="{Text::url('pages/Terms_and_Conditions')}">{Lang::T('Terms and Conditions')}</a></li>
                                {$_MENU_PAGES}
                            </ul>
                        </li>
                    {/if}
                    {$_MENU_AFTER_PAGES}
                    <li
                        class="{if $_system_menu eq 'settings' || $_system_menu eq 'paymentgateway' }active{/if} treeview">
                        <a href="#">
                            <i class="ion ion-gear-a"></i> <span>{Lang::T('Settings')}</span>
                            <span class="pull-right-container">
                                <i class="fa fa-angle-left pull-right"></i>
                            </span>
                        </a>
                        <ul class="treeview-menu">
                            {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                                <li {if $_routes[1] eq 'app' }class="active" {/if}><a
                                        href="{Text::url('settings/app')}">{Lang::T('General Settings')}</a></li>
                                <li {if $_routes[1] eq 'localisation' }class="active" {/if}><a
                                        href="{Text::url('settings/localisation')}">{Lang::T('Localisation')}</a></li>
                                <li {if $_routes[0] eq 'customfield' }class="active" {/if}><a
                                        href="{Text::url('customfield')}">{Lang::T('Custom Fields')}</a></li>
                                <li {if $_routes[1] eq 'miscellaneous' }class="active" {/if}><a
                                        href="{Text::url('settings/miscellaneous')}">{Lang::T('Miscellaneous')}</a></li>
                                <li {if $_routes[1] eq 'maintenance' }class="active" {/if}><a
                                        href="{Text::url('settings/maintenance')}">{Lang::T('Maintenance Mode')}</a></li>
                                <li {if $_routes[0] eq 'widgets' }class="active" {/if}><a
                                            href="{Text::url('widgets')}">{Lang::T('Widgets')}</a></li>
                                <li {if $_routes[1] eq 'notifications' }class="active" {/if}><a
                                        href="{Text::url('settings/notifications')}">{Lang::T('User Notification')}</a></li>
                                <li {if $_routes[1] eq 'devices' }class="active" {/if}><a
                                        href="{Text::url('settings/devices')}">{Lang::T('Devices')}</a></li>
                            {/if}
                            {if in_array($_admin['user_type'],['SuperAdmin','Admin','Agent'])}
                                <li {if $_routes[1] eq 'users' }class="active" {/if}><a
                                        href="{Text::url('settings/users')}">{Lang::T('Administrator Users')}</a></li>
                            {/if}
                            {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                                <li {if $_routes[1] eq 'dbstatus' }class="active" {/if}><a
                                        href="{Text::url('settings/dbstatus')}">{Lang::T('Backup/Restore')}</a></li>
                                <li {if $_routes[1] eq 'dbbrowser' }class="active" {/if}><a
                                    href="{Text::url('settings/dbbrowser')}">{Lang::T('Database Browser')}</a></li>
                                <li {if $_routes[0] eq 'test_accounts' }class="active" {/if}><a
                                        href="{Text::url('test_accounts/list')}"><i class="glyphicon glyphicon-filter"></i> {Lang::T('Test Accounts')}</a></li>
                                <li><a href="{Text::url('settings/clearcache')}" onclick="return confirm('Clear all template cache?')"><i class="glyphicon glyphicon-refresh"></i> {Lang::T('Clear Cache')}</a></li>
                                <li {if $_routes[0] eq 'server_uptime' }class="active" {/if}><a
                                        href="{Text::url('server_uptime')}"><i class="fa fa-signal"></i> {Lang::T('Server Status & Uptime')}</a></li>
                                <li {if $_system_menu eq 'paymentgateway' }class="active" {/if}>
                                    <a href="{Text::url('paymentgateway')}">
                                        <span class="text">{Lang::T('Payment Gateway')}</span>
                                    </a>
                                </li>
                                {$_MENU_SETTINGS}
                                <li {if $_routes[0] eq 'pluginmanager' }class="active" {/if}>
                                    <a href="{Text::url('pluginmanager')}"><i class="glyphicon glyphicon-tasks"></i>
                                        {Lang::T('Plugin Manager')}</a>
                                </li>
                            {/if}
                        </ul>
                    </li>
                    {$_MENU_AFTER_SETTINGS}
                    {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                        <li class="{if $_system_menu eq 'logs' }active{/if} treeview">
                            <a href="#">
                                <i class="ion ion-clock"></i> <span>{Lang::T('Logs')}</span>
                                <span class="pull-right-container">
                                    <i class="fa fa-angle-left pull-right"></i>
                                </span>
                            </a>
                            <ul class="treeview-menu">
                                <li {if $_routes[1] eq 'list' }class="active" {/if}><a
                                        href="{Text::url('logs/phpnuxbill')}">PhpNuxBill</a></li>
                                {if $_c['radius_enable']}
                                    <li {if $_routes[1] eq 'radius' }class="active" {/if}><a
                                            href="{Text::url('logs/radius')}">Radius</a>
                                    </li>
                                {/if}
                                <li {if $_routes[1] eq 'message' }class="active" {/if}><a
                                    href="{Text::url('logs/message')}">Message</a></li>
                                <li {if $_routes[1] eq 'sessions' }class="active" {/if}><a
                                    href="{Text::url('logs/sessions')}"><i class="fa fa-shield"></i> {Lang::T('Active Sessions')}</a></li>
                                {$_MENU_LOGS}
                            </ul>
                        </li>
                    {/if}
                    {$_MENU_AFTER_LOGS}
                    {if in_array($_admin['user_type'],['SuperAdmin','Admin'])}
                        <li {if $_routes[1] eq 'docs' }class="active" {/if}>
                            <a href="{if $_c['docs_clicked'] != 'yes'}{Text::url('settings/docs')}{else}{$app_url}/docs{/if}">
                                <i class="ion ion-ios-bookmarks"></i>
                                <span class="text">{Lang::T('Documentation')}</span>
                                {if $_c['docs_clicked'] != 'yes'}
                                    <span class="pull-right-container"><small
                                            class="label pull-right bg-green">New</small></span>
                                {/if}
                            </a>
                        </li>
                        <li {if $_system_menu eq 'community' }class="active" {/if}>
                            <a href="{Text::url('community')}">
                                <i class="ion ion-chatboxes"></i>
                                <span class="text">Community</span>
                            </a>
                        </li>
                    {/if}
                    {$_MENU_AFTER_COMMUNITY}
                </ul>
            </section>
        </aside>

        {if $_c['maintenance_mode'] == 1}
            <div class="notification-top-bar">
                <p>{Lang::T('The website is currently in maintenance mode, this means that some or all functionality may be
                unavailable to regular users during this time.')}<small> &nbsp;&nbsp;<a
                            href="{Text::url('settings/maintenance')}">{Lang::T('Turn Off')}</a></small></p>
            </div>
        {/if}

        <div class="content-wrapper">
            <section class="content-header">
                <h1>
                    {$_title}
                </h1>
            </section>

            <section class="content">
                {if isset($notify)}
                    <script>
                        // Display SweetAlert toast notification
                        Swal.fire({
                            icon: '{if $notify_t == "s"}success{else}error{/if}',
                            title: '{$notify}',
                            position: 'top-end',
                            showConfirmButton: false,
                            timer: 5000,
                            timerProgressBar: true,
                            didOpen: (toast) => {
                                toast.addEventListener('mouseenter', Swal.stopTimer)
                                toast.addEventListener('mouseleave', Swal.resumeTimer)
                            }
                        });
                    </script>
                {/if}
                
                <!-- Unified Notification System -->
                <script>
                (function() {
                    // Only run for admin users
                    var isAdmin = '{$_admin['user_type']}';
                    if (!isAdmin || isAdmin === '') return;
                    
                    var notificationPermission = false;
                    var audioContext = null;
                    var audioReady = false;
                    
                    // Initialize audio context on first user interaction
                    function initAudio() {
                        if (!audioContext) {
                            try {
                                audioContext = new (window.AudioContext || window.webkitAudioContext)();
                                console.log('AudioContext created, state:', audioContext.state);
                            } catch (e) {
                                console.error('Failed to create AudioContext:', e);
                                return false;
                            }
                        }
                        
                        if (audioContext && audioContext.state === 'suspended') {
                            audioContext.resume().then(() => {
                                console.log('AudioContext resumed');
                                audioReady = true;
                            }).catch(e => {
                                console.error('Failed to resume AudioContext:', e);
                            });
                        } else {
                            audioReady = true;
                        }
                        return true;
                    }
                    
                    // Initialize on any user interaction
                    ['click', 'keydown', 'touchstart'].forEach(function(event) {
                        document.addEventListener(event, function initOnInteraction() {
                            if (initAudio()) {
                                document.removeEventListener(event, initOnInteraction);
                            }
                        }, { once: true });
                    });
                    
                    // Request notification permission on page load
                    if ('Notification' in window && Notification.permission === 'default') {
                        Notification.requestPermission().then(function(permission) {
                            notificationPermission = (permission === 'granted');
                        });
                    } else if ('Notification' in window && Notification.permission === 'granted') {
                        notificationPermission = true;
                    }
                    
                    // Sound configurations for different notification types
                    var soundConfigs = {
                        recharge: {
                            beeps: 5,
                            frequencies: [1000, 1200], // Alternating high-pitched beeps
                            volume: 0.8,
                            duration: 0.2,
                            interval: 0.25
                        },
                        message: {
                            beeps: 3,
                            frequencies: [600, 800], // Lower, softer tones
                            volume: 0.6,
                            duration: 0.15,
                            interval: 0.3
                        },
                        default: {
                            beeps: 4,
                            frequencies: [1000, 1200],
                            volume: 0.7,
                            duration: 0.2,
                            interval: 0.25
                        }
                    };
                    
                    // Create notification sound with configurable parameters
                    function playNotificationSound(soundType) {
                        console.log('playNotificationSound called for type:', soundType);
                        
                        if (!audioContext) {
                            console.log('Initializing audio...');
                            initAudio();
                            setTimeout(function() { playNotificationSound(soundType); }, 100);
                            return;
                        }
                        
                        if (audioContext.state === 'suspended') {
                            console.log('AudioContext suspended, resuming...');
                            audioContext.resume().then(() => {
                                playNotificationSound(soundType);
                            });
                            return;
                        }
                        
                        try {
                            var config = soundConfigs[soundType] || soundConfigs.default;
                            console.log('Playing ' + soundType + ' sound with config:', config);
                            var now = audioContext.currentTime;
                            
                            for (var i = 0; i < config.beeps; i++) {
                                (function(index) {
                                    var startTime = now + (index * config.interval);
                                    var osc = audioContext.createOscillator();
                                    var gain = audioContext.createGain();
                                    
                                    osc.connect(gain);
                                    gain.connect(audioContext.destination);
                                    
                                    // Alternate between frequencies
                                    osc.frequency.value = config.frequencies[index % config.frequencies.length];
                                    
                                    gain.gain.setValueAtTime(0, startTime);
                                    gain.gain.linearRampToValueAtTime(config.volume, startTime + 0.01);
                                    gain.gain.linearRampToValueAtTime(config.volume, startTime + config.duration);
                                    gain.gain.linearRampToValueAtTime(0, startTime + config.duration + 0.05);
                                    
                                    osc.start(startTime);
                                    osc.stop(startTime + config.duration + 0.05);
                                })(i);
                            }
                            
                            console.log('Sound scheduled successfully');
                        } catch (e) {
                            console.error('Audio playback failed:', e);
                        }
                    }
                    
                    // Expose test functions globally
                    window.testRechargeNotificationSound = function() { playNotificationSound('recharge'); };
                    window.testMessageNotificationSound = function() { playNotificationSound('message'); };
                    
                    // Generic notification checker factory
                    function createNotificationChecker(config) {
                        var lastCheckTime = new Date().toISOString().slice(0, 19).replace('T', ' ');
                        
                        return {
                            checkNew: function() {
                                fetch(appUrl + '/index.php?_route=' + config.endpoint, {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                                    body: 'last_check=' + encodeURIComponent(lastCheckTime)
                                })
                                .then(response => response.json())
                                .then(data => {
                                    if (data.status === 'success' && data.new_count > 0) {
                                        console.log('New ' + config.type + ' detected:', data.new_count);
                                        playNotificationSound(config.soundType);
                                        
                                        // Show SweetAlert
                                        Swal.fire({
                                            icon: config.icon,
                                            title: config.title(data),
                                            html: config.message(data),
                                            position: 'top-end',
                                            showConfirmButton: true,
                                            confirmButtonText: config.confirmText,
                                            showCancelButton: true,
                                            cancelButtonText: 'Dismiss',
                                            timer: 15000,
                                            timerProgressBar: true,
                                        }).then((result) => {
                                            if (result.isConfirmed) {
                                                window.location.href = appUrl + config.url(data);
                                            }
                                        });
                                        
                                        // Browser notification
                                        if (notificationPermission && data.latest_request) {
                                            var notification = new Notification(config.notificationTitle(data), {
                                                body: config.notificationBody(data),
                                                icon: appUrl + '/ui/ui/images/logo.png',
                                                requireInteraction: true,
                                                tag: config.type + '-' + (data.latest_request.id || Date.now())
                                            });
                                            
                                            notification.onclick = function() {
                                                window.focus();
                                                window.location.href = appUrl + config.url(data);
                                                notification.close();
                                            };
                                        }
                                        
                                        lastCheckTime = data.timestamp;
                                    }
                                })
                                .catch(error => console.log(config.type + ' check failed:', error));
                            },
                            
                            checkPending: function() {
                                if (!config.pendingCheck) return;
                                
                                fetch(appUrl + '/index.php?_route=' + config.endpoint, {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                                    body: 'last_check=' + encodeURIComponent(lastCheckTime)
                                })
                                .then(response => response.json())
                                .then(data => {
                                    var pendingCount = data.total_pending || data.total_unread || 0;
                                    if (data.status === 'success' && pendingCount > 0) {
                                        console.log('Pending ' + config.type + ' reminder:', pendingCount);
                                        playNotificationSound(config.soundType);
                                        
                                        Swal.fire({
                                            icon: 'warning',
                                            title: config.pendingTitle(data),
                                            html: config.pendingMessage(data),
                                            position: 'top-end',
                                            showConfirmButton: true,
                                            confirmButtonText: config.confirmText,
                                            showCancelButton: true,
                                            cancelButtonText: 'Dismiss',
                                            timer: 15000,
                                            timerProgressBar: true,
                                        }).then((result) => {
                                            if (result.isConfirmed) {
                                                window.location.href = appUrl + config.url(data);
                                            }
                                        });
                                    }
                                })
                                .catch(error => console.log(config.type + ' pending check failed:', error));
                            }
                        };
                    }
                    
                    // Configure recharge request notifications
                    var rechargeChecker = createNotificationChecker({
                        type: 'recharge_requests',
                        endpoint: 'recharge_requests/check_new',
                        soundType: 'recharge',
                        icon: 'info',
                        title: (data) => 'New Recharge Request!',
                        message: (data) => '<strong>' + data.new_count + '</strong> new recharge request(s)<br>' +
                            (data.latest_request ? '<br>Customer: <strong>' + data.latest_request.username + '</strong><br>Plan: ' + data.latest_request.plan_name : ''),
                        confirmText: 'View Requests',
                        url: (data) => '/index.php?_route=recharge_requests/list',
                        notificationTitle: (data) => 'New Recharge Request',
                        notificationBody: (data) => data.latest_request ? 'Customer: ' + data.latest_request.username + '\nPlan: ' + data.latest_request.plan_name : 'New request',
                        pendingCheck: true,
                        pendingTitle: (data) => 'Pending Recharge Requests!',
                        pendingMessage: (data) => 'You have <strong>' + data.total_pending + '</strong> pending recharge request(s) waiting for action.<br><br><small>This reminder will repeat every 5 minutes until handled.</small>'
                    });
                    
                    // Configure admin messages notifications
                    var messageChecker = createNotificationChecker({
                        type: 'admin_messages',
                        endpoint: 'admin_messages/check_new',
                        soundType: 'message',
                        icon: 'warning',
                        title: (data) => 'New Admin Message!',
                        message: (data) => '<strong>' + data.new_count + '</strong> new message(s)<br>' +
                            (data.latest_message ? '<br>Type: <strong>' + data.latest_message.type + '</strong><br>Title: ' + data.latest_message.title : ''),
                        confirmText: 'View Messages',
                        url: (data) => '/index.php?_route=admin_messages/list',
                        notificationTitle: (data) => 'New Admin Message',
                        notificationBody: (data) => data.latest_message ? data.latest_message.title : 'New message',
                        pendingCheck: false // Admin messages don't need reminder
                    });
                    
                    // Start monitoring
                    setTimeout(function() {
                        console.log('Starting notification monitoring...');
                        
                        // Initial checks
                        rechargeChecker.checkNew();
                        messageChecker.checkNew();
                        
                        // Regular checks every 60 seconds
                        setInterval(rechargeChecker.checkNew, 60000);
                        setInterval(messageChecker.checkNew, 60000);
                        
                        // Pending reminders every 5 minutes
                        setInterval(rechargeChecker.checkPending, 300000);
                        setTimeout(rechargeChecker.checkPending, 300000);
                    }, 5000);
                    
                    // Add test buttons to navbar
                    setTimeout(function() {
                        var navMenu = document.querySelector('.navbar-custom-menu .nav.navbar-nav');
                        if (navMenu) {
                            var testButtons = document.createElement('li');
                            testButtons.className = 'dropdown';
                            testButtons.innerHTML = '<a href="#" class="dropdown-toggle" data-toggle="dropdown" title="Test Notification Sounds" style="padding: 15px 10px;"><i class="fa fa-volume-up"></i></a>' +
                                '<ul class="dropdown-menu"><li><a href="#" onclick="window.testRechargeNotificationSound(); return false;">Recharge Sound</a></li>' +
                                '<li><a href="#" onclick="window.testMessageNotificationSound(); return false;">Message Sound</a></li></ul>';
                            navMenu.insertBefore(testButtons, navMenu.firstChild);
                            console.log('Test button added to navbar');
                        }
                    }, 1000);
                })();
                </script>
