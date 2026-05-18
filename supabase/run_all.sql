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
  is_active boolean default true,
  created_at timestamptz default now()
);

alter table products add column if not exists category text;

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
  total numeric,
  created_at timestamptz default now()
);

create table if not exists transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid references transactions(id) on delete cascade,
  product_id uuid references products(id),
  qty integer,
  price numeric
);

alter table if exists profiles enable row level security;
alter table if exists products enable row level security;
alter table if exists stock_movements enable row level security;
alter table if exists transactions enable row level security;
alter table if exists transaction_items enable row level security;

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

drop policy if exists "transactions insert" on transactions;
drop policy if exists "transactions read" on transactions;

drop policy if exists "transaction_items insert" on transaction_items;
drop policy if exists "transaction_items read" on transaction_items;

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
  with check (auth.uid() = cashier_id);

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
