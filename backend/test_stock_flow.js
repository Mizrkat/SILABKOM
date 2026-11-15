const dbService = require('./src/config/db');

async function testFullApprovalFlow() {
  console.log('=== TEST PERBAIKAN BUG: ACC PERMOHONAN STOK 1 -> 0 ===');

  // 1. Ambil akun mahasiswa
  const student = await dbService.getUserByNim('21120124120017');
  console.log('1. Mahasiswa:', student.name);

  // 2. Buat komponen baru dengan stok = 1 (seperti skenario modul baru "bom" dari asprak)
  const comp = await dbService.createComponent({
    name: 'Modul ESP8266 ESP-01 Uji ACC',
    category: 'Mikrokontroler',
    stock: 1,
    location: 'Loker Uji-A1',
    description: 'Pengujian persetujuan asprak saat stok sudah terpotong menjadi 0'
  });
  console.log('2. Modul dibuat. Nama:', comp.name, 'Stok:', comp.stock);

  // 3. Mahasiswa mengajukan permohonan pinjam (Stok 1 -> 0)
  const loan = await dbService.createLoan({
    user_id: student.id,
    component_id: comp.id,
    borrow_date: '2026-11-20',
    return_date: '2026-11-25',
    reason: 'Uji coba ACC permohonan'
  });
  console.log('3. Mahasiswa berhasil mengajukan. ID Pinjam:', loan.id, 'Status:', loan.status);

  // Cek stok komponen di DB (seharusnya 0 karena ter-booking oleh mahasiswa ini)
  const compAfterApply = await dbService.getComponentById(comp.id);
  console.log('   Stok barang saat ini di katalog:', compAfterApply.stock, '(Ter-booking/Reserved = 0)');

  // 4. Asisten Praktikum MENYETUJUI (ACC) permohonan ini
  // SEBELUMNYA: Ini error 'Stok alat sudah habis (0). Permohonan tidak dapat disetujui.'
  // SEKARANG: Harus BERHASIL disetujui!
  const approvedLoan = await dbService.updateLoanStatus(
    loan.id,
    'approved',
    'Disetujui oleh asisten praktikum.'
  );
  console.log('4. HASIL ACC ASISTEN:', approvedLoan.status, '- CATATAN:', approvedLoan.notes);
  if (approvedLoan.status !== 'approved') {
    console.error('❌ BUG MASIH ADA: Status bukan approved!');
    process.exit(1);
  }
  console.log('   ✅ Asisten Praktikum BERHASIL menyetujui permohonan meskipun stok di katalog 0!');

  // 5. Mahasiswa mengembalikan barang & Asprak konfirmasi returned
  const returnedLoan = await dbService.updateLoanStatus(
    loan.id,
    'returned',
    'Barang telah diterima kembali di lab.'
  );
  console.log('5. Status setelah dikembalikan:', returnedLoan.status);

  // Cek stok komponen setelah dikembalikan (harus kembali 1)
  const compAfterReturn = await dbService.getComponentById(comp.id);
  console.log('   Stok barang setelah dikembalikan:', compAfterReturn.stock, '(Harus kembali 1)');
  if (compAfterReturn.stock !== 1) {
    console.error('❌ BUG: Stok tidak bertambah kembali menjadi 1!');
    process.exit(1);
  }

  // 6. Bersihkan data uji
  if (dbService.supabase) {
    await dbService.supabase.from('loans').delete().eq('id', loan.id);
  }
  await dbService.deleteComponent(comp.id);
  console.log('6. Data uji berhasil dibersihkan.');

  console.log('\n🎉 SEMUA PENGUJIAN ALUR ACC ASISTEN PRAKTIKUM SUKSES 100%!');
  process.exit(0);
}

testFullApprovalFlow().catch(err => {
  console.error('Test gagal:', err);
  process.exit(1);
});
