-- ==============================================================================
-- MIGRATION: Menambahkan Kolom Avatar pada Tabel Users
-- Jalankan di SQL Editor Supabase jika menggunakan Supabase remote
-- ==============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar TEXT;

COMMENT ON COLUMN users.avatar IS 'Foto profil pengguna dalam format Base64 data URI atau URL gambar';
