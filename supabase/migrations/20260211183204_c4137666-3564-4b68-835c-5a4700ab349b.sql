
-- Settings table
CREATE TABLE public.settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  institution_name TEXT DEFAULT 'R∴L∴S∴ Ejemplo No. 1',
  monthly_fee_base NUMERIC DEFAULT 50,
  monthly_report_template TEXT,
  annual_report_template TEXT,
  logo_url TEXT,
  treasurer_id UUID,
  treasurer_signature_url TEXT,
  vm_signature_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Settings readable by authenticated" ON public.settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Settings updatable by authenticated" ON public.settings FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Settings insertable by authenticated" ON public.settings FOR INSERT TO authenticated WITH CHECK (true);

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
  join_date TEXT,
  birth_date TEXT,
  cargo_logial TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members readable by authenticated" ON public.members FOR SELECT TO authenticated USING (true);
CREATE POLICY "Members insertable by authenticated" ON public.members FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Members updatable by authenticated" ON public.members FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Members deletable by authenticated" ON public.members FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_members_status ON public.members(status);
CREATE INDEX idx_members_full_name ON public.members(full_name);

-- Monthly payments table
CREATE TABLE public.monthly_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  paid_at TEXT,
  status TEXT,
  receipt_url TEXT,
  payment_type TEXT DEFAULT 'regular',
  quick_pay_group_id TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(member_id, month, year)
);
ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Monthly payments readable by authenticated" ON public.monthly_payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Monthly payments insertable by authenticated" ON public.monthly_payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Monthly payments updatable by authenticated" ON public.monthly_payments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Monthly payments deletable by authenticated" ON public.monthly_payments FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_monthly_payments_member ON public.monthly_payments(member_id);
CREATE INDEX idx_monthly_payments_month_year ON public.monthly_payments(month, year);
CREATE INDEX idx_monthly_payments_type ON public.monthly_payments(payment_type);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT,
  expense_date TEXT NOT NULL,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Expenses readable by authenticated" ON public.expenses FOR SELECT TO authenticated USING (true);
CREATE POLICY "Expenses insertable by authenticated" ON public.expenses FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Expenses updatable by authenticated" ON public.expenses FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Expenses deletable by authenticated" ON public.expenses FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX idx_expenses_category ON public.expenses(category);

-- Extraordinary fees table
CREATE TABLE public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  amount_per_member NUMERIC NOT NULL,
  due_date TEXT,
  is_mandatory BOOLEAN DEFAULT true,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Extraordinary fees readable by authenticated" ON public.extraordinary_fees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Extraordinary fees insertable by authenticated" ON public.extraordinary_fees FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Extraordinary fees updatable by authenticated" ON public.extraordinary_fees FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Extraordinary fees deletable by authenticated" ON public.extraordinary_fees FOR DELETE TO authenticated USING (true);

-- Extraordinary payments table
CREATE TABLE public.extraordinary_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  extraordinary_fee_id UUID NOT NULL REFERENCES public.extraordinary_fees(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  amount_paid NUMERIC NOT NULL,
  payment_date TEXT,
  receipt_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Extraordinary payments readable by authenticated" ON public.extraordinary_payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Extraordinary payments insertable by authenticated" ON public.extraordinary_payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Extraordinary payments updatable by authenticated" ON public.extraordinary_payments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Extraordinary payments deletable by authenticated" ON public.extraordinary_payments FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_extraordinary_payments_fee ON public.extraordinary_payments(extraordinary_fee_id);
CREATE INDEX idx_extraordinary_payments_member ON public.extraordinary_payments(member_id);

-- Degree fees table
CREATE TABLE public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  fee_date TEXT NOT NULL,
  category TEXT NOT NULL,
  receipt_url TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Degree fees readable by authenticated" ON public.degree_fees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Degree fees insertable by authenticated" ON public.degree_fees FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Degree fees updatable by authenticated" ON public.degree_fees FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Degree fees deletable by authenticated" ON public.degree_fees FOR DELETE TO authenticated USING (true);

CREATE INDEX idx_degree_fees_date ON public.degree_fees(fee_date);
CREATE INDEX idx_degree_fees_category ON public.degree_fees(category);

-- Receipt counter table for sequential receipt numbers
CREATE TABLE public.receipt_counters (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  counter_type TEXT NOT NULL UNIQUE,
  last_number INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
ALTER TABLE public.receipt_counters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Receipt counters readable by authenticated" ON public.receipt_counters FOR SELECT TO authenticated USING (true);
CREATE POLICY "Receipt counters insertable by authenticated" ON public.receipt_counters FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Receipt counters updatable by authenticated" ON public.receipt_counters FOR UPDATE TO authenticated USING (true);

-- Storage bucket for receipts
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true);
CREATE POLICY "Receipts publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated can upload receipts" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'receipts');
CREATE POLICY "Authenticated can update receipts" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'receipts');

-- Initial settings row
INSERT INTO public.settings (institution_name, monthly_fee_base) VALUES ('R∴L∴S∴ Ejemplo No. 1', 50);

-- Initial receipt counters
INSERT INTO public.receipt_counters (counter_type, last_number) VALUES ('monthly', 0), ('extraordinary', 0), ('degree', 0);
