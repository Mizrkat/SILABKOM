# SILABKOM — Sistem Informasi Laboratorium Teknik Komputer Universitas Diponegoro

> **Tugas Akhir Praktikum Pemrograman Perangkat Bergerak (PPB) - Semester 5 Teknik Komputer UNDIP**  
> **Platform:** Flutter Mobile (Android) + Node.js Express.js RESTful API + Supabase / PostgreSQL  
> **Target Pengujian & Responsi:** 25 – 28 November 2026

---

## 🏛️ 1. Gambaran Umum Proyek
**SILABKOM** (*Sistem Informasi Laboratorium Teknik Komputer Universitas Diponegoro*) adalah aplikasi mobile yang dikembangkan untuk mendigitalisasi pengelolaan sirkulasi perangkat keras, modul mikrokontroler, kit sensor, alat ukur digital, dan board FPGA pada **Laboratorium Sistem Komputer, Departemen Teknik Komputer, Universitas Diponegoro**.

Dengan sistem **Role-Based Access Control (RBAC)**:
- **Mahasiswa (`student`)**: Dapat menelusuri katalog komponen lab lengkap dengan status stok dan lokasi rak/loker, mencari modul berdasarkan kategori/kata kunci, mengajukan permohonan pinjam alat, serta memantau status persetujuan permohonan secara *real-time*.
- **Asisten Laboratorium (`assistant`)**: Memiliki wewenang manajemen inventaris (menambahkan modul/alat baru ke katalog, menyesuaikan stok fisik) serta meninjau seluruh antrean permohonan pinjam masuk untuk melakukan persetujuan (*approve*) atau penolakan (*reject*).

---

## 🌟 2. Pemenuhan Ketentuan Praktikum & Nilai Tambah

| Ketentuan Praktikum PPB | Syarat Minimal | Realisasi Proyek | Status |
| :--- | :--- | :--- | :---: |
| **RESTful API Mandiri** | Buatan sendiri (standar Modul 1) | Express.js + Supabase / PostgreSQL REST API | ✅ Terpenuhi |
| **Navigasi Utama** | Bottom Navigation Bar | Material 3 NavigationBar (3 Tab interaktif) | ✅ Terpenuhi |
| **Jumlah Halaman** | Minimal 5 Halaman | **6 Halaman Fungsional Lengkap** | 🌟 Melampaui |
| **Pasang List - Detail** | Minimal 2 Pasang | **Pasang 1 (Komponen)** & **Pasang 2 (Peminjaman)** | ✅ Terpenuhi |
| **Halaman Profil / About** | 1 Halaman Profil | Info Akun, Profil Lab Sisfo UNDIP, Config IP | ✅ Terpenuhi |
| **Role-Based Access Control** | Mahasiswa & Asisten | Antarmuka dinamis berbasis role pengguna | 🌟 Poin Plus |
| **Build Mandiri APK** | Bonus nilai rilis | `flutter build apk --release` siap pasang | 🌟 Nilai Tambah |

---

## 📱 3. Struktur 6 Halaman Antarmuka (UI/UX)
1. **`LoginScreen`**: Autentikasi NIM/NIP & Password, validasi error, serta **Pintasan Uji Akun Responsi** (`[Login Mahasiswa]` dan `[Login Asisten]`) untuk pengujian instan.
2. **`MainNavigationScreen`**: Bottom Navigation Bar 3 Tab (Katalog Modul, Peminjaman / Antrean, Profil Lab).
3. **`ComponentListScreen` (List 1)**: Katalog alat dengan pencarian teks, filter chips kategori, badge status stok, dan tombol FAB `+ Tambah Modul` (khusus asisten).
4. **`ComponentDetailScreen` (Detail 1)**: Visualisasi header modul, lokasi rak fisik, deskripsi, tautan datasheet, formulir modal pengajuan pinjam (khusus mahasiswa), serta edit stok (khusus asisten).
5. **`BorrowRequestScreen` (List 2)**: Antrean & riwayat pinjam dengan filter status (Semua, Menunggu, Disetujui, Ditolak). Menampilkan riwayat personal bagi mahasiswa dan seluruh antrean bagi asisten lab.
6. **`BorrowDetailScreen` (Detail 2)**: Rincian pemohon, komponen, rentang tanggal, alasan peminjaman, serta aksi **[Setujui Pinjam]** dan **[Tolak Permohonan]** dengan catatan penolakan (khusus asisten).
7. **`ProfileScreen` (Halaman Profile / About)**: Identitas akun, badge role, profil Laboratorium Sistem Komputer UNDIP, informasi tugas akhir, konfigurasi dinamis IP API server, dan tombol Logout.

