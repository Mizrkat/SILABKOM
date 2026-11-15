const dbService = require('../config/db');

/**
 * Mendapatkan seluruh list komponen laboratorium
 * GET /api/components?search=&category=
 */
exports.getAllComponents = async (req, res) => {
  try {
    const { search, category, is_deleted } = req.query;
    const components = await dbService.getComponents(search, category, is_deleted);

    return res.status(200).json({
      status: 'success',
      total: components.length,
      data: components
    });
  } catch (error) {
    console.error('Error get components:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal mengambil data katalog komponen.',
      error: error.message
    });
  }
};

/**
 * Mendapatkan detail spesifik satu komponen
 * GET /api/components/:id
 */
exports.getComponentById = async (req, res) => {
  try {
    const { id } = req.params;
    const component = await dbService.getComponentById(id);

    if (!component) {
      return res.status(404).json({
        status: 'fail',
        message: `Komponen dengan ID ${id} tidak ditemukan.`
      });
    }

    return res.status(200).json({
      status: 'success',
      data: component
    });
  } catch (error) {
    console.error('Error get component by id:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal mengambil rincian komponen.',
      error: error.message
    });
  }
};

/**
 * Menambahkan modul/komponen baru (Fitur Khusus Asisten)
 * POST /api/components
 */
exports.createComponent = async (req, res) => {
  try {
    const { name, category, stock, location, description, datasheet_url } = req.body;

    if (!name || !category || stock === undefined || !location) {
      return res.status(400).json({
        status: 'fail',
        message: 'Field name, category, stock, dan location wajib diisi.'
      });
    }

    const newComponent = await dbService.createComponent({
      name,
      category,
      stock: parseInt(stock, 10),
      location,
      description: description || '',
      datasheet_url: datasheet_url || ''
    });

    return res.status(201).json({
      status: 'success',
      message: 'Komponen laboratorium baru berhasil ditambahkan.',
      data: newComponent
    });
  } catch (error) {
    console.error('Error create component:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal menambahkan komponen baru.',
      error: error.message
    });
  }
};

/**
 * Mengubah informasi data komponen
 * PUT /api/components/:id
 */
exports.updateComponent = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const existing = await dbService.getComponentById(id);
    if (!existing) {
      return res.status(404).json({
        status: 'fail',
        message: `Komponen dengan ID ${id} tidak ditemukan.`
      });
    }

    const updated = await dbService.updateComponent(id, updateData);

    return res.status(200).json({
      status: 'success',
      message: 'Data komponen berhasil diperbarui.',
      data: updated
    });
  } catch (error) {
    console.error('Error update component:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal memperbarui data komponen.',
      error: error.message
    });
  }
};

/**
 * Menghapus komponen dari katalog laboratorium (Soft Delete / Hard Delete)
 * DELETE /api/components/:id?hard=true
 */
exports.deleteComponent = async (req, res) => {
  try {
    const { id } = req.params;
    const isHard = req.query.hard === 'true' || req.body?.hard === true;

    const existing = await dbService.getComponentById(id);
    if (!existing) {
      return res.status(404).json({
        status: 'fail',
        message: `Komponen dengan ID ${id} tidak ditemukan.`
      });
    }

    const deleted = await dbService.deleteComponent(id, isHard);

    return res.status(200).json({
      status: 'success',
      message: isHard
        ? 'Komponen berhasil dihapus secara permanen dari basis data.'
        : 'Komponen berhasil dipindahkan ke arsip sampah (Soft Delete) dan dapat dipulihkan sewaktu-waktu.',
      data: deleted
    });
  } catch (error) {
    console.error('Error delete component:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal menghapus komponen.',
      error: error.message
    });
  }
};

/**
 * Memulihkan komponen yang telah dihapus (Restore Soft Delete)
 * POST /api/components/:id/restore
 */
exports.restoreComponent = async (req, res) => {
  try {
    const { id } = req.params;

    const restored = await dbService.restoreComponent(id);
    if (!restored) {
      return res.status(404).json({
        status: 'fail',
        message: `Komponen dengan ID ${id} tidak ditemukan.`
      });
    }

    return res.status(200).json({
      status: 'success',
      message: 'Komponen berhasil dipulihkan dari arsip sampah ke katalog aktif.',
      data: restored
    });
  } catch (error) {
    console.error('Error restore component:', error);
    return res.status(500).json({
      status: 'error',
      message: 'Gagal memulihkan komponen.',
      error: error.message
    });
  }
};
