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
        avatar: user.avatar || null,
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

/**
 * Controller untuk Pendaftaran Mahasiswa Baru (Sign Up)
 * POST /api/auth/register
 */
exports.register = async (req, res) => {
  try {
    const { name, nim_nip, password, avatar } = req.body;

    if (!name || !nim_nip || !password) {
      return res.status(400).json({
        status: 'fail',
        message: 'Nama lengkap, NIM, dan password wajib diisi.'
      });
    }

    const cleanNim = nim_nip.trim();
    const cleanName = name.trim();

    if (cleanNim.length < 5) {
      return res.status(400).json({
        status: 'fail',
        message: 'NIM harus memiliki minimal 5 karakter.'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        status: 'fail',
        message: 'Password harus memiliki minimal 6 karakter.'
      });
    }

    // Cek apakah NIM sudah terdaftar
    const existing = await dbService.getUserByNim(cleanNim);
    if (existing) {
      return res.status(409).json({
        status: 'fail',
        message: `NIM ${cleanNim} sudah terdaftar di sistem SILABKOM.`
      });
    }

    // Role default untuk pendaftaran mahasiswa baru adalah 'student'
    const newUser = await dbService.createUser({
      name: cleanName,
      nim_nip: cleanNim,
      password: password,
      role: 'student',
      avatar: avatar || null
    });

    return res.status(201).json({
      status: 'success',
      message: 'Akun mahasiswa baru berhasil didaftarkan.',
      data: {
        id: newUser.id,
        name: newUser.name,
        nim_nip: newUser.nim_nip,
        role: newUser.role,
        avatar: newUser.avatar || null,
        created_at: newUser.created_at
      }
    });
  } catch (error) {
    console.error('Error saat registrasi mahasiswa baru:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Terjadi kesalahan pada server saat proses pendaftaran mahasiswa.',
      error: error.message
    });
  }
};

/**
 * Controller untuk Update Profil Mahasiswa (Ganti Nama & Upload Foto Profil)
 * PUT /api/auth/profile
 */
exports.updateProfile = async (req, res) => {
  try {
    const { id, name, avatar } = req.body;

    if (!id) {
      return res.status(400).json({
        status: 'fail',
        message: 'ID pengguna wajib disertakan.'
      });
    }

    if (!name && avatar === undefined) {
      return res.status(400).json({
        status: 'fail',
        message: 'Tidak ada perubahan data yang dikirimkan.'
      });
    }

    const user = await dbService.getUserById(id);
    if (!user) {
      return res.status(404).json({
        status: 'fail',
        message: 'Pengguna tidak ditemukan.'
      });
    }

    const updatedUser = await dbService.updateUser(id, {
      name: name ? name.trim() : undefined,
      avatar: avatar !== undefined ? avatar : undefined
    });

    return res.status(200).json({
      status: 'success',
      message: 'Profil mahasiswa berhasil diperbarui.',
      data: updatedUser
    });
  } catch (error) {
    console.error('Error saat update profil:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Terjadi kesalahan pada server saat memperbarui profil.',
      error: error.message
    });
  }
};

/**
 * Controller untuk Mengambil Data Profil Pengguna
 * GET /api/auth/profile/:id
 */
exports.getProfile = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await dbService.getUserById(id);
    if (!user) {
      return res.status(404).json({
        status: 'fail',
        message: 'Pengguna tidak ditemukan.'
      });
    }
    return res.status(200).json({
      status: 'success',
      data: user
    });
  } catch (error) {
    console.error('Error saat mengambil profil:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Terjadi kesalahan pada server saat mengambil data profil.',
      error: error.message
    });
  }
};
