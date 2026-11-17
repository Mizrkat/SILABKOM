const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// POST /api/auth/login
router.post('/login', authController.login);

// POST /api/auth/register (Pendaftaran Akun Mahasiswa Baru)
router.post('/register', authController.register);

// PUT /api/auth/profile (Update Nama & Foto Profil Mahasiswa)
router.put('/profile', authController.updateProfile);

// GET /api/auth/profile/:id (Ambil Data Profil)
router.get('/profile/:id', authController.getProfile);

module.exports = router;
