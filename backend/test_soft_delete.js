const dbService = require('./src/config/db');

async function testSoftDelete() {
  console.log('=== TEST FITUR SOFT DELETE & RESTORE MODUL & PINJAMAN ===');

  // 1. Ambil Mahasiswa
  const student = await dbService.getUserByNim('21120124120017');
  console.log('1. Mahasiswa:', student.name);

  // 2. Buat Modul Baru
  const comp = await dbService.createComponent({
    name: 'Modul Raspberry Pi 4 Model B (Test Soft Delete)',
    category: 'Mikrokontroler',
    stock: 2,
    location: 'Loker Pi-01',
    description: 'SBC 64-bit quad-core ARM Cortex-A72'
  });
  console.log('2. Komponen dibuat. ID:', comp.id, 'Nama:', comp.name, 'Stok:', comp.stock);

  // 3. Mahasiswa Pinjam (Stok jadi 1)
  const loan = await dbService.createLoan({
    user_id: student.id,
    component_id: comp.id,
    borrow_date: '2026-11-20',
    return_date: '2026-11-27',
    reason: 'Uji fitur soft delete'
  });
  console.log('3. Pinjaman dibuat. ID:', loan.id, 'Status:', loan.status);

  // 4. SOFT DELETE PINJAMAN
  console.log('\n--- 4. Uji Soft Delete Pinjaman ---');
  const deletedLoan = await dbService.deleteLoan(loan.id);
  console.log('   Pinjaman berhasil di-soft-delete:', deletedLoan.id);

  // Cek apakah pinjaman hilang dari antrean aktif
  const activeLoans = await dbService.getLoans(null, 'Semua', false);
  const findInActiveLoans = activeLoans.find(l => l.id === loan.id);
  console.log('   Ditemukan di antrean aktif?:', Boolean(findInActiveLoans), '(Harus FALSE)');
  if (findInActiveLoans) {
    throw new Error('Pinjaman yang sudah di-soft-delete tidak boleh muncul di antrean aktif!');
  }

  // Cek stok alat (harus otomatis dikembalikan jadi 2)
  const compAfterLoanSoftDelete = await dbService.getComponentById(comp.id);
  console.log('   Stok alat setelah permohonan di-soft-delete:', compAfterLoanSoftDelete.stock, '(Harus kembali 2)');
  if (compAfterLoanSoftDelete.stock !== 2) {
    throw new Error('Stok alat harus kembali 2 setelah permohonan di-soft-delete!');
  }

  // 5. RESTORE PINJAMAN
  console.log('\n--- 5. Uji Restore Pinjaman ---');
  const restoredLoan = await dbService.restoreLoan(loan.id);
  console.log('   Pinjaman berhasil di-restore:', restoredLoan.id);

  const activeLoansAfterRestore = await dbService.getLoans(null, 'Semua', false);
  const findInActiveAfterRestore = activeLoansAfterRestore.find(l => l.id === loan.id);
  console.log('   Ditemukan di antrean aktif setelah restore?:', Boolean(findInActiveAfterRestore), '(Harus TRUE)');
  if (!findInActiveAfterRestore) {
    throw new Error('Pinjaman yang di-restore harus muncul kembali di antrean aktif!');
  }

  // Cek stok alat (harus ter-booking kembali jadi 1)
  const compAfterLoanRestore = await dbService.getComponentById(comp.id);
  console.log('   Stok alat setelah permohonan di-restore:', compAfterLoanRestore.stock, '(Harus kembali 1)');
  if (compAfterLoanRestore.stock !== 1) {
    throw new Error('Stok alat harus ter-booking kembali menjadi 1 setelah permohonan di-restore!');
  }

  // 6. SOFT DELETE MODUL KOMPONEN
  console.log('\n--- 6. Uji Soft Delete Modul ---');
  const deletedComp = await dbService.deleteComponent(comp.id);
  console.log('   Modul berhasil di-soft-delete:', deletedComp.id);

  const activeComponents = await dbService.getComponents('', 'Semua', false);
  const findInActiveComp = activeComponents.find(c => c.id === comp.id);
  console.log('   Modul ditemukan di katalog aktif?:', Boolean(findInActiveComp), '(Harus FALSE)');
  if (findInActiveComp) {
    throw new Error('Modul yang di-soft-delete tidak boleh muncul di katalog aktif!');
  }

  // 7. RESTORE MODUL KOMPONEN
  console.log('\n--- 7. Uji Restore Modul ---');
  const restoredComp = await dbService.restoreComponent(comp.id);
  console.log('   Modul berhasil di-restore:', restoredComp.id);

  const activeCompAfterRestore = await dbService.getComponents('', 'Semua', false);
  const findInActiveCompAfterRestore = activeCompAfterRestore.find(c => c.id === comp.id);
  console.log('   Modul ditemukan di katalog aktif setelah restore?:', Boolean(findInActiveCompAfterRestore), '(Harus TRUE)');
  if (!findInActiveCompAfterRestore) {
    throw new Error('Modul yang di-restore harus muncul kembali di katalog aktif!');
  }

  // 8. Bersihkan data pengujian
  if (dbService.supabase) {
    await dbService.supabase.from('loans').delete().eq('id', loan.id);
    await dbService.supabase.from('components').delete().eq('id', comp.id);
  }
  console.log('\n8. Data pengujian dibersihkan.');
  console.log('\n🎉 SEMUA FITUR SOFT DELETE & RESTORE BERHASIL 100%!');
  process.exit(0);
}

testSoftDelete().catch(err => {
  console.error('Test gagal:', err);
  process.exit(1);
});
