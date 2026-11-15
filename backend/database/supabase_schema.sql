-- ==============================================================================
-- SKRIP SQL SUPABASE EDITOR (COPY-PASTE READY)
-- PROYEK: SISTEM MANAJEMEN INVENTARIS & PEMINJAMAN LAB SISTEM KOMPUTER UNDIP
-- PRAKTIKUM PEMROGRAMAN PERANGKAT BERGERAK (PPB) 2026
-- ==============================================================================

-- 1. Aktifkan ekstensi pgcrypto untuk fungsi gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Bersihkan tabel lama jika sudah ada (Cascade untuk menghapus relasi Foreign Key)
DROP TABLE IF EXISTS public.loans CASCADE;
DROP TABLE IF EXISTS public.components CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ==============================================================================
-- 3. PEMBUATAN TABEL
-- ==============================================================================

-- Tabel Users: Akun Mahasiswa & Asisten Laboratorium
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    nim_nip VARCHAR(30) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'assistant')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel Components: Katalog Modul Hardware, Sensor & Alat Laboratorium
CREATE TABLE public.components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    location VARCHAR(80) NOT NULL,
    description TEXT,
    datasheet_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabel Loans: Antrean & Riwayat Permohonan Peminjaman Modul Lab
CREATE TABLE public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    component_id UUID NOT NULL,
    borrow_date DATE NOT NULL,
    return_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'returning', 'rejected', 'returned')),
    notes TEXT,
    return_photo TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_loans_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_loans_component FOREIGN KEY (component_id) REFERENCES public.components(id) ON DELETE RESTRICT
);

-- ==============================================================================
-- 4. PENGATURAN HAK AKSES & ROW LEVEL SECURITY (RLS)
-- RLS diaktifkan (ENABLED) dengan Policy Universal untuk anon dan authenticated
-- agar API Gateway Express.js dapat beroperasi dengan aman dan lancar.
-- ==============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.components ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all for users" ON public.users;
DROP POLICY IF EXISTS "Allow all for components" ON public.components;
DROP POLICY IF EXISTS "Allow all for loans" ON public.loans;

CREATE POLICY "Allow all for users" ON public.users FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for components" ON public.components FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for loans" ON public.loans FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);

GRANT ALL ON TABLE public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.components TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.loans TO postgres, anon, authenticated, service_role;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- ==============================================================================
-- 5. SEED DATA AWAL (DUMMY DATA RESPONSI)
-- ==============================================================================

-- A. Akun Pengguna
INSERT INTO public.users (id, name, nim_nip, password, role) VALUES
('a0000000-0000-0000-0000-000000000001', 'Radhine Muhammad Rossie', '21120124120017', 'mahasiswa123', 'student'),
('a0000000-0000-0000-0000-000000000002', 'Asisten Lab Sistem Komputer', '199801012023011001', 'asisten123', 'assistant');

-- B. Katalog Modul Lab Siskom UNDIP
INSERT INTO public.components (id, name, category, stock, location, description, datasheet_url) VALUES
(
    'c0000000-0000-0000-0000-000000000001',
    'ESP32 WROOM-32 DevKit V1',
    'Mikrokontroler',
    15,
    'Loker A-01',
    'Modul pengembangan berbasis SoC ESP32 dual-core Tensilica Xtensa 32-bit LX6 dengan konektivitas Wi-Fi 802.11 b/g/n dan Bluetooth v4.2 BR/EDR & BLE.',
    'https://www.espressif.com/sites/default/files/documentation/esp32-wroom-32_datasheet_en.pdf'
),
(
    'c0000000-0000-0000-0000-000000000002',
    'Arduino Uno R3 Atmega328P',
    'Mikrokontroler',
    8,
    'Loker A-02',
    'Board mikrokontroler standar industri berbasis ATmega328P dengan 14 pin I/O digital, 6 input analog, clock speed 16 MHz osilator kristal keramik.',
    'https://docs.arduino.cc/resources/datasheets/A000066-datasheet.pdf'
),
(
    'c0000000-0000-0000-0000-000000000003',
    'STM32 Blue Pill ARM Cortex-M3',
    'Mikrokontroler',
    5,
    'Loker A-03',
    'Development board hemat daya dengan core 32-bit ARM Cortex-M3 (STM32F103C8T6), kecepatan 72 MHz, 64KB Flash, 20KB SRAM, USB interface dan CAN controller.',
    'https://www.st.com/resource/en/datasheet/stm32f103c8.pdf'
),
(
    'c0000000-0000-0000-0000-000000000004',
    '24MHz 8-Channel USB Logic Analyzer',
    'Alat Ukur & Debugger',
    4,
    'Rak B-01',
    'Alat penganalisis sinyal digital 8 kanal dengan frekuensi sampling hingga 24MHz. Kompatibel dengan Saleae Logic Software untuk protokol I2C, SPI, UART, CAN.',
    'https://sigrok.org/wiki/Saleae_Logic'
),
(
    'c0000000-0000-0000-0000-000000000005',
    'MPU6050 6-DOF Gyroscope & Accelerometer',
    'Sensor & Modul',
    20,
    'Box C-04',
    'Sensor gerak terintegrasi 6-sumbu memadukan 3-axis gyroscope dan 3-axis accelerometer dengan Digital Motion Processor (DMP) internal berbasis antarmuka I2C.',
    'https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Datasheet1.pdf'
),
(
    'c0000000-0000-0000-0000-000000000006',
    'Altera Cyclone IV FPGA EP4CE6 Starter Kit',
    'FPGA & IC',
    3,
    'Lemari Utama',
    'Kit pembelajaran komputasi rekonfigurasi FPGA Altera Cyclone IV EP4CE6E22C8N dengan 6,272 Logic Elements, onboard SDRAM, VGA port, dan JTAG programmer.',
    'https://www.intel.com/content/www/us/en/docs/programmable/683610/current/cyclone-iv-device-handbook.html'
);

-- C. Sampel Peminjaman Awal
INSERT INTO public.loans (id, user_id, component_id, borrow_date, return_date, reason, status, notes) VALUES
(
    'e0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'Pengerjaan proyek mata kuliah Praktikum Sistem Tertanam dan IoT',
    'approved',
    'Disetujui. Harap jaga modul dengan baik dan kembalikan tepat waktu.'
),
(
    'e0000000-0000-0000-0000-000000000002',
    'a0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000004',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '3 days',
    'Analisis sinyal debugging komunikasi serial I2C bus sensor gyroscope',
    'pending',
    NULL
);

-- Verifikasi data yang baru saja dimasukkan
SELECT 'users' AS table_name, count(*) AS total_rows FROM public.users
UNION ALL
SELECT 'components', count(*) FROM public.components
UNION ALL
SELECT 'loans', count(*) FROM public.loans;
