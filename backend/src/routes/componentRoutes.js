const express = require('express');
const router = express.Router();
const componentController = require('../controllers/componentController');

// GET /api/components (dukung ?search= & ?category=)
router.get('/', componentController.getAllComponents);

// GET /api/components/:id
router.get('/:id', componentController.getComponentById);

// POST /api/components (tambah modul baru - aksi asisten)
router.post('/', componentController.createComponent);

// PUT /api/components/:id (edit komponen)
router.put('/:id', componentController.updateComponent);

// DELETE /api/components/:id (soft delete komponen)
router.delete('/:id', componentController.deleteComponent);

// POST /api/components/:id/restore (restore soft delete komponen)
router.post('/:id/restore', componentController.restoreComponent);

module.exports = router;
