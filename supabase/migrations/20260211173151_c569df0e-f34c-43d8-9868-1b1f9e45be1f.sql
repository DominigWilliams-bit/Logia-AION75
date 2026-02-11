
-- Members table
CREATE TABLE public.members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  degree TEXT NULL,
  phone TEXT NULL,
  email TEXT NULL,
  status TEXT NULL DEFAULT 'activo',
  treasury_amount NUMERIC NULL DEFAULT 0,
  is_treasurer BOOLEAN NULL DEFAULT false,
  cedula TEXT NULL,
  address TEXT NULL,
  join_date DATE NULL,
  birth_date DATE NULL,
  cargo_logial TEXT NULL,
  emergency_contact_name TEXT NULL,
  emergency_contact_phone TEXT NULL,
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
  status TEXT NULL DEFAULT 'pendiente',
  paid_at TIMESTAMPTZ NULL,
  payment_type TEXT NULL,
  notes TEXT NULL,
  receipt_url TEXT NULL,
  quick_pay_group_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Extraordinary fees table
CREATE TABLE public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NULL,
  amount_per_member NUMERIC NOT NULL DEFAULT 0,
  due_date DATE NULL,
  is_mandatory BOOLEAN NULL DEFAULT true,
  category TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Extraordinary payments table
CREATE TABLE public.extraordinary_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  extraordinary_fee_id UUID NOT NULL REFERENCES public.extraordinary_fees(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  amount_paid NUMERIC NOT NULL DEFAULT 0,
  payment_date DATE NULL,
  receipt_url TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT NULL,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT NULL,
  receipt_url TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Degree fees table
CREATE TABLE public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'grado',
  fee_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT NULL,
  receipt_url TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Settings table
CREATE TABLE public.settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  institution_name TEXT NULL,
  logo_url TEXT NULL,
  monthly_fee_base NUMERIC NULL DEFAULT 50,
  treasurer_id TEXT NULL,
  treasurer_signature_url TEXT NULL,
  vm_signature_url TEXT NULL,
  monthly_report_template TEXT NULL,
  annual_report_template TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Receipt counter table
CREATE TABLE public.receipt_counter (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL,
  last_number INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Function to get next receipt number
CREATE OR REPLACE FUNCTION public.get_next_receipt_number(p_module TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_next INTEGER;
BEGIN
  INSERT INTO public.receipt_counter (category, last_number)
  VALUES (p_module, 1)
  ON CONFLICT (category) DO UPDATE SET last_number = receipt_counter.last_number + 1
  RETURNING last_number INTO v_next;
  RETURN LPAD(v_next::TEXT, 6, '0');
END;
$$;

-- Add unique constraint on receipt_counter category
ALTER TABLE public.receipt_counter ADD CONSTRAINT receipt_counter_category_key UNIQUE (category);

-- Update timestamp function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_monthly_payments_updated_at BEFORE UPDATE ON public.monthly_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Enable RLS on all tables
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_counter ENABLE ROW LEVEL SECURITY;

-- RLS policies - allow all authenticated users full access (lodge management app)
CREATE POLICY "Allow all access" ON public.members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.monthly_payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.extraordinary_fees FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.extraordinary_payments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.expenses FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.degree_fees FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.settings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access" ON public.receipt_counter FOR ALL USING (true) WITH CHECK (true);
