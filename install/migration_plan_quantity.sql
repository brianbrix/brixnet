-- Migration: Plan Quantity Feature
-- Purpose: Allow customers to purchase multiple units of the same plan
-- Benefits are multiplied (time, data, etc.)

-- Add quantity column to tbl_payment_gateway
ALTER TABLE `tbl_payment_gateway` 
ADD COLUMN `quantity` int(11) DEFAULT 1 
AFTER `price`;

-- Add quantity column to tbl_transactions for tracking
ALTER TABLE `tbl_transactions` 
ADD COLUMN `quantity` int(11) DEFAULT 1 
AFTER `price`;

-- Create index for reporting purposes
CREATE INDEX `idx_quantity` ON `tbl_payment_gateway` (`quantity`);
CREATE INDEX `idx_quantity_trans` ON `tbl_transactions` (`quantity`);

-- Update existing records to have default quantity of 1
UPDATE `tbl_payment_gateway` SET `quantity` = 1 WHERE `quantity` IS NULL;
UPDATE `tbl_transactions` SET `quantity` = 1 WHERE `quantity` IS NULL;
