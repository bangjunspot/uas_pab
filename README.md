![Banner](https://capsule-render.vercel.app/api?type=waving&height=260&color=0:F97316,50:EA580C,100:C2410C&text=BANGJUN%20SPOT&fontColor=ffffff&fontSize=52&fontAlignY=38&desc=POS%20UMKM%20Kuliner%20%C2%B7%20Flutter%20%C2%B7%20Supabase%20%C2%B7%20Samarinda&descAlignY=58&animation=fadeIn)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-F97316?style=for-the-badge)](#)
[![Status](https://img.shields.io/badge/Status-UAS%20Ready-EA580C?style=for-the-badge)](#)

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
- [🚀 Setup Cepat](#-setup-cepat)
- [📱 Halaman & Fitur Aplikasi](#-halaman--fitur-aplikasi)
- [🔐 Fitur Keamanan](#-fitur-keamanan)
- [📡 Integrasi Sensor & Platform](#-integrasi-sensor--platform)
- [⚙️ Panduan Supabase](#️-panduan-supabase)
- [🧪 Akun Demo](#-akun-demo)
- [🔧 Troubleshooting](#-troubleshooting)
- [👥 Tim Pengembang](#-tim-pengembang)

---

## 🎯 Ringkasan Proyek

**BANGJUN SPOT** adalah aplikasi **Point of Sale (POS)** berbasis Flutter yang dirancang khusus untuk **Warung BangJun**, sebuah UMKM kuliner yang berlokasi di Samarinda. Aplikasi ini hadir sebagai solusi digitalisasi operasional warung agar lebih terorganisir, efisien, dan mudah dipantau secara real-time.

Aplikasi ini menyediakan dua lapisan akses utama:

- **Kasir** — Melayani transaksi harian: tambah item ke keranjang, validasi stok, dan proses checkout dengan pencatatan otomatis.
- **Admin** — Mengelola produk, memantau stok, melihat laporan penjualan, serta mengatur user dan pengaturan kedai.

> **Tujuan Utama:** Membantu operasional Warung BangJun beralih dari pencatatan manual ke sistem digital yang praktis, cepat dipakai, dan siap dipresentasikan sebagai proyek UAS.

**Fokus pengembangan:**

- **Kemudahan transaksi kasir** — Alur kasir yang cepat dan intuitif, cocok untuk pengguna non-teknis.
- **Kontrol stok real-time** — Setiap transaksi otomatis mengurangi stok; admin mendapat notifikasi stok menipis.
- **Dashboard analitik** — Grafik omzet harian, mingguan, bulanan, dan tahunan dalam satu layar.
- **Integrasi sensor modern** — Kamera (barcode/QR), GPS (lokasi kedai), dan biometrik (keamanan login).

---

## ✨ Fitur Utama

### 🔑 1. Autentikasi & Manajemen User

- Login aman berbasis **Supabase Auth**.
- Sistem role: **`admin`** dan **`kasir`** dengan hak akses berbeda.
- Profil pengguna tersimpan di tabel `profiles`.
- **Login biometrik** (fingerprint/face) tersedia sebagai gate keamanan tambahan.
- Manajemen user: admin dapat membuat akun kasir baru melalui **Supabase Edge Function** (`create-user`).

---

### 🧾 2. Kasir (POS)

- Tambah produk ke **keranjang belanja** dengan mudah.
- **Validasi stok real-time** saat menambah kuantitas item.
- Proses **checkout transaksi** beserta pencatatan detail item.
- Stok otomatis berkurang (`stock out`) setiap transaksi berhasil.
- Tampilan produk responsif — grid atau list, sesuai preferensi kasir.

---

### 📦 3. Manajemen Produk

- Tambah, edit, dan hapus produk dengan mudah.
- Pengelompokan produk berdasarkan **kategori**.
- **Toggle aktif/nonaktif** produk — produk nonaktif tidak tampil di kasir.
- Upload **foto produk** ke Supabase Storage.
- **Crop foto sebelum upload** untuk memastikan ukuran dan rasio gambar konsisten.
- Scan **barcode/QR** produk menggunakan kamera perangkat.

---

### 📊 4. Manajemen Stok

- **Riwayat pergerakan stok** — tercatat setiap `stock in` (pengisian) dan `stock out` (penjualan).
- Monitoring produk dengan **stok mendekati habis**.
- Produk dapat dinonaktifkan otomatis atau manual saat stok mencapai 0.
- Semua mutasi stok terhubung langsung ke tabel `stock_movements`.

---

### 📈 5. Dashboard Admin

- Ringkasan **omzet harian & bulanan** dalam satu tampilan.
- **Grafik 7 hari terakhir** — tren penjualan harian.
- **Grafik bulanan & tahunan** — analisis performa jangka panjang.
- Daftar **transaksi terbaru** lengkap dengan detail item.
- **Informasi lokasi kedai** + tombol deteksi GPS otomatis.

---

### 📡 6. Sensor & Integrasi Platform

| Sensor | Fungsi |
|---|---|
| 📷 **Kamera** | Scan barcode/QR produk + foto produk |
| 📍 **GPS** | Simpan & tampilkan koordinat lokasi kedai |
| 🔒 **Biometrik** | Login cepat / gate keamanan (Android) |

---

### 🎨 7. UI/UX

- Tema custom **Clay / Neumorphic** yang modern dan elegan.
- Layout **responsif** — nyaman di mobile (Android) maupun web (browser desktop).
- Feedback pengguna via **SnackBar** notifikasi.
- Komponen reusable: `ClayCard`, `ClayButton`, dan lainnya.

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
| **Kamera & Barcode** | mobile_scanner |
| **Foto & Crop** | image_picker, image_cropper |
| **GPS** | geolocator |
| **Biometrik** | local_auth |
| **Preferensi Lokal** | shared_preferences |
| **WebView** | webview_flutter |

---

## 🗂️ Struktur Folder

<details>
<summary><strong>📂 Klik untuk memperluas struktur folder lengkap</strong></summary>

```
lib/
├── core/
│   ├── constants/          -> Konstanta aplikasi (warna, string, route)
│   ├── services/           -> Layanan platform (supabase, sensor, storage)
│   └── utils/              -> Helper & utilitas umum
│
├── features/
│   ├── auth/               -> Login, biometrik, session management
│   ├── dashboard/          -> Dashboard admin (grafik, ringkasan omzet)
│   ├── home/               -> Halaman utama setelah login
│   ├── kasir/              -> Modul POS (keranjang, checkout)
│   ├── product/            -> Manajemen produk (CRUD, foto, kategori)
│   ├── settings/           -> Pengaturan aplikasi & lokasi kedai
│   └── stock/              -> Manajemen & riwayat stok
│
├── models/                 -> Data model (Profile, Product, Transaction, dll)
│
├── providers/              -> State management & business logic
│   ├── auth_provider.dart
│   ├── kasir_provider.dart
│   ├── product_provider.dart
│   ├── stock_provider.dart
│   └── dashboard_provider.dart
│
├── theme/                  -> Konfigurasi tema Clay/Neumorphic
│
└── widgets/                -> Komponen UI reusable
    ├── clay_card.dart
    ├── clay_button.dart
    └── ...

supabase/
├── functions/
│   └── create-user/        -> Edge Function untuk membuat user baru
└── run_all.sql             -> Schema + policy + seed data lengkap

assets/
└── .env                    -> Konfigurasi Supabase URL & Anon Key
```

</details>

---

## 🗃️ Skema Database

Database dikelola di **Supabase PostgreSQL**. Semua tabel dilengkapi dengan **Row Level Security (RLS)** aktif.

### Tabel `profiles`

Menyimpan profil pengguna yang terhubung dengan Supabase Auth.

```sql
CREATE TABLE profiles (
    id         UUID PRIMARY KEY REFERENCES auth.users(id),
    full_name  VARCHAR(150),
    role       VARCHAR(20) DEFAULT 'kasir',  -- 'admin' atau 'kasir'
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

### Tabel `products`

Menyimpan data produk yang dijual di Warung BangJun.

```sql
CREATE TABLE products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(200) NOT NULL,
    category    VARCHAR(100),
    price       NUMERIC(10,2) NOT NULL,
    stock       INT NOT NULL DEFAULT 0,
    image_url   TEXT,
    is_active   BOOLEAN DEFAULT TRUE,
    barcode     VARCHAR(100),
    created_at  TIMESTAMP DEFAULT NOW()
);
```

---

### Tabel `stock_movements`

Mencatat setiap pergerakan stok — baik pengisian (`in`) maupun penjualan (`out`).

```sql
CREATE TABLE stock_movements (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id  UUID REFERENCES products(id),
    type        VARCHAR(10) NOT NULL,  -- 'in' atau 'out'
    quantity    INT NOT NULL,
    note        TEXT,
    created_by  UUID REFERENCES profiles(id),
    created_at  TIMESTAMP DEFAULT NOW()
);
```

---

### Tabel `transactions`

Menyimpan header setiap transaksi penjualan.

```sql
CREATE TABLE transactions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    total        NUMERIC(12,2) NOT NULL,
    payment      NUMERIC(12,2),
    change       NUMERIC(12,2),
    cashier_id   UUID REFERENCES profiles(id),
    created_at   TIMESTAMP DEFAULT NOW()
);
```

---

### Tabel `transaction_items`

Menyimpan detail item per transaksi.

```sql
CREATE TABLE transaction_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id  UUID REFERENCES transactions(id),
    product_id      UUID REFERENCES products(id),
    product_name    VARCHAR(200),
    quantity        INT NOT NULL,
    price           NUMERIC(10,2) NOT NULL,
    subtotal        NUMERIC(12,2) NOT NULL
);
```

---

### 🔐 Keamanan Database

| Fitur | Keterangan |
|---|---|
| **RLS (Row Level Security)** | Aktif di semua tabel inti |
| **Policy Role** | Policy berbeda untuk `admin` dan `kasir` |
| **Helper Function** | `is_admin()` untuk cek role di level database |
| **Script Lengkap** | [`supabase/run_all.sql`](supabase/run_all.sql) berisi schema + policy + seed |

---

## 🧩 Arsitektur Aplikasi

Aplikasi menggunakan pola modular berbasis `features` + `providers` (mirip Clean Architecture ringan):

```
User Action (Tap / Input)
        |
        v
   Feature Page (UI)          <- lib/features/[domain]/
        |
        v
   Provider (State + Logic)   <- lib/providers/
        |
        +---> Service          <- lib/core/services/
        |           |
        |           v
        |     Supabase SDK     <- supabase_flutter
        |     (Auth / DB / Storage)
        |
        +---> Model            <- lib/models/
                    |
                    v
            Data Class (Dart)  <- Profile, Product, Transaction, dll
```

### Alur Lengkap Aplikasi

```
1. App Start
      |
      v
2. Cek Session (Supabase Auth)
      |
      +-- Belum Login --> Halaman Login
      |                        |
      |                   Input Email + Password
      |                   (opsional: Biometrik)
      |                        |
      |                   Supabase Auth
      |
      +-- Sudah Login --> Load Profile & Role
                               |
                    +----------+----------+
                    |                     |
               Role: admin          Role: kasir
                    |                     |
             Dashboard Admin        Halaman Kasir (POS)
             (Grafik, Stok,         (Keranjang, Checkout,
              Laporan, User)         Riwayat Transaksi)
```

---

## 🚀 Setup Cepat

### Prasyarat

- Flutter SDK **>= 3.10**
- Dart **3.x**
- Android Emulator / Device atau Chrome (untuk web)
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

### 3. Konfigurasi Environment

Isi file `assets/.env` dengan kredensial Supabase kamu:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

> ⚠️ Jangan commit file `.env` ke repository publik!

---

### 4. Setup Database Supabase

Buka **Supabase Dashboard → SQL Editor**, lalu jalankan seluruh isi file:

```
supabase/run_all.sql
```

Script ini akan otomatis membuat:
- ✅ Semua tabel (profiles, products, stock_movements, transactions, transaction_items)
- ✅ RLS policy per role
- ✅ Helper function `is_admin()`
- ✅ Seed produk contoh

---

### 5. Buat Bucket Storage

Di **Supabase Dashboard → Storage → New Bucket**:

| Setting | Nilai |
|---|---|
| **Nama Bucket** | `product-images` |
| **Public Bucket** | ✅ ON |

> Tanpa bucket ini, fitur upload foto produk akan gagal dengan error `Bucket not found (404)`.

---

### 6. Buat User Demo

Di **Supabase Dashboard → Authentication → Users → Add User**:

| Email | Password | Role |
|---|---|---|
| `admin@bangjun.id` | *(diberikan pengembang)* | admin |
| `kasir@bangjun.id` | *(diberikan pengembang)* | kasir |

Setelah menambahkan user, jalankan ulang `run_all.sql` agar tabel `profiles` tersinkron.

---

### 7. Jalankan Aplikasi

**Web (Chrome):**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run
```

**Build APK:**
```bash
flutter build apk --release
```

---

## 📱 Halaman & Fitur Aplikasi

| Halaman | Role | Fungsi Utama |
|---|---|---|
| **Login** | Semua | Autentikasi email/password + biometrik |
| **Kasir (POS)** | Kasir, Admin | Transaksi penjualan, keranjang, checkout |
| **Riwayat Transaksi** | Kasir, Admin | Daftar & detail transaksi harian |
| **Dashboard** | Admin | Grafik omzet, ringkasan stok, transaksi terbaru |
| **Manajemen Produk** | Admin | CRUD produk, upload foto, toggle aktif |
| **Manajemen Stok** | Admin | Riwayat stock in/out, monitoring stok menipis |
| **Manajemen User** | Admin | Tambah/kelola akun kasir |
| **Pengaturan** | Admin | Info kedai, lokasi GPS, preferensi aplikasi |

---

## 🔐 Fitur Keamanan

### Row Level Security (RLS) — Supabase

Setiap tabel di Supabase dilindungi RLS. Kasir hanya bisa membaca produk dan menulis transaksi. Admin memiliki akses penuh. Semua policy terdefinisi di `run_all.sql`.

### Autentikasi Berlapis

- **Layer 1:** Login email + password via Supabase Auth (JWT-based).
- **Layer 2 (opsional):** Biometrik (fingerprint/face ID) via `local_auth` — tersedia di Android.

### Session Management

Session dikelola Supabase secara otomatis dengan refresh token. Jika token kadaluarsa, user diarahkan kembali ke halaman login.

### Validasi Upload Foto

Foto produk divalidasi tipe dan ukurannya sebelum diunggah ke Supabase Storage. Nama file di-generate secara unik (UUID) untuk mencegah konflik.

### Edge Function untuk Pembuatan User

Pembuatan akun kasir baru dilakukan melalui **Supabase Edge Function** (`create-user`) — bukan langsung dari client — agar kunci `service_role` tidak terekspos ke perangkat pengguna.

---

## 📡 Integrasi Sensor & Platform

| Package | Sensor / Fitur | Keterangan |
|---|---|---|
| `mobile_scanner` | 📷 Kamera + Barcode | Scan barcode/QR untuk identifikasi produk |
| `image_picker` | 📷 Kamera + Galeri | Ambil foto produk dari kamera atau galeri |
| `image_cropper` | ✂️ Crop Foto | Crop foto sebelum upload agar ukuran konsisten |
| `geolocator` | 📍 GPS | Deteksi & simpan koordinat lokasi kedai |
| `local_auth` | 🔒 Biometrik | Fingerprint/face ID untuk gate keamanan login |
| `shared_preferences` | 💾 Preferensi Lokal | Simpan pengaturan sesi & preferensi user |
| `webview_flutter` | 🗺️ WebView | Preview peta lokasi kedai (Android) |

> **Catatan:** Biometrik (`local_auth`) dan WebView peta tidak aktif/tidak optimal di platform web. Ini adalah perilaku normal.

---

## ⚙️ Panduan Supabase

### A. Setup Awal Project Supabase

1. Buka [supabase.com](https://supabase.com) dan buat project baru.
2. Catat **Project URL** dan **Anon Key** dari Settings → API.
3. Isi ke `assets/.env`.

### B. Menjalankan SQL Setup

Di **SQL Editor**, jalankan `supabase/run_all.sql`. Pastikan tidak ada error merah.

### C. Deploy Edge Function (create-user)

```bash
# Install Supabase CLI terlebih dahulu
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy create-user
```

### D. Konfigurasi Storage

Buat bucket `product-images` dengan akses **public** agar URL foto produk bisa diakses langsung.

### E. Konfigurasi Auth

Di **Authentication → Settings**:
- Pastikan **Email Auth** diaktifkan.
- Sesuaikan redirect URL jika diperlukan untuk web.

---

## 🧪 Akun Demo

| Role | Email | Password |
|---|---|---|
| 👑 **Admin** | `admin@bangjun.id` | *diberikan kepada pengembang* |
| 🧾 **Kasir** | `kasir@bangjun.id` | *diberikan kepada pengembang* |

> Akun demo hanya untuk keperluan presentasi & pengujian. Segera ganti password setelah selesai UAS.

---

## 🔧 Troubleshooting

### ❌ 1. Login Gagal / Error Auth

**Cek berikut:**
- File `assets/.env` sudah diisi dengan URL dan Key Supabase yang benar (tanpa trailing `/`).
- Supabase URL **jangan** diakhiri dengan `/rest/v1` — gunakan base URL saja.
- User sudah ditambahkan di **Authentication → Users** di Supabase Dashboard.
- `run_all.sql` sudah dijalankan di project Supabase yang sama.

---

### ❌ 2. Upload Foto Gagal — Error 404 Bucket

Bucket `product-images` belum dibuat. Buka **Supabase → Storage → New Bucket**, buat bucket dengan nama `product-images` dan aktifkan **Public**.

---

### ❌ 3. Error Biometrik di Platform Web

`local_auth` tidak didukung di platform web — ini **normal**. Fitur biometrik hanya aktif di Android/iOS.

---

### ❌ 4. WebView Peta Crash di Web / Desktop

WebView peta memang tidak didukung di web/desktop Flutter. Sudah ada **fallback UI** yang menampilkan informasi lokasi tanpa peta. Preview peta penuh disarankan di Android.

---

### ❌ 5. Stok Tidak Berkurang Setelah Transaksi

Pastikan `run_all.sql` sudah dijalankan lengkap — tabel `stock_movements` dan trigger terkait harus sudah ada. Cek juga policy RLS pada tabel `stock_movements` sudah mengizinkan kasir melakukan `INSERT`.

---

### ❌ 6. Flutter pub get Gagal

Pastikan Flutter SDK versi **>= 3.10** dan koneksi internet stabil. Jalankan:

```bash
flutter clean
flutter pub get
```

---

## 👥 Tim Pengembang

| Nama | NIM | Role |
|---|---|---|
| Sayid Rafi A'thaya | 2409116036 | 💡 Project Manager |
| Mochammad Rezky Ramadhan | 2409116029 | ⚙️ Backend / Supabase |
| Adella Putri | 2409116006 | 🎨 Frontend / UI |
| Dhita Olivia Ramadhayanti Kusuma | 2409116040 | 🧾 Dokumentasi |

---

## 📊 Sumber Daya Proyek

| Sumber Daya | Tautan |
|---|---|
| 📊 **Slide Presentasi** | [Lihat di Canva](https://canva.link/g10638pe91h9aws) |
| 💻 **Repository** | [github.com/bangjunspot/uas_pab](https://github.com/bangjunspot/uas_pab) |

---

<div align="center">

![Footer](https://capsule-render.vercel.app/api?type=waving&height=120&color=0:C2410C,100:F97316&section=footer)

**BANGJUN SPOT** &nbsp;·&nbsp; POS UMKM Kuliner Warung BangJun &nbsp;·&nbsp; Samarinda

[![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Powered_by-Supabase-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com/)
[![UAS](https://img.shields.io/badge/Project-UAS%20PAB-F97316?style=flat-square)](#)

</div>
