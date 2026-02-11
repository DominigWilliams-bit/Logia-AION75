
-- 1. Members table
CREATE TABLE IF NOT EXISTS public.members (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  full_name TEXT NOT NULL,
  degree TEXT DEFAULT 'aprendiz',
  status TEXT DEFAULT 'activo',
  is_treasurer BOOLEAN DEFAULT false,
  treasury_amount NUMERIC DEFAULT 0,
  cargo_logial TEXT,
  email TEXT,
  phone TEXT,
  cedula TEXT,
  address TEXT,
  join_date DATE,
  birth_date DATE,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read members" ON public.members FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert members" ON public.members FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update members" ON public.members FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete members" ON public.members FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_members_status ON public.members(status);
CREATE INDEX idx_members_full_name ON public.members(full_name);

-- 2. Settings table
CREATE TABLE IF NOT EXISTS public.settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  institution_name TEXT DEFAULT 'Logia',
  monthly_fee_base NUMERIC DEFAULT 50,
  monthly_report_template TEXT,
  annual_report_template TEXT,
  logo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read settings" ON public.settings FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert settings" ON public.settings FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update settings" ON public.settings FOR UPDATE USING (auth.role() = 'authenticated');

-- Insert default settings row
INSERT INTO public.settings (institution_name, monthly_fee_base) VALUES ('Logia', 50);

-- 3. Monthly payments table
CREATE TABLE IF NOT EXISTS public.monthly_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  paid_at TIMESTAMPTZ,
  status TEXT DEFAULT 'paid',
  receipt_url TEXT,
  payment_type TEXT DEFAULT 'regular',
  quick_pay_group_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read monthly_payments" ON public.monthly_payments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert monthly_payments" ON public.monthly_payments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update monthly_payments" ON public.monthly_payments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete monthly_payments" ON public.monthly_payments FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_monthly_payments_member_id ON public.monthly_payments(member_id);
CREATE INDEX idx_monthly_payments_year ON public.monthly_payments(year);
CREATE INDEX idx_monthly_payments_month ON public.monthly_payments(month);
CREATE INDEX idx_monthly_payments_created_at ON public.monthly_payments(created_at);
CREATE UNIQUE INDEX idx_monthly_payments_unique ON public.monthly_payments(member_id, month, year);

-- 4. Expenses table
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read expenses" ON public.expenses FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert expenses" ON public.expenses FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update expenses" ON public.expenses FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete expenses" ON public.expenses FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_expenses_expense_date ON public.expenses(expense_date);
CREATE INDEX idx_expenses_created_at ON public.expenses(created_at);

-- 5. Extraordinary fees table
CREATE TABLE IF NOT EXISTS public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  amount_per_member NUMERIC NOT NULL DEFAULT 0,
  due_date DATE,
  is_mandatory BOOLEAN DEFAULT true,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read extraordinary_fees" ON public.extraordinary_fees FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert extraordinary_fees" ON public.extraordinary_fees FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update extraordinary_fees" ON public.extraordinary_fees FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete extraordinary_fees" ON public.extraordinary_fees FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_extraordinary_fees_created_at ON public.extraordinary_fees(created_at);

-- 6. Extraordinary payments table
CREATE TABLE IF NOT EXISTS public.extraordinary_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  extraordinary_fee_id UUID NOT NULL REFERENCES public.extraordinary_fees(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  amount_paid NUMERIC NOT NULL DEFAULT 0,
  payment_date DATE,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read extraordinary_payments" ON public.extraordinary_payments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert extraordinary_payments" ON public.extraordinary_payments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update extraordinary_payments" ON public.extraordinary_payments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete extraordinary_payments" ON public.extraordinary_payments FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_extraordinary_payments_member_id ON public.extraordinary_payments(member_id);
CREATE INDEX idx_extraordinary_payments_fee_id ON public.extraordinary_payments(extraordinary_fee_id);

-- 7. Degree fees table (with member_id field)
CREATE TABLE IF NOT EXISTS public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID REFERENCES public.members(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  fee_date DATE NOT NULL DEFAULT CURRENT_DATE,
  receipt_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read degree_fees" ON public.degree_fees FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can insert degree_fees" ON public.degree_fees FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update degree_fees" ON public.degree_fees FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete degree_fees" ON public.degree_fees FOR DELETE USING (auth.role() = 'authenticated');

CREATE INDEX idx_degree_fees_member_id ON public.degree_fees(member_id);
CREATE INDEX idx_degree_fees_fee_date ON public.degree_fees(fee_date);
CREATE INDEX idx_degree_fees_created_at ON public.degree_fees(created_at);

-- 8. Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('logos', 'logos', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies for logos
CREATE POLICY "Anyone can view logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
CREATE POLICY "Authenticated users can upload logos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update logos" ON storage.objects FOR UPDATE USING (bucket_id = 'logos' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete logos" ON storage.objects FOR DELETE USING (bucket_id = 'logos' AND auth.role() = 'authenticated');

-- Storage policies for receipts
CREATE POLICY "Anyone can view receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated users can upload receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update receipts" ON storage.objects FOR UPDATE USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can delete receipts" ON storage.objects FOR DELETE USING (bucket_id = 'receipts' AND auth.role() = 'authenticated');

-- Trigger for updated_at on members
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_monthly_payments_updated_at BEFORE UPDATE ON public.monthly_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
