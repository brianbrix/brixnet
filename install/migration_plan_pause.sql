-- Migration: Plan Pause/Resume Feature
-- Purpose: Allow admins to pause active customer plans without losing settings

-- Add pause columns to tbl_user_recharges
ALTER TABLE `tbl_user_recharges` ADD COLUMN `is_paused` tinyint(1) DEFAULT 0 AFTER `is_archived`;
ALTER TABLE `tbl_user_recharges` ADD COLUMN `paused_on` datetime NULL AFTER `is_paused`;
ALTER TABLE `tbl_user_recharges` ADD COLUMN `paused_by_admin_id` int UNSIGNED DEFAULT NULL AFTER `paused_on`;
ALTER TABLE `tbl_user_recharges` ADD COLUMN `pause_reason` text NULL AFTER `paused_by_admin_id`;

-- Create index for efficient pause lookups
CREATE INDEX `is_paused` ON `tbl_user_recharges` (`is_paused`, `customer_id`);

-- Table: tbl_plan_pause_history
-- Track pause/resume history for audit purposes
CREATE TABLE IF NOT EXISTS `tbl_plan_pause_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `recharge_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `action` enum('pause', 'resume') NOT NULL,
  `admin_id` int UNSIGNED NOT NULL,
  `reason` text,
  `ip_address` varchar(45),
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `notes` text,
  PRIMARY KEY (`id`),
  KEY `recharge_id` (`recharge_id`),
  KEY `customer_id` (`customer_id`),
  KEY `created_date` (`created_date`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `fk_pause_history_recharge` FOREIGN KEY (`recharge_id`) REFERENCES `tbl_user_recharges` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pause_history_customer` FOREIGN KEY (`customer_id`) REFERENCES `tbl_customers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pause_history_admin` FOREIGN KEY (`admin_id`) REFERENCES `tbl_users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Index for efficient lookups
CREATE INDEX `plan_pause_history_idx` ON `tbl_plan_pause_history` (`customer_id`, `recharge_id`, `created_date`);
