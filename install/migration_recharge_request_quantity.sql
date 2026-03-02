-- Migration: Add Quantity Support to Recharge Requests
-- Date: 2026-03-02
-- Description: Adds quantity field to recharge request system

-- Add quantity column to tbl_recharge_requests
ALTER TABLE `tbl_recharge_requests` 
ADD COLUMN `quantity` INT(11) NOT NULL DEFAULT 1 AFTER `plan_name`;

-- Add index for better performance on quantity queries
CREATE INDEX `idx_quantity` ON `tbl_recharge_requests` (`quantity`);
