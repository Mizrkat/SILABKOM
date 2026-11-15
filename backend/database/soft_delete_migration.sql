-- ==============================================================================
-- SKRIP MIGRASI SOFT DELETE LAB SISTEM KOMPUTER UNDIP
-- Jalankan skrip ini di: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Tambahkan kolom is_deleted dan deleted_at pada tabel components
ALTER TABLE components 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT null;

-- 2. Tambahkan kolom is_deleted dan deleted_at pada tabel loans
ALTER TABLE loans 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT null;

-- 3. Pastikan data yang sudah ada memiliki nilai default is_deleted = false
UPDATE components SET is_deleted = false WHERE is_deleted IS NULL;
UPDATE loans SET is_deleted = false WHERE is_deleted IS NULL;

-- 4. Buat index untuk optimasi performa query filter
CREATE INDEX IF NOT EXISTS idx_components_is_deleted ON components(is_deleted);
CREATE INDEX IF NOT EXISTS idx_loans_is_deleted ON loans(is_deleted);

-- ==============================================================================
-- SELESAI: Skema tabel components dan loans kini mendukung fitur Soft Delete & Restore
-- ==============================================================================
