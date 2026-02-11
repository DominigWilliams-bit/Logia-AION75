
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
  status TEXT DEFAULT 'paid',
  receipt_url TEXT,
  payment_type TEXT DEFAULT 'regular',
  quick_pay_group_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT DEFAULT 'otros',
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
  category TEXT DEFAULT 'otro',
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
  fee_date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT NOT NULL DEFAULT 'iniciacion',
  receipt_url TEXT,
  notes TEXT,
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

-- Receipt counter table for receipt number generation
CREATE TABLE public.receipt_counter (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category TEXT NOT NULL UNIQUE,
  last_number INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_counter ENABLE ROW LEVEL SECURITY;

-- RLS Policies: authenticated users can do everything (this is an internal admin app)
CREATE POLICY "Authenticated users full access" ON public.members FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.monthly_payments FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.expenses FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.extraordinary_fees FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.extraordinary_payments FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.degree_fees FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.settings FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users full access" ON public.receipt_counter FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- Storage bucket for receipts
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Authenticated users can upload receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated users can update receipts" ON storage.objects FOR UPDATE USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete receipts" ON storage.objects FOR DELETE USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_monthly_payments_updated_at BEFORE UPDATE ON public.monthly_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_monthly_payments_member ON public.monthly_payments(member_id);
CREATE INDEX idx_monthly_payments_year_month ON public.monthly_payments(year, month);
CREATE INDEX idx_extraordinary_payments_fee ON public.extraordinary_payments(extraordinary_fee_id);
CREATE INDEX idx_extraordinary_payments_member ON public.extraordinary_payments(member_id);
CREATE INDEX idx_expenses_date ON public.expenses(expense_date);
