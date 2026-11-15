const dbService = require('../config/db');

/**
 * Mendapatkan daftar permohonan peminjaman
 * GET /api/loans?user_id=...&status=...
 * Mahasiswa: filter dengan user_id miliknya
 * Asisten: tanpa user_id untuk melihat seluruh antrean
 */
exports.getAllLoans = async (req, res) => {
  try {
    const { user_id, status, is_deleted } = req.query;
    const loans = await dbService.getLoans(user_id, status, is_deleted);

    return res.status(200).json({
      status: 'success',
      total: loans.length,
      data: loans
    });
  } catch (error) {
    console.error('Error get loans:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal mengambil riwayat atau antrean peminjaman.',
      error: error.message
    });
  }
};

/**
 * Mendapatkan detail satu permohonan peminjaman
 * GET /api/loans/:id
 */
exports.getLoanById = async (req, res) => {
  try {
    const { id } = req.params;
    const loan = await dbService.getLoanById(id);

    if (!loan) {
      return res.status(404).json({
        status: 'fail',
        message: `Permohonan pinjam dengan ID ${id} tidak ditemukan.`
      });
    }

    return res.status(200).json({
      status: 'success',
      data: loan
    });
  } catch (error) {
    console.error('Error get loan by id:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal mengambil rincian peminjaman.',
      error: error.message
    });
  }
};

/**
 * Mengajukan permohonan peminjaman baru (Fitur Khusus Mahasiswa)
 * POST /api/loans
 * Body: { user_id, component_id, borrow_date, return_date, reason }
 */
exports.createLoan = async (req, res) => {
  try {
    const { user_id, component_id, borrow_date, return_date, reason } = req.body;

    if (!user_id || !component_id || !borrow_date || !return_date || !reason) {
      return res.status(400).json({
        status: 'fail',
        message: 'Field user_id, component_id, borrow_date, return_date, dan reason wajib diisi.'
      });
    }

    // Pastikan komponen yang dipinjam tersedia
    const component = await dbService.getComponentById(component_id);
    if (!component) {
      return res.status(404).json({
        status: 'fail',
        message: 'Komponen yang dipilih tidak ditemukan dalam katalog.'
      });
    }

    if (component.stock <= 0) {
      return res.status(400).json({
        status: 'fail',
        message: 'Stok komponen ini sedang habis. Tidak dapat mengajukan peminjaman saat ini.'
      });
    }

    const newLoan = await dbService.createLoan({
      user_id,
      component_id,
      borrow_date,
      return_date,
      reason
    });

    return res.status(201).json({
      status: 'success',
      message: 'Permohonan peminjaman berhasil dikirim. Menunggu persetujuan asisten lab.',
      data: newLoan
    });
  } catch (error) {
    console.error('Error create loan:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal mengajukan peminjaman.',
      error: error.message
    });
  }
};

/**
 * Menyetujui atau menolak permohonan peminjaman (Fitur Khusus Asisten)
 * PATCH /api/loans/:id/status
 * Body: { status: 'approved' | 'rejected', notes: '...' }
 */
exports.updateLoanStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, return_photo } = req.body;

    const allowedStatuses = ['approved', 'rejected', 'returning', 'returned', 'pending'];
    if (!status || !allowedStatuses.includes(status.toLowerCase())) {
      return res.status(400).json({
        status: 'fail',
        message: "Status tidak valid. Pilihan status yang diterima: 'approved', 'rejected', 'returning', 'returned', 'pending'."
      });
    }

    const existingLoan = await dbService.getLoanById(id);
    if (!existingLoan) {
      return res.status(404).json({
        status: 'fail',
        message: `Permohonan pinjam dengan ID ${id} tidak ditemukan.`
      });
    }

    const updatedLoan = await dbService.updateLoanStatus(
      id,
      status.toLowerCase(),
      notes !== undefined ? notes : existingLoan.notes,
      return_photo
    );

    let statusLabel = status;
    switch (status.toLowerCase()) {
      case 'approved':
        statusLabel = 'Disetujui';
        break;
      case 'rejected':
        statusLabel = 'Ditolak';
        break;
      case 'returning':
        statusLabel = 'Menunggu Konfirmasi Pengembalian';
        break;
      case 'returned':
        statusLabel = 'Telah Dikembalikan';
        break;
      case 'pending':
        statusLabel = 'Menunggu Persetujuan';
        break;
    }

    return res.status(200).json({
      status: 'success',
      message: `Permohonan peminjaman berhasil diperbarui menjadi: ${statusLabel}.`,
      data: updatedLoan
    });
  } catch (error) {
    console.error('Error update loan status:', error);
    if (error.code === '23514') {
      return res.status(400).json({
        status: 'fail',
        message: 'Kolom status di Supabase belum mengizinkan status returning. Silakan jalankan skrip pembaruan SQL di Supabase SQL Editor.',
        error: error.message
      });
    }
    return res.status(500).json({
      status: 'error',
      message: 'Gagal memperbarui status permohonan pinjam.',
      error: error.message
    });
  }
};

/**
 * Menghapus data permohonan peminjaman (Fitur Khusus Asisten - Soft Delete / Hard Delete)
 * DELETE /api/loans/:id?hard=true
 */
exports.deleteLoan = async (req, res) => {
  try {
    const { id } = req.params;
    const isHard = req.query.hard === 'true' || req.body?.hard === true;

    const existingLoan = await dbService.getLoanById(id);
    if (!existingLoan) {
      return res.status(404).json({
        status: 'fail',
        message: `Permohonan pinjam dengan ID ${id} tidak ditemukan.`
      });
    }

    const deleted = await dbService.deleteLoan(id, isHard);

    return res.status(200).json({
      status: 'success',
      message: isHard
        ? 'Permohonan peminjaman berhasil dihapus secara permanen dari basis data.'
        : 'Permohonan peminjaman berhasil dipindahkan ke arsip sampah (Soft Delete).',
      data: deleted
    });
  } catch (error) {
    console.error('Error delete loan:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal menghapus permohonan peminjaman.',
      error: error.message
    });
  }
};

/**
 * Memulihkan data permohonan peminjaman (Restore Soft Delete)
 * POST /api/loans/:id/restore
 */
exports.restoreLoan = async (req, res) => {
  try {
    const { id } = req.params;

    const restored = await dbService.restoreLoan(id);
    if (!restored) {
      return res.status(404).json({
        status: 'fail',
        message: `Permohonan pinjam dengan ID ${id} tidak ditemukan.`
      });
    }

    return res.status(200).json({
      status: 'success',
      message: 'Permohonan peminjaman berhasil dipulihkan dari arsip sampah ke antrean aktif.',
      data: restored
    });
  } catch (error) {
    console.error('Error restore loan:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal memulihkan permohonan peminjaman.',
      error: error.message
    });
  }
};
