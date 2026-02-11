-- Add missing table used by the app: public.degree_fees
-- Fixes runtime errors like:
--   "Could not find the table 'public.degree_fees' in the schema cache"

create table if not exists public.degree_fees (
  id uuid not null default gen_random_uuid() primary key,
  member_id uuid null references public.members(id) on delete set null,
  description text not null,
  amount numeric(10,2) not null,
  category text null,
  fee_date date not null default (now() at time zone 'utc')::date,
  notes text null,
  receipt_url text null,
  created_at timestamp with time zone not null default now()
);

alter table public.degree_fees enable row level security;

-- Keep policies consistent with the rest of the MVP (permissive for authenticated users)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'degree_fees' and policyname = 'Allow authenticated users to read degree_fees'
  ) then
    create policy "Allow authenticated users to read degree_fees"
      on public.degree_fees for select to authenticated
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'degree_fees' and policyname = 'Allow authenticated users to insert degree_fees'
  ) then
    create policy "Allow authenticated users to insert degree_fees"
      on public.degree_fees for insert to authenticated
      with check (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'degree_fees' and policyname = 'Allow authenticated users to update degree_fees'
  ) then
    create policy "Allow authenticated users to update degree_fees"
      on public.degree_fees for update to authenticated
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'degree_fees' and policyname = 'Allow authenticated users to delete degree_fees'
  ) then
    create policy "Allow authenticated users to delete degree_fees"
      on public.degree_fees for delete to authenticated
      using (true);
  end if;
end $$;

-- Storage bucket required by the UI uploads (logo, comprobantes, firmas, etc.)
-- The code uses: supabase.storage.from('receipts')
-- Create it if missing and allow authenticated CRUD.
do $$
begin
  if not exists (select 1 from storage.buckets where id = 'receipts') then
    insert into storage.buckets (id, name, public) values ('receipts', 'receipts', false);
  end if;
end $$;

-- Note: storage.objects already has RLS enabled in Supabase.
-- These policies allow authenticated users to upload/read/delete within the 'receipts' bucket.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Authenticated read receipts bucket'
  ) then
    create policy "Authenticated read receipts bucket"
      on storage.objects for select to authenticated
      using (bucket_id = 'receipts');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Authenticated write receipts bucket'
  ) then
    create policy "Authenticated write receipts bucket"
      on storage.objects for insert to authenticated
      with check (bucket_id = 'receipts');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Authenticated update receipts bucket'
  ) then
    create policy "Authenticated update receipts bucket"
      on storage.objects for update to authenticated
      using (bucket_id = 'receipts');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'Authenticated delete receipts bucket'
  ) then
    create policy "Authenticated delete receipts bucket"
      on storage.objects for delete to authenticated
      using (bucket_id = 'receipts');
  end if;
end $$;
