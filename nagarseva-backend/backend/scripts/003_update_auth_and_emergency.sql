-- Migration: Remove OTP authentication and update Emergency Services
-- This script updates the database schema to support password-based authentication
-- and enhanced emergency services management

-- Drop OTP table (no longer needed)
DROP TABLE IF EXISTS otps CASCADE;

-- Add missing columns to emergency_services table
ALTER TABLE emergency_services 
ADD COLUMN IF NOT EXISTS email VARCHAR(100);

ALTER TABLE emergency_services 
ADD COLUMN IF NOT EXISTS google_maps_link VARCHAR(500);

ALTER TABLE emergency_services 
ADD COLUMN IF NOT EXISTS category VARCHAR(100);

ALTER TABLE emergency_services 
ADD COLUMN IF NOT EXISTS created_by INTEGER;

ALTER TABLE emergency_services 
ADD COLUMN IF NOT EXISTS is_citywide BOOLEAN DEFAULT FALSE;

-- Add foreign key for created_by if not exists
ALTER TABLE emergency_services
ADD CONSTRAINT fk_emergency_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

-- Make phone optional (was previously required)
ALTER TABLE emergency_services 
ALTER COLUMN phone DROP NOT NULL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_emergency_services_ward_id ON emergency_services(ward_id);
CREATE INDEX IF NOT EXISTS idx_emergency_services_type ON emergency_services(type);
CREATE INDEX IF NOT EXISTS idx_emergency_services_category ON emergency_services(category);
CREATE INDEX IF NOT EXISTS idx_emergency_services_is_active ON emergency_services(is_active);

-- Create index for notice/announcement queries
CREATE INDEX IF NOT EXISTS idx_notifications_ward_id ON notifications(ward_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_expires ON notifications(expires_at);
