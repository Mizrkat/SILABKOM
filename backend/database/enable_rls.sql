-- ==============================================================================
-- PENGAKTIFAN ROW LEVEL SECURITY (RLS) DENGAN KEBIJAKAN (POLICIES) LENGKAP
-- SISTEM MANAJEMEN INVENTARIS & PEMINJAMAN LAB SISTEM KOMPUTER UNDIP
-- ==============================================================================

-- 1. Pastikan kolom pendukung terbaru sudah ada
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS return_photo TEXT;
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. Perbarui batasan status loans agar mendukung status 'returning'
ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS loans_status_check;
ALTER TABLE public.loans ADD CONSTRAINT loans_status_check CHECK (status IN ('pending', 'approved', 'returning', 'rejected', 'returned'));

-- 3. AKTIFKAN ROW LEVEL SECURITY (RLS) PADA SEMUA TABEL
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.components ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;

-- 4. Hapus policy lama jika ada untuk mencegah duplikasi
DROP POLICY IF EXISTS "Allow all for users" ON public.users;
DROP POLICY IF EXISTS "Allow all for components" ON public.components;
DROP POLICY IF EXISTS "Allow all for loans" ON public.loans;

-- 5. Buat Policy Universal untuk anon dan authenticated
-- Mengizinkan API Gateway Express.js (menggunakan anon key maupun service_role key)
-- untuk membaca (SELECT), menambah (INSERT), mengubah (UPDATE), dan menghapus (DELETE) data
-- dengan status RLS TETAP AKTIF (ENABLED) di Supabase.

CREATE POLICY "Allow all for users"
ON public.users
FOR ALL
TO anon, authenticated, service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all for components"
ON public.components
FOR ALL
TO anon, authenticated, service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all for loans"
ON public.loans
FOR ALL
TO anon, authenticated, service_role
USING (true)
WITH CHECK (true);

-- 6. Berikan Hak Akses Grants
GRANT ALL ON TABLE public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.components TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.loans TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 7. Verifikasi Status RLS di Supabase
SELECT tablename, rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' AND tablename IN ('users', 'components', 'loans');
