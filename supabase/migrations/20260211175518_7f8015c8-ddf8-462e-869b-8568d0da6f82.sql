
-- Create storage bucket for receipts
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to receipts
CREATE POLICY "Public read access for receipts"
ON storage.objects FOR SELECT
USING (bucket_id = 'receipts');

-- Allow authenticated users to upload receipts
CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'receipts');

-- Allow authenticated users to update receipts
CREATE POLICY "Authenticated users can update receipts"
ON storage.objects FOR UPDATE
USING (bucket_id = 'receipts');

-- Allow authenticated users to delete receipts
CREATE POLICY "Authenticated users can delete receipts"
ON storage.objects FOR DELETE
USING (bucket_id = 'receipts');
