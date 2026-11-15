-- ==============================================================================
-- SISTEM MANAJEMEN INVENTARIS & PEMINJAMAN KOMPONEN LAB SISTEM KOMPUTER UNDIP
-- SKEMA DATABASE POSTGRESQL / SUPABASE
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing tables if needed (cascade to drop foreign keys)
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS components CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Tabel Users (Mahasiswa & Asisten Laboratorium)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    nim_nip VARCHAR(30) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'assistant')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel Components (Katalog Modul & Alat Lab)
CREATE TABLE components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    location VARCHAR(80) NOT NULL,
    description TEXT,
    datasheet_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabel Loans (Permohonan & Sirkulasi Peminjaman)
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    component_id UUID NOT NULL REFERENCES components(id) ON DELETE RESTRICT,
    borrow_date DATE NOT NULL,
    return_date DATE NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'returned')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- SEED DATA AWAL (DUMMY DATA UNTUK PENGUJIAN RESPONSI)
-- ==============================================================================

-- Insert Users (Mahasiswa & Asisten)
INSERT INTO users (id, name, nim_nip, password, role) VALUES
('a0000000-0000-0000-0000-000000000001', 'Radhine Muhammad Rossie', '21120124120017', 'mahasiswa123', 'student'),
('a0000000-0000-0000-0000-000000000002', 'Asisten Lab Sistem Komputer', '199801012023011001', 'asisten123', 'assistant');

-- Insert Components (Katalog Modul Hardware Lab Sisfo / Siskom UNDIP)
INSERT INTO components (id, name, category, stock, location, description, datasheet_url) VALUES
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

-- Insert Sample Initial Loans
INSERT INTO loans (id, user_id, component_id, borrow_date, return_date, reason, status, notes) VALUES
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
