
-- Create members table
CREATE TABLE public.members (
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
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view members" ON public.members FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert members" ON public.members FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update members" ON public.members FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete members" ON public.members FOR DELETE TO authenticated USING (true);

-- Create monthly_payments table
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
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(member_id, month, year)
);

ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view payments" ON public.monthly_payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert payments" ON public.monthly_payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update payments" ON public.monthly_payments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete payments" ON public.monthly_payments FOR DELETE TO authenticated USING (true);

-- Create expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL DEFAULT 0,
  category TEXT,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view expenses" ON public.expenses FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert expenses" ON public.expenses FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update expenses" ON public.expenses FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete expenses" ON public.expenses FOR DELETE TO authenticated USING (true);

-- Create extraordinary_fees table
CREATE TABLE public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  amount_per_member NUMERIC NOT NULL DEFAULT 0,
  due_date DATE,
  is_mandatory BOOLEAN DEFAULT true,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view extraordinary_fees" ON public.extraordinary_fees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert extraordinary_fees" ON public.extraordinary_fees FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update extraordinary_fees" ON public.extraordinary_fees FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete extraordinary_fees" ON public.extraordinary_fees FOR DELETE TO authenticated USING (true);

-- Create extraordinary_payments table
CREATE TABLE public.extraordinary_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  extraordinary_fee_id UUID NOT NULL REFERENCES public.extraordinary_fees(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  amount_paid NUMERIC NOT NULL DEFAULT 0,
  payment_date DATE,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view extraordinary_payments" ON public.extraordinary_payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert extraordinary_payments" ON public.extraordinary_payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update extraordinary_payments" ON public.extraordinary_payments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete extraordinary_payments" ON public.extraordinary_payments FOR DELETE TO authenticated USING (true);

-- Create settings table
CREATE TABLE public.settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  institution_name TEXT DEFAULT 'Logia',
  monthly_fee_base NUMERIC DEFAULT 50,
  monthly_report_template TEXT DEFAULT 'Este informe presenta el resumen financiero correspondiente al período indicado.',
  annual_report_template TEXT DEFAULT 'Este informe presenta el resumen financiero anual consolidado.',
  logo_url TEXT,
  treasurer_id UUID REFERENCES public.members(id),
  treasurer_signature_url TEXT,
  vm_signature_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view settings" ON public.settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert settings" ON public.settings FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update settings" ON public.settings FOR UPDATE TO authenticated USING (true);

-- Create degree_fees table
CREATE TABLE public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID REFERENCES public.members(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL DEFAULT 0,
  fee_date DATE NOT NULL DEFAULT CURRENT_DATE,
  degree TEXT,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view degree_fees" ON public.degree_fees FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated users can insert degree_fees" ON public.degree_fees FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update degree_fees" ON public.degree_fees FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Authenticated users can delete degree_fees" ON public.degree_fees FOR DELETE TO authenticated USING (true);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('logos', 'logos', true);
INSERT INTO storage.buckets (id, name, public) VALUES ('signatures', 'signatures', true);

-- Storage policies for receipts
CREATE POLICY "Authenticated users can upload receipts" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'receipts');
CREATE POLICY "Anyone can view receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated users can update receipts" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated users can delete receipts" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'receipts');

-- Storage policies for logos
CREATE POLICY "Authenticated users can upload logos" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'logos');
CREATE POLICY "Anyone can view logos" ON storage.objects FOR SELECT USING (bucket_id = 'logos');
CREATE POLICY "Authenticated users can update logos" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'logos');
CREATE POLICY "Authenticated users can delete logos" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'logos');

-- Storage policies for signatures
CREATE POLICY "Authenticated users can upload signatures" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'signatures');
CREATE POLICY "Anyone can view signatures" ON storage.objects FOR SELECT USING (bucket_id = 'signatures');
CREATE POLICY "Authenticated users can update signatures" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'signatures');
CREATE POLICY "Authenticated users can delete signatures" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'signatures');

-- Indexes for performance
CREATE INDEX idx_monthly_payments_member ON public.monthly_payments(member_id);
CREATE INDEX idx_monthly_payments_month_year ON public.monthly_payments(month, year);
CREATE INDEX idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX idx_extraordinary_payments_fee ON public.extraordinary_payments(extraordinary_fee_id);
CREATE INDEX idx_extraordinary_payments_member ON public.extraordinary_payments(member_id);
CREATE INDEX idx_degree_fees_member ON public.degree_fees(member_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_monthly_payments_updated_at BEFORE UPDATE ON public.monthly_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_extraordinary_fees_updated_at BEFORE UPDATE ON public.extraordinary_fees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_extraordinary_payments_updated_at BEFORE UPDATE ON public.extraordinary_payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_degree_fees_updated_at BEFORE UPDATE ON public.degree_fees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
