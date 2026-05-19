-- ============================================================
-- RUN ALL (1 FILE) - BANGJUN SPOT (SAFE)
-- Jalankan file ini di Supabase SQL Editor.
--
-- Catatan penting:
-- - File ini TIDAK membuat user auth secara manual.
-- - Buat user lewat Dashboard: Authentication > Users > Add user.
--   Contoh:
--   1) admin@bangjun.id / admin123
--   2) kasir@bangjun.id / kasir123
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- A. SCHEMA
-- ============================================================

create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  role text default 'kasir',
  store_lat double precision,
  store_lng double precision,
  created_at timestamptz default now()
);

alter table profiles add column if not exists store_lat double precision;
alter table profiles add column if not exists store_lng double precision;

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text,
  category text,
  price numeric,
  image_url text,
  min_stock integer default 3,
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table products add column if not exists category text;
alter table products add column if not exists min_stock integer default 3;

create table if not exists cashier_shifts (
  id uuid primary key default gen_random_uuid(),
  cashier_id uuid references profiles(id) on delete cascade,
  opened_at timestamptz default now(),
  closed_at timestamptz,
  opening_cash numeric default 0,
  closing_cash numeric,
  expected_cash numeric default 0,
  cash_difference numeric,
  note text
);

create table if not exists stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  qty integer,
  type text,
  note text,
  created_at timestamptz default now()
);

create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  cashier_id uuid references profiles(id),
  shift_id uuid references cashier_shifts(id),
  total numeric,
  created_at timestamptz default now()
);

alter table transactions add column if not exists shift_id uuid references cashier_shifts(id);

create table if not exists transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references transactions(id) on delete cascade,
  product_id uuid references products(id),
  qty integer,
  price numeric
);

create table if not exists attendance_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  type text not null check (type in ('masuk', 'pulang')),
  lat double precision not null,
  lng double precision not null,
  photo_url text,
  biometric_verified boolean default false,
  distance_km double precision,
  created_at timestamptz default now()
);

alter table if exists profiles enable row level security;
alter table if exists products enable row level security;
alter table if exists cashier_shifts enable row level security;
alter table if exists stock_movements enable row level security;
alter table if exists transactions enable row level security;
alter table if exists transaction_items enable row level security;
alter table if exists attendance_records enable row level security;

create or replace function is_admin()
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- ============================================================
-- B. POLICIES
-- ============================================================

drop policy if exists "profiles read" on profiles;
drop policy if exists "profiles insert" on profiles;
drop policy if exists "profiles update" on profiles;

drop policy if exists "products read" on products;
drop policy if exists "products admin" on products;

drop policy if exists "stock admin" on stock_movements;
drop policy if exists "stock read authenticated" on stock_movements;
drop policy if exists "stock out insert authenticated" on stock_movements;

drop policy if exists "shifts insert own" on cashier_shifts;
drop policy if exists "shifts read own or admin" on cashier_shifts;
drop policy if exists "shifts update own open or admin" on cashier_shifts;

drop policy if exists "transactions insert" on transactions;
drop policy if exists "transactions read" on transactions;

drop policy if exists "transaction_items insert" on transaction_items;
drop policy if exists "transaction_items read" on transaction_items;

drop policy if exists "attendance insert own" on attendance_records;
drop policy if exists "attendance read own or admin" on attendance_records;

create policy "profiles read"
  on profiles
  for select
  using (auth.uid() = id or is_admin());

create policy "profiles insert"
  on profiles
  for insert
  with check (auth.uid() = id);

create policy "profiles update"
  on profiles
  for update
  using (is_admin())
  with check (is_admin());

create policy "products read"
  on products
  for select
  using (auth.uid() is not null);

create policy "products admin"
  on products
  for all
  using (is_admin())
  with check (is_admin());

create policy "shifts insert own"
  on cashier_shifts
  for insert
  with check (auth.uid() = cashier_id);

create policy "shifts read own or admin"
  on cashier_shifts
  for select
  using (auth.uid() = cashier_id or is_admin());

create policy "shifts update own open or admin"
  on cashier_shifts
  for update
  using (auth.uid() = cashier_id or is_admin())
  with check (auth.uid() = cashier_id or is_admin());

create policy "stock admin"
  on stock_movements
  for all
  using (is_admin())
  with check (is_admin());

create policy "stock read authenticated"
  on stock_movements
  for select
  using (auth.uid() is not null);

create policy "stock out insert authenticated"
  on stock_movements
  for insert
  with check (
    auth.uid() is not null
    and type = 'out'
    and qty > 0
    and product_id is not null
  );

create policy "transactions insert"
  on transactions
  for insert
  with check (
    auth.uid() = cashier_id
    and (
      shift_id is null
      or exists (
        select 1 from cashier_shifts s
        where s.id = shift_id
          and s.cashier_id = auth.uid()
          and s.closed_at is null
      )
    )
  );

create policy "transactions read"
  on transactions
  for select
  using (is_admin() or cashier_id = auth.uid());

create policy "transaction_items insert"
  on transaction_items
  for insert
  with check (auth.uid() is not null);

create policy "transaction_items read"
  on transaction_items
  for select
  using (
    is_admin()
    or exists (
      select 1 from transactions t
      where t.id = transaction_id
        and t.cashier_id = auth.uid()
    )
  );

create policy "attendance insert own"
  on attendance_records
  for insert
  with check (
    auth.uid() = user_id
    and biometric_verified = true
  );

create policy "attendance read own or admin"
  on attendance_records
  for select
  using (auth.uid() = user_id or is_admin());

