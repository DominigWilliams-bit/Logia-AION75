
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
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
  quick_pay_group_id UUID,
  payment_type TEXT DEFAULT 'regular',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(member_id, month, year)
);

-- Expenses table
CREATE TABLE public.expenses (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT DEFAULT 'otros',
  expense_date DATE NOT NULL,
  notes TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Extraordinary fees table
CREATE TABLE public.extraordinary_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  amount_per_member NUMERIC NOT NULL,
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
  amount_paid NUMERIC NOT NULL,
  payment_date DATE,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Degree fees table
CREATE TABLE public.degree_fees (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  fee_date DATE NOT NULL,
  category TEXT DEFAULT 'iniciacion',
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
  treasurer_id UUID REFERENCES public.members(id),
  treasurer_signature_url TEXT,
  vm_signature_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Receipts counter table for receipt numbering
CREATE TABLE public.receipt_counters (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  counter_type TEXT NOT NULL UNIQUE,
  last_number INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraordinary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.degree_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_counters ENABLE ROW LEVEL SECURITY;

-- RLS policies - allow authenticated users full access
CREATE POLICY "Authenticated users can do everything on members" ON public.members FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on monthly_payments" ON public.monthly_payments FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on expenses" ON public.expenses FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on extraordinary_fees" ON public.extraordinary_fees FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on extraordinary_payments" ON public.extraordinary_payments FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on degree_fees" ON public.degree_fees FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on settings" ON public.settings FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can do everything on receipt_counters" ON public.receipt_counters FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Create storage bucket for receipts
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true);

-- Storage policies
CREATE POLICY "Authenticated users can upload receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.uid() IS NOT NULL);
CREATE POLICY "Anyone can view receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts');
CREATE POLICY "Authenticated users can update receipts" ON storage.objects FOR UPDATE USING (bucket_id = 'receipts' AND auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated users can delete receipts" ON storage.objects FOR DELETE USING (bucket_id = 'receipts' AND auth.uid() IS NOT NULL);

-- Indexes for performance
CREATE INDEX idx_monthly_payments_member ON public.monthly_payments(member_id);
CREATE INDEX idx_monthly_payments_year ON public.monthly_payments(year);
CREATE INDEX idx_extraordinary_payments_fee ON public.extraordinary_payments(extraordinary_fee_id);
CREATE INDEX idx_extraordinary_payments_member ON public.extraordinary_payments(member_id);
CREATE INDEX idx_members_status ON public.members(status);

-- Trigger for updated_at on monthly_payments
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER update_monthly_payments_updated_at
  BEFORE UPDATE ON public.monthly_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
