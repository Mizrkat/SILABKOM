const dbService = require('../config/db');

/**
 * Controller untuk Autentikasi Pengguna
 * POST /api/auth/login
 */
exports.login = async (req, res) => {
  try {
    const { nim_nip, password } = req.body;

    if (!nim_nip || !password) {
      return res.status(400).json({
        status: 'fail',
        message: 'NIM/NIP dan password wajib diisi.'
      });
    }

    const user = await dbService.getUserByNim(nim_nip.trim());

    if (!user || user.password !== password) {
      return res.status(401).json({
        status: 'fail',
        message: 'Kombinasi NIM/NIP atau password salah.'
      });
    }

    // Response sukses tanpa mengekspos password
    return res.status(200).json({
      status: 'success',
      message: `Login berhasil sebagai ${user.role === 'assistant' ? 'Asisten Laboratorium' : 'Mahasiswa'}`,
      data: {
        id: user.id,
        name: user.name,
        nim_nip: user.nim_nip,
        role: user.role,
        created_at: user.created_at
      }
    });
  } catch (error) {
    console.error('Error saat login:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Terjadi kesalahan pada server saat proses autentikasi.',
      error: error.message
    });
  }
};
