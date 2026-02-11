
-- Members table
CREATE TABLE public.members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  degree TEXT DEFAULT 'aprendiz',
  phone TEXT,
  email TEXT,
  status TEXT DEFAULT 'activo',
  treasury_amount NUMERIC DEFAULT 0,
  is_treasurer BOOLEAN DEFAULT false,
  cedula TEXT,
  address TEXT,
  join_date DATE,
  birth_date DATE,
  cargo_logial TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Monthly payments table
CREATE TABLE public.monthly_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  paid_at DATE,
  status TEXT,
  receipt_url TEXT,
  payment_type TEXT DEFAULT 'regular',
  quick_pay_group_id TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(member_id, month, year)
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Extraordinary fees table
CREATE TABLE public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  amount_per_member NUMERIC NOT NULL DEFAULT 0,
  due_date DATE,
  is_mandatory BOOLEAN DEFAULT true,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Extraordinary payments table
CREATE TABLE public.extraordinary_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  extraordinary_fee_id UUID NOT NULL REFERENCES public.extraordinary_fees(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  amount_paid NUMERIC NOT NULL DEFAULT 0,
  payment_date DATE,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Degree fees table
CREATE TABLE public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'iniciacion',
  fee_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Receipt counter table
CREATE TABLE public.receipt_counter (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL UNIQUE,
  last_number INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Settings table
CREATE TABLE public.settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  institution_name TEXT DEFAULT 'Logia',
  monthly_fee_base NUMERIC DEFAULT 50,
  monthly_report_template TEXT,
  annual_report_template TEXT,
  logo_url TEXT,
  treasurer_id UUID,
  treasurer_signature_url TEXT,
  vm_signature_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_counter ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- RLS policies: authenticated users can do everything (this is a single-org app)
CREATE POLICY "Authenticated users full access" ON public.members FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.monthly_payments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.extraordinary_fees FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.extraordinary_payments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.degree_fees FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.receipt_counter FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Authenticated users full access" ON public.settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Receipt number function
CREATE OR REPLACE FUNCTION public.get_next_receipt_number(p_module TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prefix TEXT;
  v_next INTEGER;
  v_year TEXT;
BEGIN
  CASE p_module
    WHEN 'treasury' THEN v_prefix := 'TSR';
    WHEN 'extraordinary' THEN v_prefix := 'EXT';
    WHEN 'degree' THEN v_prefix := 'GRD';
    ELSE v_prefix := 'REC';
  END CASE;

  v_year := TO_CHAR(NOW(), 'YYYY');

  INSERT INTO public.receipt_counter (category, last_number)
  VALUES (p_module, 1)
  ON CONFLICT (category)
  DO UPDATE SET last_number = receipt_counter.last_number + 1
  RETURNING last_number INTO v_next;

  RETURN v_prefix || '-' || v_year || '-' || LPAD(v_next::TEXT, 5, '0');
END;
$$;

-- Storage bucket for receipts
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true) ON CONFLICT DO NOTHING;

-- Storage policies
CREATE POLICY "Authenticated users can upload receipts"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'receipts');

CREATE POLICY "Authenticated users can update receipts"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'receipts');

CREATE POLICY "Anyone can view receipts"
ON storage.objects FOR SELECT
USING (bucket_id = 'receipts');

-- Initial receipt counter rows
INSERT INTO public.receipt_counter (category, last_number) VALUES ('treasury', 0), ('extraordinary', 0), ('degree', 0);

-- Initial settings row
INSERT INTO public.settings (institution_name, monthly_fee_base) VALUES ('Logia', 50);
