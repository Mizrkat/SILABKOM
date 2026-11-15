const dbService = require('./src/config/db');

async function testDeleteFeatures() {
  console.log('=== TEST FITUR DELETE MODUL & DELETE PERMOHONAN PINJAM ===');

  // 1. Ambil user mahasiswa
  const student = await dbService.getUserByNim('21120124120017');
  console.log('1. Mahasiswa:', student.name);

  // 2. Buat komponen baru dengan stok 3
  const comp = await dbService.createComponent({
    name: 'Modul Test Delete Feature',
    category: 'Sensor & Modul',
    stock: 3,
    location: 'Loker Test-Del',
    description: 'Untuk menguji fitur hapus modul dan hapus peminjaman'
  });
  console.log('2. Komponen dibuat. ID:', comp.id, 'Stok awal:', comp.stock);

  // 3. Mahasiswa mengajukan peminjaman (stok berkurang jadi 2)
  const loan = await dbService.createLoan({
    user_id: student.id,
    component_id: comp.id,
    borrow_date: '2026-11-20',
    return_date: '2026-11-27',
    reason: 'Uji hapus peminjaman'
  });
  console.log('3. Permohonan dibuat. ID:', loan.id, 'Status:', loan.status);

  const compAfterApply = await dbService.getComponentById(comp.id);
  console.log('   Stok setelah peminjaman diajukan:', compAfterApply.stock, '(Harus 2)');
  if (compAfterApply.stock !== 2) {
    throw new Error('Stok harus 2!');
  }

  // 4. Hapus permohonan pinjam (Fitur Asisten: deleteLoan)
  // Stok harus otomatis dikembalikan menjadi 3
  const deletedLoan = await dbService.deleteLoan(loan.id);
  console.log('4. Permohonan pinjam berhasil dihapus:', deletedLoan.id);

  const compAfterLoanDelete = await dbService.getComponentById(comp.id);
  console.log('   Stok setelah permohonan dihapus:', compAfterLoanDelete.stock, '(Harus kembali 3)');
  if (compAfterLoanDelete.stock !== 3) {
    throw new Error('Stok harus kembali menjadi 3 setelah permohonan dibatalkan/dihapus!');
  }

  // 5. Hapus modul (Fitur Asisten: deleteComponent)
  const deletedComp = await dbService.deleteComponent(comp.id);
  console.log('5. Modul berhasil dihapus dari katalog:', deletedComp.id);

  const compCheck = await dbService.getComponentById(comp.id);
  if (compCheck) {
    throw new Error('Komponen masih ditemukan padahal sudah dihapus!');
  }
  console.log('   ✅ Komponen sudah benar-benar terhapus dari database.');

  console.log('\n🎉 SEMUA PENGUJIAN FITUR DELETE BERHASIL 100%!');
  process.exit(0);
}

testDeleteFeatures().catch(err => {
  console.error('Test gagal:', err);
  process.exit(1);
});
