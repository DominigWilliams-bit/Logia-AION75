
-- Add category column to degree_fees if not exists
ALTER TABLE public.degree_fees ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'iniciacion';
