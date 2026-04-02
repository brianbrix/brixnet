<?php

class SessionTracker
{
    private static $tableReady = false;

    private static function ensureTable()
    {
        if (self::$tableReady) return;
        ORM::raw_execute("CREATE TABLE IF NOT EXISTS `tbl_login_sessions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT NOT NULL DEFAULT 0,
            `user_type` VARCHAR(20) NOT NULL DEFAULT 'Customer',
            `username` VARCHAR(100) NOT NULL,
            `fullname` VARCHAR(150) DEFAULT '',
            `ip` VARCHAR(45) NOT NULL,
            `user_agent` TEXT,
            `login_time` DATETIME NOT NULL,
            `last_seen` DATETIME NOT NULL,
            `token_hash` VARCHAR(64) DEFAULT NULL,
            `revoked` TINYINT(1) NOT NULL DEFAULT 0,
            INDEX `idx_token` (`token_hash`),
            INDEX `idx_user` (`user_id`, `user_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Migration: add revoked column if table existed before this feature
        try {
            ORM::raw_execute("ALTER TABLE `tbl_login_sessions` ADD COLUMN `revoked` TINYINT(1) NOT NULL DEFAULT 0");
        } catch (Exception $e) {
            // Column already exists — ignore
        }
        self::$tableReady = true;
    }

    public static function record($userId, $userType, $username, $fullname, $tokenHash = null)
    {
        self::ensureTable();
        $ip = $_SERVER['REMOTE_ADDR'] ?? '';
        $ua = $_SERVER['HTTP_USER_AGENT'] ?? '';
        $now = date('Y-m-d H:i:s');

        // If token exists, update the existing session row
        if ($tokenHash) {
            $existing = ORM::for_table('tbl_login_sessions')
                ->where('token_hash', $tokenHash)
                ->find_one();
            if ($existing) {
                $existing->last_seen = $now;
                $existing->save();
                return;
            }
        }

        $s = ORM::for_table('tbl_login_sessions')->create();
        $s->user_id    = $userId;
        $s->user_type  = $userType;
        $s->username   = $username;
        $s->fullname   = $fullname ?: $username;
        $s->ip         = $ip;
        $s->user_agent = $ua;
        $s->login_time = $now;
        $s->last_seen  = $now;
        $s->token_hash = $tokenHash;
        $s->save();
    }

    public static function touch($tokenHash)
    {
        if (empty($tokenHash)) return;
        self::ensureTable();
        $s = ORM::for_table('tbl_login_sessions')
            ->where('token_hash', $tokenHash)
            ->find_one();
        if ($s) {
            $s->last_seen = date('Y-m-d H:i:s');
            $s->save();
        }
    }

    public static function clear($tokenHash)
    {
        if (empty($tokenHash)) return;
        self::ensureTable();
        $s = ORM::for_table('tbl_login_sessions')
            ->where('token_hash', $tokenHash)
            ->find_one();
        if ($s) $s->delete();
    }

    public static function forceLogout($tokenHash)
    {
        if (empty($tokenHash)) return;
        self::ensureTable();
        $s = ORM::for_table('tbl_login_sessions')
            ->where('token_hash', $tokenHash)
            ->find_one();
        if ($s) {
            $s->revoked    = 1;
            $s->last_seen  = date('Y-m-d H:i:s');
            $s->save();
        } else {
            // Token was never recorded — insert a revocation marker
            $s = ORM::for_table('tbl_login_sessions')->create();
            $s->user_id    = 0;
            $s->user_type  = 'Unknown';
            $s->username   = '';
            $s->fullname   = '';
            $s->ip         = '';
            $s->user_agent = '';
            $s->login_time = date('Y-m-d H:i:s');
            $s->last_seen  = date('Y-m-d H:i:s');
            $s->token_hash = $tokenHash;
            $s->revoked    = 1;
            $s->save();
        }
    }

    public static function isRevoked($tokenHash)
    {
        if (empty($tokenHash)) return false;
        self::ensureTable();
        $s = ORM::for_table('tbl_login_sessions')
            ->where('token_hash', $tokenHash)
            ->where('revoked', 1)
            ->find_one();
        return !empty($s);
    }

    public static function clearByUser($userId, $userType)
    {
        self::ensureTable();
        ORM::raw_execute(
            "DELETE FROM tbl_login_sessions WHERE user_id = :uid AND user_type = :utype",
            [':uid' => $userId, ':utype' => $userType]
        );
    }

    public static function getActive($staleMinutes = 30)
    {
        self::ensureTable();
        return ORM::for_table('tbl_login_sessions')
            ->where('revoked', 0)
            ->where_raw("last_seen >= DATE_SUB(NOW(), INTERVAL $staleMinutes MINUTE)")
            ->order_by_desc('last_seen')
            ->find_array();
    }

    public static function pruneStale($staleMinutes = 60)
    {
        self::ensureTable();
        // Delete non-revoked stale sessions
        ORM::raw_execute(
            "DELETE FROM tbl_login_sessions WHERE revoked = 0 AND last_seen < DATE_SUB(NOW(), INTERVAL :mins MINUTE)",
            [':mins' => $staleMinutes]
        );
        // Delete revoked sessions older than 7 days
        ORM::raw_execute(
            "DELETE FROM tbl_login_sessions WHERE revoked = 1 AND last_seen < DATE_SUB(NOW(), INTERVAL 7 DAY)"
        );
    }

    public static function parseDevice($userAgent)
    {
        if (empty($userAgent)) return ['browser' => 'Unknown', 'os' => 'Unknown', 'icon' => 'fa-question-circle'];

        $ua = strtolower($userAgent);

        // OS detection
        if (strpos($ua, 'windows') !== false) $os = 'Windows';
        elseif (strpos($ua, 'android') !== false) $os = 'Android';
        elseif (strpos($ua, 'iphone') !== false || strpos($ua, 'ipad') !== false) $os = 'iOS';
        elseif (strpos($ua, 'mac') !== false) $os = 'macOS';
        elseif (strpos($ua, 'linux') !== false) $os = 'Linux';
        else $os = 'Unknown';

        // Browser detection
        if (strpos($ua, 'edg/') !== false) $browser = 'Edge';
        elseif (strpos($ua, 'opr/') !== false || strpos($ua, 'opera') !== false) $browser = 'Opera';
        elseif (strpos($ua, 'chrome') !== false) $browser = 'Chrome';
        elseif (strpos($ua, 'firefox') !== false) $browser = 'Firefox';
        elseif (strpos($ua, 'safari') !== false) $browser = 'Safari';
        elseif (strpos($ua, 'curl') !== false || strpos($ua, 'python') !== false || strpos($ua, 'okhttp') !== false) $browser = 'API Client';
        else $browser = 'Unknown';

        // Icon
        if (strpos($ua, 'mobile') !== false || strpos($ua, 'android') !== false || strpos($ua, 'iphone') !== false)
            $icon = 'fa-mobile';
        elseif (strpos($ua, 'ipad') !== false || strpos($ua, 'tablet') !== false)
            $icon = 'fa-tablet';
        else
            $icon = 'fa-desktop';

        return ['browser' => $browser, 'os' => $os, 'icon' => $icon];
    }
}
