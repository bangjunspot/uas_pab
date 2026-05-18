![Banner](https://capsule-render.vercel.app/api?type=waving&height=260&color=0:F97316,50:EA580C,100:C2410C&text=BANGJUN%20SPOT&fontColor=ffffff&fontSize=52&fontAlignY=38&desc=POS%20UMKM%20Kuliner%20%C2%B7%20Flutter%20%C2%B7%20Supabase%20%C2%B7%20Samarinda&descAlignY=58&animation=fadeIn)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-F97316?style=for-the-badge)](#)
[![Status](https://img.shields.io/badge/Status-UAS%20Ready-EA580C?style=for-the-badge)](#)

<p align="center">
  Aplikasi kasir dan manajemen operasional Kedai Bang Jun.<br>
  Fokus pada <strong>kecepatan kasir</strong>, <strong>kontrol stok</strong>, <strong>insight transaksi</strong>, dan <strong>lokasi kedai</strong>.
</p>

---

### 🌐 Sumber Daya Proyek

| Sumber Daya | Tautan |
|---|---|
| 📊 **Slide Presentasi** | [Lihat di Canva](https://canva.link/g10638pe91h9aws) |
| 💻 **Repository GitHub** | [github.com/bangjunspot/uas_pab](https://github.com/bangjunspot/uas_pab) |

---

## 📑 Daftar Isi

- [🎯 Ringkasan Proyek](#-ringkasan-proyek)
- [✨ Fitur Utama](#-fitur-utama)
- [🛠️ Teknologi yang Digunakan](#️-teknologi-yang-digunakan)
- [🗂️ Struktur Folder](#️-struktur-folder)
- [🗃️ Skema Database](#️-skema-database)
- [🧩 Arsitektur Aplikasi](#-arsitektur-aplikasi)
- [🚀 Setup Lokal](#-setup-lokal)
- [📱 Halaman & Fitur Aplikasi](#-halaman--fitur-aplikasi)
- [⚙️ Konfigurasi Penting](#️-konfigurasi-penting)
- [🔐 Fitur Keamanan](#-fitur-keamanan)
- [📡 Integrasi Sensor & Platform](#-integrasi-sensor--platform)
- [📌 Panduan Supabase](#-panduan-supabase)
- [🗄️ Run All SQL](#️-run-all-sql)
- [🧪 Akun Demo](#-akun-demo)
- [📋 Catatan Operasional](#-catatan-operasional)
- [🔧 Troubleshooting](#-troubleshooting)
- [🗺️ Rencana Lanjutan](#️-rencana-lanjutan)
- [👥 Tim Pengembang](#-tim-pengembang)
- [📄 Lisensi](#-lisensi)

---

## 🎯 Ringkasan Proyek

**BANGJUN SPOT** adalah aplikasi **Point of Sale (POS)** berbasis Flutter yang dirancang khusus untuk **Warung BangJun**, sebuah UMKM kuliner di Samarinda. Aplikasi ini menghadirkan solusi digitalisasi operasional warung secara menyeluruh — dari transaksi kasir yang cepat hingga analitik penjualan yang informatif.

Aplikasi ini menyediakan dua lapisan akses utama:

- **Kasir** — Melayani transaksi harian dengan UX yang cepat: quick add item, hotkey keyboard, repeat last order, dan validasi stok otomatis saat checkout.
- **Admin** — Mengelola produk, memantau stok, membaca laporan penjualan, serta mengatur user dan lokasi kedai.

> **Tujuan Utama:** Membantu operasional Warung BangJun beralih dari pencatatan manual ke sistem digital yang **praktis, cepat dipakai, dan siap dipresentasikan** sebagai proyek UAS.

**Fokus pengembangan:**

- **Kecepatan transaksi kasir** — Hotkey `1–9`, quick search, dan repeat order untuk melayani pembeli lebih cepat.
- **Kontrol stok real-time** — Setiap transaksi langsung mengurangi stok; notifikasi cerdas saat stok kritis.
- **Dashboard analitik bisnis** — Grafik omzet, performa 7 hari terakhir, dan menu terlaris dalam satu layar.
- **Integrasi sensor modern** — GPS (lokasi & ETA kedai), kamera (foto produk), dan notifikasi lokal.

---

## ✨ Fitur Utama

### 📊 1. Dashboard Bisnis

**Ringkasan Real-Time:**
- Omzet hari ini
- Daftar transaksi terbaru
- Stok kritis (produk hampir habis)
- Menu terlaris periode berjalan

**Notifikasi Cerdas:**
- ⚠️ Stok hampir habis — peringatan sebelum produk kosong
- 💡 Menu nonaktif tapi stok masih tersedia — ingatkan admin untuk mengaktifkan kembali
- 📉 Omzet turun dibanding kemarin / 7 hari sebelumnya

**Grafik Performa:**
- Tren penjualan **7 hari terakhir**
- Keuntungan **tahunan per bulan**
- Detail **bulanan** dengan breakdown per produk

---

### 📍 2. Lokasi Kedai

- Deteksi dan simpan **koordinat GPS** kedai (`store_lat`, `store_lng`) ke tabel `profiles` di Supabase.
- Hitung **jarak pengguna ke kedai** secara real-time.
- Estimasi waktu tempuh (**ETA**) berbasis kecepatan rata-rata:

| Mode | Kecepatan Estimasi |
|---|---|
| 🚶 Jalan Kaki | ~5 km/jam |
| 🛵 Motor | ~30 km/jam |
| 🚗 Mobil | ~60 km/jam |

- Buka rute langsung di **Google Maps** (deep link via `url_launcher`).
- Preview peta di dalam aplikasi via **WebView** (Android).

> **Catatan:** ETA adalah estimasi berbasis kecepatan rata-rata, bukan live traffic.

---

### 📦 3. Manajemen Produk

- Tambah, edit, dan hapus produk.
- Pengelompokan produk berdasarkan **kategori**.
- **Toggle aktif/nonaktif** — produk nonaktif tidak tampil di halaman kasir.
- Upload **foto produk** dari 3 sumber:
  - 📷 Kamera langsung
  - 🖼️ Galeri foto
  - 📁 Penyimpanan file (file picker)
- **Crop foto sebelum upload** untuk rasio gambar yang konsisten.
- Foto tersimpan di Supabase Storage bucket **`product-images`**.

---

### 🧾 4. Halaman Kasir (Fast UX)

Dirancang untuk kecepatan melayani pembeli — meminimalkan tap dan waktu per transaksi.

| Fitur | Keterangan |
|---|---|
| ⚡ Quick Add Item | Tambah item ke keranjang dengan satu tap |
| 🔍 Quick Search | Cari menu secara instan saat mengetik |
| 🕐 Recent Items | Tampilkan item yang baru-baru ini dipilih |
| 🔁 Repeat Last Order | Ulangi transaksi terakhir langsung ke keranjang |
| ⌨️ Hotkey `1–9` | Tambah item via keyboard tanpa menyentuh layar |
| ✅ Validasi Stok | Stok diperiksa saat tambah item dan saat checkout |
| 🛒 Keranjang Interaktif | Edit kuantitas, hapus item, dan checkout cepat |

---

### 🔑 5. Autentikasi & Manajemen User

- Login aman berbasis **Supabase Auth** (JWT).
- Sistem role: **`admin`** dan **`cashier`** dengan hak akses terpisah.
- Profil user tersimpan di tabel `profiles` (relasi ke `auth.users`).
- Koordinat lokasi kedai (`store_lat`, `store_lng`) ikut tersimpan di tabel `profiles`.
- Pembuatan akun kasir baru via **Supabase Edge Function** (`create-user`).

---

## 🛠️ Teknologi yang Digunakan

| Kategori | Teknologi |
|---|---|
| **Framework Utama** | Flutter 3.10+ |
| **Bahasa** | Dart 3.x |
| **State Management** | Provider |
| **Backend & Auth** | Supabase Auth |
| **Database** | Supabase PostgreSQL |
| **File Storage** | Supabase Storage |
| **Serverless Function** | Supabase Edge Function (`create-user`) |
| **Grafik & Chart** | fl_chart |
| **Foto & Crop** | image_picker, image_cropper, file_picker |
| **GPS & Lokasi** | geolocator |
| **Deep Link** | url_launcher |
| **WebView** | webview_flutter |
| **Notifikasi Lokal** | local_notification_service (custom) |
| **Preferensi Lokal** | shared_preferences |

---

## 🗂️ Struktur Folder

<details>
<summary><strong>📂 Klik untuk memperluas struktur folder lengkap</strong></summary>

```
lib/
├── core/
│   ├── services/
│   │   ├── location_service.dart           -> GPS, hitung jarak & ETA, deep link Maps
│   │   ├── local_notification_service.dart -> Notifikasi stok kritis & omzet
│   │   └── supabase_service.dart           -> Inisialisasi & helper Supabase client
│   │
│   └── utils/
│       ├── currency_formatter.dart         -> Format angka ke Rupiah (Rp)
│       ├── date_formatter.dart             -> Format tanggal & waktu
│       ├── input_validators.dart           -> Validasi form (nama, harga, stok, dll)
│       ├── rupiah_input_formatter.dart     -> TextInputFormatter khusus mata uang
│       └── emoji_filter.dart              -> Filter emoji dari input teks
│
├── features/
│   ├── auth/
│   │   └── login_page.dart                -> Halaman login email + password
│   ├── dashboard/
│   │   └── dashboard_page.dart            -> Dashboard bisnis, grafik, notifikasi
│   ├── kasir/
│   │   └── kasir_page.dart                -> POS: keranjang, quick add, hotkey, checkout
│   ├── product/
│   │   └── product_page.dart              -> CRUD produk, upload & crop foto
│   ├── stock/
│   │   └── stock_page.dart                -> Riwayat stock movement, monitoring stok kritis
│   ├── settings/
│   │   └── settings_page.dart             -> Pengaturan lokasi kedai & preferensi app
│   └── home/
│       └── home_page.dart                 -> Halaman utama dengan navigasi role
│
├── models/
│   ├── product.dart                       -> Model produk (id, nama, harga, is_active, dll)
│   ├── cart_item.dart                     -> Model item di keranjang
│   ├── transaction.dart                   -> Model header transaksi
│   ├── transaction_item.dart              -> Model detail item transaksi
│   └── profile.dart                       -> Model profil user + role + koordinat kedai
│
├── providers/
│   ├── auth_provider.dart                 -> State login, logout, session, role
│   ├── cart_provider.dart                 -> State keranjang, validasi stok, checkout
│   ├── product_provider.dart              -> State CRUD produk, upload foto
│   ├── stock_provider.dart                -> State riwayat stok, monitoring kritis
│   └── transaction_provider.dart          -> State riwayat & detail transaksi
│
├── widgets/
│   ├── clay_button.dart                   -> Tombol bergaya Clay/Neumorphic
│   ├── clay_card.dart                     -> Card bergaya Clay/Neumorphic
│   ├── clay_fade_slide.dart               -> Animasi fade + slide untuk transisi
│   ├── clay_fab.dart                      -> Floating Action Button bergaya Clay
│   └── clay_input.dart                    -> TextField bergaya Clay
│
└── theme/
    └── clay_colors.dart                   -> Palet warna tema Clay/Neumorphic

supabase/
├── functions/
│   └── create-user/                       -> Edge Function: buat user dari admin
└── run_all.sql                            -> Schema + RLS + policy + bucket storage

assets/
└── .env                                   -> SUPABASE_URL & SUPABASE_ANON_KEY
```

</details>

---

## 🗃️ Skema Database

Database dikelola di **Supabase PostgreSQL** dengan **Row Level Security (RLS)** aktif di semua tabel. Skema berikut adalah struktur aktual yang digunakan aplikasi.

### Tabel `profiles`

Menyimpan profil pengguna dan koordinat lokasi kedai. Berelasi langsung ke `auth.users`.

```sql
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text,
  role       text default 'cashier',   -- 'admin' atau 'cashier'
  store_lat  double precision,         -- Latitude lokasi kedai
  store_lng  double precision,         -- Longitude lokasi kedai
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

---

### Tabel `products`

Menyimpan data master produk/menu Warung BangJun.

```sql
create table if not exists public.products (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  category   text,
  price      numeric(14,2) not null default 0,
  image_url  text,
  is_active  boolean not null default true,
  created_at timestamptz default now()
);
```

---

### Tabel `stock_movements`

Mencatat setiap pergerakan stok. Nilai `qty` positif = stok masuk, negatif = stok keluar.

```sql
create table if not exists public.stock_movements (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  qty        integer not null,   -- (+) masuk | (-) keluar
  note       text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);
```

---

### Tabel `transactions`

Menyimpan header setiap transaksi yang diproses kasir.

```sql
create table if not exists public.transactions (
  id         uuid primary key default gen_random_uuid(),
  cashier_id uuid not null references auth.users(id),
  total      numeric(14,2) not null default 0,
  created_at timestamptz default now()
);
```

---

### Tabel `transaction_items`

Menyimpan detail item per transaksi.

```sql
create table if not exists public.transaction_items (
  id             uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  product_id     uuid not null references public.products(id),
  qty            integer not null,
  price          numeric(14,2) not null default 0
);
```

---

### 🔐 Ringkasan Keamanan Database

| Aspek | Detail |
|---|---|
| **RLS** | Aktif di semua 5 tabel inti |
| **Policy Profiles** | User hanya bisa akses & edit profil miliknya sendiri (`auth.uid() = id`) |
| **Policy Produk & Transaksi** | Semua user `authenticated` bisa CRUD |
| **Storage Bucket** | `product-images` — dibuat otomatis via `run_all.sql` |
| **Storage Policy** | User `authenticated` bisa read, insert, update, delete foto produk |
| **Script Lengkap** | [`supabase/run_all.sql`](supabase/run_all.sql) — jalankan sekali, semua siap |

---

## 🧩 Arsitektur Aplikasi

Aplikasi menggunakan pola modular **features + providers** yang terinspirasi Clean Architecture ringan:

```
User Action (Tap / Input / Hotkey)
         │
         ▼
  Feature Page (UI)           ← lib/features/[domain]/
         │
         ▼
  Provider (State + Logic)    ← lib/providers/
         │
         ├──► Service          ← lib/core/services/
         │        │
         │        ▼
         │   Supabase SDK      ← Auth / PostgreSQL / Storage
         │
         └──► Model            ← lib/models/
                  │
                  ▼
         Data Class Dart       ← Product, Transaction, Profile, dll
```

### Alur Lengkap Pengguna

```
1. App Start
      │
      ▼
2. Cek Supabase Session
      │
      ├── Belum Login ──► Halaman Login
      │                       │
      │                  Input Email + Password
      │                       │
      │                  Supabase Auth (JWT)
      │
      └── Sudah Login ──► Load Profile & Role
                               │
                    ┌──────────┴──────────┐
                    │                     │
               Role: admin          Role: cashier
                    │                     │
             ┌──────┴──────┐        ┌─────┴──────┐
             │             │        │            │
         Dashboard    Produk &   Halaman    Riwayat
          Bisnis        Stok      Kasir    Transaksi
         (Grafik,     (CRUD,    (Quick     (Detail
         Notif, ETA)  Upload)   Add, POS)   Item)
```

---

## 🚀 Setup Lokal

### Prasyarat

- Flutter SDK **>= 3.10**
- Dart **3.x**
- Android Emulator / Device atau Windows Desktop
- Project **Supabase** aktif

---

### 1. Clone Repository

```bash
git clone https://github.com/bangjunspot/uas_pab.git
cd uas_pab
```

---

### 2. Install Dependency

```bash
flutter pub get
```

---

### 3. Jalankan Analyzer

```bash
flutter analyze
```

---

### 4. Konfigurasi Environment

Isi file `assets/.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

> ⚠️ Jangan commit file `.env` ke repository publik!

---

### 5. Setup Database

Jalankan [`supabase/run_all.sql`](supabase/run_all.sql) di **Supabase Dashboard → SQL Editor**.
Satu kali jalan — semua tabel, RLS, policy, dan bucket storage langsung siap. Lihat [🗄️ Run All SQL](#️-run-all-sql) untuk isi lengkapnya.

---

### 6. Jalankan Aplikasi

**Android:**
```bash
flutter run
```

**Windows Desktop:**
```bash
flutter run -d windows
```

**Build APK:**
```bash
flutter build apk --release
```

---

## 📱 Halaman & Fitur Aplikasi

| Halaman | Role | Fungsi Utama |
|---|---|---|
| **Login** | Semua | Autentikasi email/password via Supabase Auth |
| **Dashboard** | Admin | Grafik omzet, notifikasi cerdas, stok kritis, ETA kedai |
| **Kasir (POS)** | Cashier, Admin | Quick add, hotkey 1–9, repeat order, checkout |
| **Riwayat Transaksi** | Cashier, Admin | Daftar & detail transaksi harian |
| **Manajemen Produk** | Admin | CRUD produk, upload & crop foto, toggle aktif |
| **Manajemen Stok** | Admin | Riwayat stock movement, monitoring stok kritis |
| **Manajemen User** | Admin | Tambah/kelola akun kasir via Edge Function |
| **Pengaturan** | Admin | Simpan koordinat GPS kedai, hitung jarak & ETA |

---

## ⚙️ Konfigurasi Penting

### Android Permissions

Pastikan `android/app/src/main/AndroidManifest.xml` sudah memuat izin berikut:

```xml
<!-- Koneksi internet (Supabase) -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Kamera (foto produk) -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- Akses gambar (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- Akses storage (Android ≤ 12) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>

<!-- Lokasi GPS -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

### Supabase Storage

Bucket `product-images` dibuat **otomatis** oleh `run_all.sql`. Jika perlu membuat manual:

| Setting | Nilai |
|---|---|
| **Nama Bucket** | `product-images` |
| **Public Bucket** | ✅ ON |

---

## 🔐 Fitur Keamanan

### Row Level Security (RLS) — Supabase

Setiap tabel dilindungi RLS dengan policy yang berbeda:

| Tabel | Policy |
|---|---|
| `profiles` | User hanya bisa SELECT / INSERT / UPDATE profil miliknya sendiri (`auth.uid() = id`) |
| `products` | Semua user `authenticated` bisa CRUD |
| `stock_movements` | Semua user `authenticated` bisa CRUD |
| `transactions` | Semua user `authenticated` bisa CRUD |
| `transaction_items` | Semua user `authenticated` bisa CRUD |

### Autentikasi JWT

Login via Supabase Auth berbasis JWT. Token di-refresh otomatis. Jika token kadaluarsa, pengguna diarahkan ke halaman login.

### Edge Function untuk Pembuatan User

Pembuatan akun kasir melalui **Supabase Edge Function** (`create-user`) — bukan dari client langsung — agar `service_role` key tidak terekspos ke perangkat pengguna.

### Validasi Input & Upload

Semua form divalidasi via `input_validators.dart`. Emoji difilter dari input kritis via `emoji_filter.dart`. Foto produk divalidasi tipe & ukuran sebelum diunggah; nama file di-generate unik.

---

## 📡 Integrasi Sensor & Platform

| Package | Sensor / Fitur | Keterangan |
|---|---|---|
| `geolocator` | 📍 GPS | Deteksi koordinat, hitung jarak & ETA ke kedai |
| `url_launcher` | 🗺️ Google Maps | Buka rute navigasi di Google Maps |
| `webview_flutter` | 🗺️ WebView | Preview peta di dalam aplikasi (Android) |
| `image_picker` | 📷 Kamera & Galeri | Ambil foto produk dari kamera atau galeri |
| `file_picker` | 📁 File Storage | Pilih gambar dari penyimpanan file |
| `image_cropper` | ✂️ Crop Foto | Crop & resize foto sebelum upload ke Storage |
| `local_notification_service` | 🔔 Notifikasi | Notifikasi stok kritis & penurunan omzet |

> **Catatan:** WebView peta tidak optimal di Windows Desktop. Tersedia fallback UI: info koordinat teks + tombol buka Google Maps.

---

## 📌 Panduan Supabase

### A. Setup Project

1. Buka [supabase.com](https://supabase.com) dan buat project baru.
2. Catat **Project URL** dan **Anon Key** dari **Settings → API**.
3. Isi ke `assets/.env`.

### B. Jalankan SQL Setup

Di **SQL Editor**, jalankan `supabase/run_all.sql` (lihat bagian berikutnya). Pastikan tidak ada error merah sebelum melanjutkan.

### C. Buat User Auth

Di **Authentication → Users → Add User**:

| Email | Role |
|---|---|
| `admin@bangjun.id` | admin |
| `kasir@bangjun.id` | cashier |

Setelah menambahkan user, jalankan ulang `run_all.sql` agar tabel `profiles` tersinkron dengan `auth.users`.

### D. Deploy Edge Function

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy create-user
```

---

## 🗄️ Run All SQL

File `supabase/run_all.sql` menyatukan seluruh setup database dalam satu alur: pembuatan tabel, aktivasi RLS, policy per tabel, pembuatan bucket storage, dan policy storage. **Jalankan sekali di SQL Editor, semua langsung siap.**

```sql
-- =========================================================
-- BANGJUN SPOT - RUN ALL SQL
-- =========================================================
-- 1) Tabel inti (profiles, products, stock, transactions)
-- 2) Enable RLS
-- 3) Policy tabel
-- 4) Bucket storage + policy
-- =========================================================

-- [PROFILES] Profil user + koordinat lokasi kedai
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text default 'cashier',
  store_lat double precision,
  store_lng double precision,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- [PRODUCTS] Master produk/menu
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  price numeric(14,2) not null default 0,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz default now()
);

-- [STOCK MOVEMENTS] Riwayat perubahan stok
-- qty (+) = stok masuk | qty (-) = stok keluar
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  qty integer not null,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- [TRANSACTIONS] Header transaksi kasir
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  cashier_id uuid not null references auth.users(id),
  total numeric(14,2) not null default 0,
  created_at timestamptz default now()
);

-- [TRANSACTION ITEMS] Detail item dalam transaksi
create table if not exists public.transaction_items (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  product_id uuid not null references public.products(id),
  qty integer not null,
  price numeric(14,2) not null default 0
);

-- =========================================================
-- RLS: Aktifkan Row Level Security
-- =========================================================
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.stock_movements enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;

-- =========================================================
-- POLICY: profiles
-- User hanya bisa akses profil miliknya sendiri
-- =========================================================
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select to authenticated
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- =========================================================
-- POLICY: products
-- =========================================================
drop policy if exists "products_read" on public.products;
create policy "products_read"
on public.products for select to authenticated using (true);

drop policy if exists "products_insert" on public.products;
create policy "products_insert"
on public.products for insert to authenticated with check (true);

drop policy if exists "products_update" on public.products;
create policy "products_update"
on public.products for update to authenticated
using (true) with check (true);

drop policy if exists "products_delete" on public.products;
create policy "products_delete"
on public.products for delete to authenticated using (true);

-- =========================================================
-- POLICY: stock_movements
-- =========================================================
drop policy if exists "stock_read" on public.stock_movements;
create policy "stock_read"
on public.stock_movements for select to authenticated using (true);

drop policy if exists "stock_insert" on public.stock_movements;
create policy "stock_insert"
on public.stock_movements for insert to authenticated with check (true);

drop policy if exists "stock_update" on public.stock_movements;
create policy "stock_update"
on public.stock_movements for update to authenticated
using (true) with check (true);

drop policy if exists "stock_delete" on public.stock_movements;
create policy "stock_delete"
on public.stock_movements for delete to authenticated using (true);

-- =========================================================
-- POLICY: transactions
-- =========================================================
drop policy if exists "transactions_read" on public.transactions;
create policy "transactions_read"
on public.transactions for select to authenticated using (true);

drop policy if exists "transactions_insert" on public.transactions;
create policy "transactions_insert"
on public.transactions for insert to authenticated with check (true);

drop policy if exists "transactions_update" on public.transactions;
create policy "transactions_update"
on public.transactions for update to authenticated
using (true) with check (true);

drop policy if exists "transactions_delete" on public.transactions;
create policy "transactions_delete"
on public.transactions for delete to authenticated using (true);

-- =========================================================
-- POLICY: transaction_items
-- =========================================================
drop policy if exists "transaction_items_read" on public.transaction_items;
create policy "transaction_items_read"
on public.transaction_items for select to authenticated using (true);

drop policy if exists "transaction_items_insert" on public.transaction_items;
create policy "transaction_items_insert"
on public.transaction_items for insert to authenticated with check (true);

drop policy if exists "transaction_items_update" on public.transaction_items;
create policy "transaction_items_update"
on public.transaction_items for update to authenticated
using (true) with check (true);

drop policy if exists "transaction_items_delete" on public.transaction_items;
create policy "transaction_items_delete"
on public.transaction_items for delete to authenticated using (true);

-- =========================================================
-- STORAGE: Bucket + policy untuk foto produk
-- =========================================================
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

drop policy if exists "product_images_read" on storage.objects;
create policy "product_images_read"
on storage.objects for select to authenticated
using (bucket_id = 'product-images');

drop policy if exists "product_images_insert" on storage.objects;
create policy "product_images_insert"
on storage.objects for insert to authenticated
with check (bucket_id = 'product-images');

drop policy if exists "product_images_update" on storage.objects;
create policy "product_images_update"
on storage.objects for update to authenticated
using (bucket_id = 'product-images')
with check (bucket_id = 'product-images');

drop policy if exists "product_images_delete" on storage.objects;
create policy "product_images_delete"
on storage.objects for delete to authenticated
using (bucket_id = 'product-images');
```

> **Catatan:** Jika di project lama ada nama policy yang sama, `drop policy if exists` di awal setiap blok akan membersihkannya sebelum dibuat ulang — tidak perlu hapus manual.

---

## 🧪 Akun Demo

| Role | Email | Password |
|---|---|---|
| 👑 **Admin** | `admin@bangjun.id` | *diberikan kepada pengembang* |
| 🧾 **Kasir** | `kasir@bangjun.id` | *diberikan kepada pengembang* |

---

## 📋 Catatan Operasional

### Repeat Last Order

Saat kasir menekan **Repeat Last Order**, sistem memeriksa tiap item dari transaksi terakhir:

| Kondisi Item | Perilaku |
|---|---|
| Produk tidak ditemukan di database | ⏭️ Dilewati otomatis |
| Produk berstatus nonaktif (`is_active = false`) | ⏭️ Dilewati otomatis |
| Stok habis | ⏭️ Dilewati otomatis |
| Stok tersedia tapi kurang dari qty sebelumnya | ✅ Qty disesuaikan dengan stok tersedia |
| Stok cukup | ✅ Ditambahkan normal ke keranjang |

### Estimasi Waktu Tempuh (ETA)

ETA dihitung dari `store_lat` / `store_lng` yang tersimpan di `profiles`. Angka yang ditampilkan adalah perkiraan ideal berbasis kecepatan rata-rata — bukan live traffic.

### Notifikasi Omzet

Notifikasi penurunan omzet muncul jika omzet hari ini lebih rendah dari kemarin atau rata-rata 7 hari sebelumnya. Bersifat informatif dan tidak memblokir penggunaan aplikasi.

---

## 🔧 Troubleshooting

### ❌ 1. Login Gagal / Error Auth

- Pastikan `assets/.env` diisi URL dan Key Supabase yang benar (tanpa trailing `/`).
- Jangan tambahkan `/rest/v1` di akhir URL — gunakan base URL saja.
- Pastikan user sudah ada di **Authentication → Users**.
- Pastikan `run_all.sql` sudah dijalankan di project yang sama.

---

### ❌ 2. Upload Foto Gagal — Error 404 Bucket

Bucket `product-images` belum ada. Jalankan ulang `run_all.sql` — bagian `insert into storage.buckets` akan membuat bucket otomatis. Atau buat manual di **Supabase → Storage → New Bucket** (nama: `product-images`, Public: ON).

---

### ❌ 3. GPS / Lokasi Tidak Terdeteksi

- Pastikan izin `ACCESS_FINE_LOCATION` ada di `AndroidManifest.xml`.
- Di perangkat, pastikan izin lokasi sudah diberikan ke aplikasi.
- Di emulator, aktifkan lokasi mock di **Extended Controls → Location**.

---

### ❌ 4. WebView Peta Tidak Muncul di Windows

WebView tidak didukung di Windows Desktop Flutter. Sudah ada fallback UI: koordinat teks + tombol **Buka di Google Maps** via `url_launcher`.

---

### ❌ 5. Stok Tidak Berkurang Setelah Checkout

Pastikan `run_all.sql` sudah dijalankan lengkap. Cek policy RLS `stock_insert` pada tabel `stock_movements` sudah mengizinkan user `authenticated` melakukan `INSERT`.

---

### ❌ 6. Konflik Policy Saat Jalankan run_all.sql

Semua blok policy diawali `drop policy if exists` sehingga aman dijalankan berulang kali. Jika masih error, periksa apakah nama policy di project lama berbeda dari yang ada di script.

---

### ❌ 7. flutter pub get Gagal

```bash
flutter clean
flutter pub get
```

Pastikan Flutter SDK **>= 3.10** dan koneksi internet stabil.

---

## 🗺️ Rencana Lanjutan

- [ ] Filter transaksi berdasarkan menu terlaris per periode.
- [ ] **Demand tracking** — deteksi "menu nonaktif tapi banyak dicari" dari riwayat pencarian kasir.
- [ ] Export laporan otomatis (harian / mingguan / bulanan) ke PDF atau CSV.
- [ ] Integrasi printer thermal Bluetooth untuk cetak struk.
- [ ] Multi-outlet — satu akun admin mengelola beberapa kedai.

---

## 👥 Tim Pengembang

| Nama | NIM | Role |
|---|---|---|
| Sayid Rafi A'thaya | 2409116036 | 💡 Project Manager |
| Mochammad Rezky Ramadhan | 2409116029 | ⚙️ Backend / Supabase |
| Adella Putri | 2409116006 | 🎨 Frontend / UI |
| Dhita Olivia Ramadhayanti Kusuma | 2409116040 | 🧾 Dokumentasi |

---

## 📄 Lisensi

Internal project **Kedai Bang Jun** — dikembangkan untuk keperluan UAS PAB.
Tidak diperkenankan untuk distribusi komersial tanpa izin tim pengembang.

---

<div align="center">

![Footer](https://capsule-render.vercel.app/api?type=waving&height=120&color=0:C2410C,100:F97316&section=footer)

**BANGJUN SPOT** &nbsp;·&nbsp; POS UMKM Kuliner Warung BangJun &nbsp;·&nbsp; Samarinda

[![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Powered_by-Supabase-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com/)
[![UAS](https://img.shields.io/badge/Project-UAS%20PAB-F97316?style=flat-square)](#)

</div>