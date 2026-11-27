-- ==============================================================================
-- MIGRATION: Menambahkan Kolom Gambar (image) pada Tabel Components
-- Jalankan di SQL Editor Supabase jika menggunakan Supabase remote
-- ==============================================================================

ALTER TABLE components ADD COLUMN IF NOT EXISTS image TEXT;

COMMENT ON COLUMN components.image IS 'Gambar komponen/modul dalam format Base64 data URI atau URL gambar';