insert into storage.buckets (id, name, public)
values ('attendance-photos', 'attendance-photos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "attendance photos read" on storage.objects;
drop policy if exists "attendance photos upload own folder" on storage.objects;

create policy "attendance photos read"
  on storage.objects
  for select
  using (bucket_id = 'attendance-photos');

create policy "attendance photos upload own folder"
  on storage.objects
  for insert
  with check (
    bucket_id = 'attendance-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================
-- C. SEED MENU (idempotent)
-- ============================================================

insert into products (name, category, price, image_url, is_active)
select 'Nasi Ayam Katsu', 'Aneka Ayam', 15000, null, true
where not exists (select 1 from products where name = 'Nasi Ayam Katsu');

insert into products (name, category, price, image_url, is_active)
select 'Nasi Ayam Popkek', 'Aneka Ayam', 15000, null, true
where not exists (select 1 from products where name = 'Nasi Ayam Popkek');

insert into products (name, category, price, image_url, is_active)
select 'Ayam Katsu (tanpa nasi)', 'Aneka Ayam', 12000, null, true
where not exists (select 1 from products where name = 'Ayam Katsu (tanpa nasi)');

insert into products (name, category, price, image_url, is_active)
select 'Ayam Popkek (tanpa nasi)', 'Aneka Ayam', 12000, null, true
where not exists (select 1 from products where name = 'Ayam Popkek (tanpa nasi)');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Katsu', 'Aneka Nasi Goreng', 22000, null, true
where not exists (select 1 from products where name = 'Nasgor Katsu');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Katsu Telur', 'Aneka Nasi Goreng', 25000, null, true
where not exists (select 1 from products where name = 'Nasgor Katsu Telur');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Ayam Popkek', 'Aneka Nasi Goreng', 22000, null, true
where not exists (select 1 from products where name = 'Nasgor Ayam Popkek');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Ayam', 'Aneka Nasi Goreng', 13000, null, true
where not exists (select 1 from products where name = 'Nasgor Ayam');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Ayam Popkek Telur', 'Aneka Nasi Goreng', 25000, null, true
where not exists (select 1 from products where name = 'Nasgor Ayam Popkek Telur');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Pedas', 'Aneka Nasi Goreng', 16000, null, true
where not exists (select 1 from products where name = 'Nasgor Pedas');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Bakaran', 'Aneka Nasi Goreng', 16000, null, true
where not exists (select 1 from products where name = 'Nasgor Bakaran');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Kampung', 'Aneka Nasi Goreng', 15000, null, true
where not exists (select 1 from products where name = 'Nasgor Kampung');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Sosis', 'Aneka Nasi Goreng', 13000, null, true
where not exists (select 1 from products where name = 'Nasgor Sosis');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Ikan Teri', 'Aneka Nasi Goreng', 20000, null, true
where not exists (select 1 from products where name = 'Nasgor Ikan Teri');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Gila', 'Aneka Nasi Goreng', 20000, null, true
where not exists (select 1 from products where name = 'Nasgor Gila');

insert into products (name, category, price, image_url, is_active)
select 'Nasgor Pete', 'Aneka Nasi Goreng', 18000, null, true
where not exists (select 1 from products where name = 'Nasgor Pete');

insert into products (name, category, price, image_url, is_active)
select 'Indomie Bangladesh', 'Aneka Indomie', 15000, null, true
where not exists (select 1 from products where name = 'Indomie Bangladesh');

insert into products (name, category, price, image_url, is_active)
select 'Ayam Katsu + Indomie Goreng', 'Aneka Indomie', 18000, null, true
where not exists (select 1 from products where name = 'Ayam Katsu + Indomie Goreng');

insert into products (name, category, price, image_url, is_active)
select 'Es Teh / Teh Tarik', 'Minuman', 3000, null, true
where not exists (select 1 from products where name = 'Es Teh / Teh Tarik');

insert into products (name, category, price, image_url, is_active)
select 'Milo / Coklat', 'Minuman', 5000, null, true
where not exists (select 1 from products where name = 'Milo / Coklat');

insert into products (name, category, price, image_url, is_active)
select 'Nutrisari', 'Minuman', 4000, null, true
where not exists (select 1 from products where name = 'Nutrisari');

insert into products (name, category, price, image_url, is_active)
select 'Jeruk Manis / Jeruk Nipis', 'Minuman', 5000, null, true
where not exists (select 1 from products where name = 'Jeruk Manis / Jeruk Nipis');

insert into products (name, category, price, image_url, is_active)
select 'Kopi Hitam / Cappuccino', 'Minuman', 4000, null, true
where not exists (select 1 from products where name = 'Kopi Hitam / Cappuccino');

insert into products (name, category, price, image_url, is_active)
select 'Air Mineral', 'Minuman', 3000, null, true
where not exists (select 1 from products where name = 'Air Mineral');

-- ============================================================
-- D. SYNC PROFILES FROM EXISTING AUTH USERS
-- Pastikan user sudah dibuat dari Supabase Dashboard Auth.
-- ============================================================

insert into profiles (id, email, role)
select au.id, au.email, 'admin'
from auth.users au
where au.email = 'admin@bangjun.id'
on conflict (id)
do update set email = excluded.email, role = excluded.role;

insert into profiles (id, email, role)
select au.id, au.email, 'kasir'
from auth.users au
where au.email = 'kasir@bangjun.id'
on conflict (id)
do update set email = excluded.email, role = excluded.role;

-- ============================================================
-- E. VERIFIKASI
-- ============================================================

select
  au.email,
  p.role,
  au.email_confirmed_at,
  p.created_at,
  case when p.id is null then 'BELUM ADA DI PROFILES' else 'OK' end as status
from auth.users au
left join profiles p on p.id = au.id
where au.email in ('admin@bangjun.id', 'kasir@bangjun.id')
order by au.email;