---

## 📂 4. Struktur Direktori Proyek
```text
Tugas Akhir_PPB/
├── backend/
│   ├── database/
│   │   └── schema.sql              # Skema PostgreSQL & seed data awal
│   ├── src/
│   │   ├── config/
│   │   │   └── db.js               # Service adapter Supabase & fallback local DB
│   │   ├── controllers/
│   │   │   ├── authController.js   # Autentikasi & login
│   │   │   ├── componentController.js # CRUD katalog inventaris lab
│   │   │   └── loanController.js   # Sirkulasi & approval permohonan pinjam
│   │   ├── routes/
│   │   │   ├── authRoutes.js
│   │   │   ├── componentRoutes.js
│   │   │   └── loanRoutes.js
│   │   └── server.js               # Express entrypoint (0.0.0.0:3000)
│   ├── .env.example
│   ├── package.json
│   └── test_api.js                 # Skrip integrasi otomatis backend
│
└── frontend/
    ├── android/                    # Android project & manifest (INTERNET permission)
    ├── lib/
    │   ├── core/
    │   │   ├── constants/
    │   │   │   ├── api_endpoints.dart # Endpoint mapping & dynamic host
    │   │   │   └── app_colors.dart    # Tech Blue UNDIP palette
    │   │   ├── network/
    │   │   │   └── api_client.dart    # HTTP client dengan timeout & error handling
    │   │   └── utils/
    │   │       └── session_manager.dart # SharedPreferences session helper
    │   ├── models/
    │   │   ├── user_model.dart
    │   │   ├── component_model.dart
    │   │   └── loan_model.dart
    │   ├── screens/
    │   │   ├── auth/login_screen.dart
    │   │   ├── navigation/main_navigation_screen.dart
    │   │   ├── components/
    │   │   │   ├── component_list_screen.dart   (Tab 1 - List 1)
    │   │   │   ├── component_detail_screen.dart (Detail 1)
    │   │   │   └── add_component_screen.dart    (Form Tambah Modul)
    │   │   ├── loans/
    │   │   │   ├── borrow_request_screen.dart   (Tab 2 - List 2)
    │   │   │   └── borrow_detail_screen.dart    (Detail 2)
    │   │   └── profile/profile_screen.dart      (Tab 3 - Profile & About)
    │   └── main.dart
    └── pubspec.yaml
```

---

## 🔑 5. Akun Pengujian Responsi (Seed Data)
| Role | NIM / NIP | Password | Keterangan |
| :--- | :--- | :--- | :--- |
| **Mahasiswa** | `21120124120017` | `mahasiswa123` | Radhine Muhammad Rossie |
| **Asisten Lab** | `199801012023011001` | `asisten123` | Asisten Lab Sistem Komputer |

*(Tersedia tombol pintasan klik di halaman Login untuk langsung mengisi kredensial secara otomatis)*

---

## 🚀 6. Panduan Menjalankan Sistem

### A. Menjalankan Backend API
1. Buka terminal pada folder `backend`:
   ```bash
   cd backend
   npm install
   npm start
   ```
2. Server akan aktif di port `3000` (`http://localhost:3000` atau `http://10.0.2.2:3000` untuk emulator).
3. Untuk menguji seluruh endpoint secara otomatis:
   ```bash
   node test_api.js
   ```

*(Opsional: Jika menggunakan remote database Supabase, cukup masukkan `SUPABASE_URL` dan `SUPABASE_KEY` pada file `backend/.env`. Jika dikosongkan, backend otomatis berjalan menggunakan database lokal siap pakai dengan data seed lengkap tanpa membutuhkan internet).*

### B. Menjalankan Frontend Flutter
1. Buka terminal pada folder `frontend`:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
2. **Konektivitas Jaringan**:
   - Jika dijalankan di **Android Emulator**: Aplikasi otomatis terhubung ke `http://10.0.2.2:3000`.
   - Jika dijalankan di **Smartphone Android Fisik**: Buka menu Tab Profil -> klik **"Ganti URL"** -> masukkan IP Wi-Fi komputer Anda (misal `http://192.168.1.15:3000`).

---

## 📦 7. Panduan Build Release APK
Untuk menghasilkan file installer `.apk` mandiri yang siap diinstal di HP Android:

```bash
cd frontend
flutter build apk --release
```

Lokasi file output release APK:
```text
frontend/build/app/outputs/flutter-apk/app-release.apk
```
File ini siap dikumpulkan pada form tugas akhir atau di-upload ke GitHub Releases.
