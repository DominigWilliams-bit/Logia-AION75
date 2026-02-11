
-- Create RPC function for receipt numbering
CREATE OR REPLACE FUNCTION public.get_next_receipt_number(p_module TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next INTEGER;
  v_prefix TEXT;
BEGIN
  -- Determine prefix
  CASE p_module
    WHEN 'treasury' THEN v_prefix := 'TSR';
    WHEN 'extraordinary' THEN v_prefix := 'EXT';
    WHEN 'degree' THEN v_prefix := 'GRD';
    ELSE v_prefix := 'REC';
  END CASE;

  -- Upsert and increment
  INSERT INTO receipt_counters (counter_type, last_number, updated_at)
  VALUES (p_module, 1, now())
  ON CONFLICT (counter_type)
  DO UPDATE SET last_number = receipt_counters.last_number + 1, updated_at = now()
  RETURNING last_number INTO v_next;

  RETURN v_prefix || '-' || LPAD(v_next::TEXT, 6, '0');
END;
$$;
