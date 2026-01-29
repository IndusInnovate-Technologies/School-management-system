-- Add grade column to students table if it doesn't exist
ALTER TABLE students ADD COLUMN IF NOT EXISTS grade VARCHAR(50) NULL;
