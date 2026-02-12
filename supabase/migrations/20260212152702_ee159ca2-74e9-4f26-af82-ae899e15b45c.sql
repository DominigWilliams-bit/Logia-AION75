-- Create the get_next_receipt_number function
CREATE OR REPLACE FUNCTION public.get_next_receipt_number(p_module text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  prefix text;
  next_num integer;
  result text;
BEGIN
  CASE p_module
    WHEN 'treasury' THEN prefix := 'TSR';
    WHEN 'extraordinary' THEN prefix := 'EXT';
    WHEN 'degree' THEN prefix := 'GRD';
    ELSE prefix := 'REC';
  END CASE;

  -- Get the current max number for this prefix from a simple counter approach
  -- Use timestamp-based sequential numbering
  next_num := (EXTRACT(EPOCH FROM now()) * 1000)::bigint % 10000000;
  
  result := prefix || '-' || LPAD(next_num::text, 7, '0');
  RETURN result;
END;
$$;