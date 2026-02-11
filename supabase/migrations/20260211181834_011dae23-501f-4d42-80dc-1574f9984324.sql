
-- Performance indexes for scalability to 10,000+ records
CREATE INDEX IF NOT EXISTS idx_monthly_payments_member_id ON public.monthly_payments(member_id);
CREATE INDEX IF NOT EXISTS idx_monthly_payments_year_month ON public.monthly_payments(year, month);
CREATE INDEX IF NOT EXISTS idx_monthly_payments_status ON public.monthly_payments(status);
CREATE INDEX IF NOT EXISTS idx_monthly_payments_paid_at ON public.monthly_payments(paid_at);
CREATE INDEX IF NOT EXISTS idx_monthly_payments_payment_type ON public.monthly_payments(payment_type);

CREATE INDEX IF NOT EXISTS idx_extraordinary_payments_member_id ON public.extraordinary_payments(member_id);
CREATE INDEX IF NOT EXISTS idx_extraordinary_payments_fee_id ON public.extraordinary_payments(extraordinary_fee_id);
CREATE INDEX IF NOT EXISTS idx_extraordinary_payments_date ON public.extraordinary_payments(payment_date);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);

CREATE INDEX IF NOT EXISTS idx_degree_fees_date ON public.degree_fees(fee_date);
CREATE INDEX IF NOT EXISTS idx_degree_fees_category ON public.degree_fees(category);

CREATE INDEX IF NOT EXISTS idx_members_status ON public.members(status);
CREATE INDEX IF NOT EXISTS idx_members_full_name ON public.members(full_name);
CREATE INDEX IF NOT EXISTS idx_members_degree ON public.members(degree);
