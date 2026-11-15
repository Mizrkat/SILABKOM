const express = require('express');
const router = express.Router();
const loanController = require('../controllers/loanController');

// GET /api/loans (dukung ?user_id= & ?status=)
router.get('/', loanController.getAllLoans);

// GET /api/loans/:id
router.get('/:id', loanController.getLoanById);

// POST /api/loans (pengajuan peminjaman baru - aksi mahasiswa)
router.post('/', loanController.createLoan);

// PATCH /api/loans/:id/status (persetujuan/penolakan - aksi asisten)
router.patch('/:id/status', loanController.updateLoanStatus);

// DELETE /api/loans/:id (soft delete permohonan pinjam - aksi asisten)
router.delete('/:id', loanController.deleteLoan);

// POST /api/loans/:id/restore (restore soft delete permohonan pinjam)
router.post('/:id/restore', loanController.restoreLoan);

module.exports = router;
