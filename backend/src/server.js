const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const componentRoutes = require('./routes/componentRoutes');
const loanRoutes = require('./routes/loanRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request Logger sederhana
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.originalUrl}`);
  next();
});

// Root / Health Check
app.get('/', (req, res) => {
  res.json({
    name: 'RESTful API Sistem Inventaris & Peminjaman Lab Sistem Komputer UNDIP',
    version: '1.0.0',
    status: 'ONLINE',
    author: 'Teknik Komputer UNDIP - Praktikum PPB 2026',
    endpoints: {
      auth: {
        login: 'POST /api/auth/login'
      },
      components: {
        getAll: 'GET /api/components?search=&category=',
        getOne: 'GET /api/components/:id',
        create: 'POST /api/components',
        update: 'PUT /api/components/:id',
        delete: 'DELETE /api/components/:id'
      },
      loans: {
        getAll: 'GET /api/loans?user_id=&status=',
        getOne: 'GET /api/loans/:id',
        create: 'POST /api/loans',
        updateStatus: 'PATCH /api/loans/:id/status',
        delete: 'DELETE /api/loans/:id'
      }
    }
  });
});

// Mount API Routes
app.use('/api/auth', authRoutes);
app.use('/api/components', componentRoutes);
app.use('/api/loans', loanRoutes);

// 404 Not Found Handler
app.use((req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan pada server ini.`
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled server error:', err);
  res.status(500).json({
    status: 'error',
    message: 'Terjadi kesalahan internal pada server.',
    error: err.message
  });
});

// Start Server
app.listen(PORT, HOST, () => {
  console.log('================================================================');
  console.log('🚀 SERVER RESTful API LAB SISTEM KOMPUTER UNDIP BERJALAN');
  console.log(`🌐 Local Host      : http://localhost:${PORT}`);
  console.log(`📱 Android Emulator: http://10.0.2.2:${PORT}`);
  console.log(`📡 Network Host    : http://${HOST}:${PORT}`);
  console.log('================================================================');
});
