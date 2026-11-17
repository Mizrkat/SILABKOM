const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');
require('dotenv').config();

let rawUrl = (process.env.SUPABASE_URL || '').trim();
// Bersihkan jika user tidak sengaja menambahkan akhiran /rest/v1 atau slash
const SUPABASE_URL = rawUrl.replace(/\/rest\/v1\/?$/, '').replace(/\/+$/, '');
const SUPABASE_KEY = (process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || '').trim();

let supabase = null;
const isSupabaseConfigured = Boolean(
  SUPABASE_URL &&
  SUPABASE_KEY &&
  !SUPABASE_URL.includes('your-project') &&
  SUPABASE_URL.startsWith('http')
);

if (isSupabaseConfigured) {
  try {
    supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      }
    });
    console.log('✅ Supabase Client initialized with remote endpoint:', SUPABASE_URL);
  } catch (err) {
    console.warn('⚠️ Gagal inisialisasi Supabase client, fallback ke database internal:', err.message);
  }
} else {
  console.log('ℹ️ SUPABASE_URL / SUPABASE_KEY belum dikonfigurasi. Menggunakan in-memory local database (seed lengkap siap pakai).');
}

// Helper pendeteksi apakah kolom soft delete belum dimigrasi di remote Supabase
function isColumnMissingError(err) {
  if (!err) return false;
  return (
    err.code === '42703' ||
    err.code === 'PGRST204' ||
    (typeof err.message === 'string' && (
      err.message.includes('column') ||
      err.message.includes('schema cache') ||
      err.message.includes('is_deleted') ||
      err.message.includes('deleted_at') ||
      err.message.includes('avatar')
    ))
  );
}

// ==============================================================================
// LOCAL IN-MEMORY DATABASE (SEED DATA LENGKAP)
// ==============================================================================
const localUsers = [
  {
    id: 'a0000000-0000-0000-0000-000000000001',
    name: 'Radhine Muhammad Rossie',
    nim_nip: '21120124120017',
    password: 'mahasiswa123',
    role: 'student',
    avatar: null,
    created_at: new Date().toISOString()
  },
  {
    id: 'a0000000-0000-0000-0000-000000000002',
    name: 'Asisten Lab Sistem Komputer',
    nim_nip: '199801012023011001',
    password: 'asisten123',
    role: 'assistant',
    avatar: null,
    created_at: new Date().toISOString()
  }
];

const localComponents = [
  {
    id: 'c0000000-0000-0000-0000-000000000001',
    name: 'ESP32 WROOM-32 DevKit V1',
    category: 'Mikrokontroler',
    stock: 15,
    location: 'Loker A-01',
    description: 'Modul pengembangan berbasis SoC ESP32 dual-core Tensilica Xtensa 32-bit LX6 dengan konektivitas Wi-Fi 802.11 b/g/n dan Bluetooth v4.2 BR/EDR & BLE.',
    datasheet_url: 'https://www.espressif.com/sites/default/files/documentation/esp32-wroom-32_datasheet_en.pdf',
    created_at: new Date().toISOString()
  },
  {
    id: 'c0000000-0000-0000-0000-000000000002',
    name: 'Arduino Uno R3 Atmega328P',
    category: 'Mikrokontroler',
    stock: 8,
    location: 'Loker A-02',
    description: 'Board mikrokontroler standar industri berbasis ATmega328P dengan 14 pin I/O digital, 6 input analog, clock speed 16 MHz osilator kristal keramik.',
    datasheet_url: 'https://docs.arduino.cc/resources/datasheets/A000066-datasheet.pdf',
    created_at: new Date().toISOString()
  },
  {
    id: 'c0000000-0000-0000-0000-000000000003',
    name: 'STM32 Blue Pill ARM Cortex-M3',
    category: 'Mikrokontroler',
    stock: 5,
    location: 'Loker A-03',
    description: 'Development board hemat daya dengan core 32-bit ARM Cortex-M3 (STM32F103C8T6), kecepatan 72 MHz, 64KB Flash, 20KB SRAM, USB interface dan CAN controller.',
    datasheet_url: 'https://www.st.com/resource/en/datasheet/stm32f103c8.pdf',
    created_at: new Date().toISOString()
  },
  {
    id: 'c0000000-0000-0000-0000-000000000004',
    name: '24MHz 8-Channel USB Logic Analyzer',
    category: 'Alat Ukur & Debugger',
    stock: 4,
    location: 'Rak B-01',
    description: 'Alat penganalisis sinyal digital 8 kanal dengan frekuensi sampling hingga 24MHz. Kompatibel dengan Saleae Logic Software untuk protokol I2C, SPI, UART, CAN.',
    datasheet_url: 'https://sigrok.org/wiki/Saleae_Logic',
    created_at: new Date().toISOString()
  },
  {
    id: 'c0000000-0000-0000-0000-000000000005',
    name: 'MPU6050 6-DOF Gyroscope & Accelerometer',
    category: 'Sensor & Modul',
    stock: 20,
    location: 'Box C-04',
    description: 'Sensor gerak terintegrasi 6-sumbu memadukan 3-axis gyroscope dan 3-axis accelerometer dengan Digital Motion Processor (DMP) internal berbasis antarmuka I2C.',
    datasheet_url: 'https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Datasheet1.pdf',
    created_at: new Date().toISOString()
  },
  {
    id: 'c0000000-0000-0000-0000-000000000006',
    name: 'Altera Cyclone IV FPGA EP4CE6 Starter Kit',
    category: 'FPGA & IC',
    stock: 3,
    location: 'Lemari Utama',
    description: 'Kit pembelajaran komputasi rekonfigurasi FPGA Altera Cyclone IV EP4CE6E22C8N dengan 6,272 Logic Elements, onboard SDRAM, VGA port, dan JTAG programmer.',
    datasheet_url: 'https://www.intel.com/content/www/us/en/docs/programmable/683610/current/cyclone-iv-device-handbook.html',
    created_at: new Date().toISOString()
  }
];

const now = new Date();
const formattedToday = now.toISOString().split('T')[0];
const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
const in3Days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

const localLoans = [
  {
    id: 'e0000000-0000-0000-0000-000000000001',
    user_id: 'a0000000-0000-0000-0000-000000000001',
    component_id: 'c0000000-0000-0000-0000-000000000001',
    borrow_date: formattedToday,
    return_date: in7Days,
    reason: 'Pengerjaan proyek mata kuliah Praktikum Sistem Tertanam dan IoT',
    status: 'approved',
    notes: 'Disetujui. Harap jaga modul dengan baik dan kembalikan tepat waktu.',
    created_at: new Date(now.getTime() - 24 * 3600 * 1000).toISOString()
  },
  {
    id: 'e0000000-0000-0000-0000-000000000002',
    user_id: 'a0000000-0000-0000-0000-000000000001',
    component_id: 'c0000000-0000-0000-0000-000000000004',
    borrow_date: formattedToday,
    return_date: in3Days,
    reason: 'Analisis sinyal debugging komunikasi serial I2C bus sensor gyroscope',
    status: 'pending',
    notes: null,
    created_at: new Date().toISOString()
  }
];

// Database service helper abstraction
const dbService = {
  isSupabaseConfigured,
  supabase,

  // --- USERS ---
  async getUserByNim(nim_nip) {
    if (supabase) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('nim_nip', nim_nip)
        .maybeSingle();
      if (error) throw error;
      return data;
    }
    return localUsers.find(u => u.nim_nip === nim_nip) || null;
  },

  async getUserById(id) {
    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('users')
          .select('id, name, nim_nip, role, avatar, created_at')
          .eq('id', id)
          .maybeSingle();
        if (error) {
          if (isColumnMissingError(error)) {
            const { data: fbData, error: fbErr } = await supabase
              .from('users')
              .select('id, name, nim_nip, role, created_at')
              .eq('id', id)
              .maybeSingle();
            if (fbErr) throw fbErr;
            return fbData ? { ...fbData, avatar: null } : null;
          }
          throw error;
        }
        return data;
      } catch (err) {
        if (isColumnMissingError(err)) {
          const { data: fbData, error: fbErr } = await supabase
            .from('users')
            .select('id, name, nim_nip, role, created_at')
            .eq('id', id)
            .maybeSingle();
          if (fbErr) throw fbErr;
          return fbData ? { ...fbData, avatar: null } : null;
        }
        throw err;
      }
    }
    const u = localUsers.find(u => u.id === id);
    if (!u) return null;
    const { password, ...safeUser } = u;
    return safeUser;
  },

  async createUser({ name, nim_nip, password, role = 'student', avatar = null }) {
    const id = crypto.randomUUID ? crypto.randomUUID() : 'u-' + Date.now();
    const now = new Date().toISOString();

    if (supabase) {
      try {
        const { data, error } = await supabase
          .from('users')
          .insert({
            name,
            nim_nip,
            password,
            role,
            avatar,
            created_at: now
          })
          .select('id, name, nim_nip, role, avatar, created_at')
          .single();

        if (error) {
          if (isColumnMissingError(error)) {
            const { data: fbData, error: fbErr } = await supabase
              .from('users')
              .insert({
                name,
                nim_nip,
                password,
                role,
                created_at: now
              })
              .select('id, name, nim_nip, role, created_at')
              .single();
            if (fbErr) throw fbErr;
            return { ...fbData, avatar: null };
          }
          throw error;
        }
        return data;
      } catch (err) {
        if (isColumnMissingError(err)) {
          const { data: fbData, error: fbErr } = await supabase
            .from('users')
            .insert({
              name,
              nim_nip,
              password,
              role,
              created_at: now
            })
            .select('id, name, nim_nip, role, created_at')
            .single();
          if (fbErr) throw fbErr;
          return { ...fbData, avatar: null };
        }
        throw err;
      }
    }

    const newUser = {
      id,
      name,
      nim_nip,
      password,
      role,
      avatar,
      created_at: now
    };
    localUsers.push(newUser);
    const { password: _, ...safeUser } = newUser;
    return safeUser;
  },

  async updateUser(id, { name, avatar }) {
    if (supabase) {
      const updateData = {};
      if (name !== undefined) updateData.name = name;
      if (avatar !== undefined) updateData.avatar = avatar;

      try {
        const { data, error } = await supabase
          .from('users')
          .update(updateData)
          .eq('id', id)
          .select('id, name, nim_nip, role, avatar, created_at')
          .single();

        if (error) {
          if (isColumnMissingError(error) && name !== undefined) {
            const { data: fbData, error: fbErr } = await supabase
              .from('users')
              .update({ name })
              .eq('id', id)
              .select('id, name, nim_nip, role, created_at')
              .single();
            if (fbErr) throw fbErr;
            return { ...fbData, avatar: avatar || null };
          }
          throw error;
        }
        return data;
      } catch (err) {
        if (isColumnMissingError(err) && name !== undefined) {
          const { data: fbData, error: fbErr } = await supabase
            .from('users')
            .update({ name })
            .eq('id', id)
            .select('id, name, nim_nip, role, created_at')
            .single();
          if (fbErr) throw fbErr;
          return { ...fbData, avatar: avatar || null };
        }
        throw err;
      }
    }

    const user = localUsers.find(u => u.id === id);
    if (!user) return null;
    if (name !== undefined) user.name = name;
    if (avatar !== undefined) user.avatar = avatar;
    const { password: _, ...safeUser } = user;
    return safeUser;
  },

  // --- COMPONENTS ---
  async getComponents(search, category, isDeleted = false) {
    const wantDeleted = isDeleted === true || isDeleted === 'true';

    if (supabase) {
      const buildQuery = (filterDeleted) => {
        let q = supabase.from('components').select('*').order('created_at', { ascending: false });
        if (category && category !== 'Semua') {
          q = q.eq('category', category);
        }
        if (search) {
          q = q.ilike('name', `%${search}%`);
        }
        if (filterDeleted) {
          q = q.eq('is_deleted', wantDeleted);
        }
        return q;
      };

      try {
        const { data, error } = await buildQuery(true);
        if (error) {
          if (isColumnMissingError(error)) {
            const { data: fbData, error: fbErr } = await buildQuery(false);
            if (fbErr) throw fbErr;
            return wantDeleted ? [] : fbData;
          }
          throw error;
        }
        return data;
      } catch (err) {
        if (isColumnMissingError(err)) {
          const { data: fbData, error: fbErr } = await buildQuery(false);
          if (fbErr) throw fbErr;
          return wantDeleted ? [] : fbData;
        }
        throw err;
      }
    }

    let result = [...localComponents];
    result = result.filter(c => Boolean(c.is_deleted) === wantDeleted);

    if (category && category !== 'Semua') {
      result = result.filter(c => c.category.toLowerCase() === category.toLowerCase());
    }
    if (search) {
      const s = search.toLowerCase();
      result = result.filter(c =>
        c.name.toLowerCase().includes(s) ||
        c.category.toLowerCase().includes(s) ||
        c.location.toLowerCase().includes(s)
      );
    }
    // Return sorted newest first
    return result.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  },

  async getComponentById(id) {
    if (supabase) {
      const { data, error } = await supabase
        .from('components')
        .select('*')
        .eq('id', id)
        .maybeSingle();
      if (error) throw error;
      return data;
    }
    return localComponents.find(c => c.id === id) || null;
  },

  async createComponent(componentData) {
    const newComponent = {
      id: crypto.randomUUID(),
      name: componentData.name,
      category: componentData.category,
      stock: parseInt(componentData.stock, 10) || 0,
      location: componentData.location,
      description: componentData.description || '',
      datasheet_url: componentData.datasheet_url || '',
      is_deleted: false,
      deleted_at: null,
      created_at: new Date().toISOString()
    };

    if (supabase) {
      let res = await supabase
        .from('components')
        .insert([newComponent])
        .select()
        .single();

      // Fallback jika tabel Supabase belum dimigrasi dengan kolom is_deleted
      if (res.error && isColumnMissingError(res.error)) {
        const fallbackComp = { ...newComponent };
        delete fallbackComp.is_deleted;
        delete fallbackComp.deleted_at;
        res = await supabase
          .from('components')
          .insert([fallbackComp])
          .select()
          .single();
      }

      if (res.error) throw res.error;
      return res.data;
    }

    localComponents.unshift(newComponent);
    return newComponent;
  },

  async updateComponent(id, updateData) {
    if (supabase) {
      const { data, error } = await supabase
        .from('components')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data;
    }

    const index = localComponents.findIndex(c => c.id === id);
    if (index === -1) return null;
    localComponents[index] = {
      ...localComponents[index],
      ...updateData,
      id // preserve ID
    };
    return localComponents[index];
  },

  // Soft / Hard Delete Modul Komponen
  async deleteComponent(id, isHardDelete = false) {
    const now = new Date().toISOString();

    if (supabase) {
      if (isHardDelete) {
        // Hapus permanen: Hapus relasi di tabel loans terlebih dahulu
        await supabase.from('loans').delete().eq('component_id', id);
        const { data, error } = await supabase
          .from('components')
          .delete()
          .eq('id', id)
          .select()
          .single();
        if (error) throw error;
        return data;
      }

      // 1. Coba Soft Delete (is_deleted = true)
      const { data, error } = await supabase
        .from('components')
        .update({ is_deleted: true, deleted_at: now })
        .eq('id', id)
        .select()
        .single();

      if (error) {
        // Fallback jika kolom is_deleted belum ada di database Supabase
        if (isColumnMissingError(error)) {
          await supabase.from('loans').delete().eq('component_id', id);
          const { data: fbData, error: fbErr } = await supabase
            .from('components')
            .delete()
            .eq('id', id)
            .select()
            .single();
          if (fbErr) throw fbErr;
          return fbData;
        }
        throw error;
      }
      return data;
    }

    // Local fallback
    if (isHardDelete) {
      for (let i = localLoans.length - 1; i >= 0; i--) {
        if (localLoans[i].component_id === id) {
          localLoans.splice(i, 1);
        }
      }
      const idx = localComponents.findIndex(c => c.id === id);
      if (idx === -1) return null;
      return localComponents.splice(idx, 1)[0];
    }

    const comp = localComponents.find(c => c.id === id);
    if (!comp) return null;
    comp.is_deleted = true;
    comp.deleted_at = now;
    return comp;
  },

  // Pulihkan Modul Komponen (Restore Soft Delete)
  async restoreComponent(id) {
    if (supabase) {
      const { data, error } = await supabase
        .from('components')
        .update({ is_deleted: false, deleted_at: null })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    }

    const comp = localComponents.find(c => c.id === id);
    if (!comp) return null;
    comp.is_deleted = false;
    comp.deleted_at = null;
    return comp;
  },

  // --- LOANS ---
  async getLoans(userId, status, isDeleted = false) {
    const wantDeleted = isDeleted === true || isDeleted === 'true';

    if (supabase) {
      const buildQuery = (filterDeleted) => {
        let q = supabase
          .from('loans')
          .select(`
            *,
            user:users(id, name, nim_nip, role),
            component:components(id, name, category, location, stock, datasheet_url)
          `)
          .order('created_at', { ascending: false });

        if (userId) {
          q = q.eq('user_id', userId);
        }
        if (status && status !== 'Semua') {
          q = q.eq('status', status.toLowerCase());
        }
        if (filterDeleted) {
          q = q.eq('is_deleted', wantDeleted);
        }
        return q;
      };

      try {
        const { data, error } = await buildQuery(true);
        if (error) {
          if (isColumnMissingError(error)) {
            const { data: fbData, error: fbErr } = await buildQuery(false);
            if (fbErr) throw fbErr;
            return wantDeleted ? [] : fbData;
          }
          throw error;
        }
        return data;
      } catch (err) {
        if (isColumnMissingError(err)) {
          const { data: fbData, error: fbErr } = await buildQuery(false);
          if (fbErr) throw fbErr;
          return wantDeleted ? [] : fbData;
        }
        throw err;
      }
    }

    let result = localLoans
      .filter(l => Boolean(l.is_deleted) === wantDeleted)
      .map(loan => {
        const user = localUsers.find(u => u.id === loan.user_id);
        const component = localComponents.find(c => c.id === loan.component_id);
        return {
          ...loan,
          user: user ? { id: user.id, name: user.name, nim_nip: user.nim_nip, role: user.role } : null,
          component: component ? { ...component } : null
        };
      });

    if (userId) {
      result = result.filter(l => l.user_id === userId);
    }
    if (status && status !== 'Semua') {
      result = result.filter(l => l.status.toLowerCase() === status.toLowerCase());
    }

    return result.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  },

  async getLoanById(id) {
    if (supabase) {
      const { data, error } = await supabase
        .from('loans')
        .select(`
          *,
          user:users(id, name, nim_nip, role),
          component:components(id, name, category, location, stock, datasheet_url)
        `)
        .eq('id', id)
        .maybeSingle();
      if (error) throw error;
      return data;
    }

    const loan = localLoans.find(l => l.id === id);
    if (!loan) return null;
    const user = localUsers.find(u => u.id === loan.user_id);
    const component = localComponents.find(c => c.id === loan.component_id);
    return {
      ...loan,
      user: user ? { id: user.id, name: user.name, nim_nip: user.nim_nip, role: user.role } : null,
      component: component ? { ...component } : null
    };
  },

  async createLoan(loanData) {
    if (supabase) {
      // 1. Cek ketersediaan stok komponen di Supabase
      const { data: comp, error: compErr } = await supabase
        .from('components')
        .select('stock')
        .eq('id', loanData.component_id)
        .single();

      if (compErr || !comp) {
        throw new Error('Komponen tidak ditemukan dalam katalog.');
      }
      if (comp.stock <= 0) {
        throw new Error('Stok barang sudah habis (0 unit). Tidak dapat mengajukan peminjaman.');
      }

      // 2. Langsung kurangi stok komponen di lab (-1) saat pengajuan dibuat
      const { error: stockUpdateErr } = await supabase
        .from('components')
        .update({ stock: comp.stock - 1 })
        .eq('id', loanData.component_id);
      if (stockUpdateErr) throw stockUpdateErr;

      // 3. Masukkan data permohonan peminjaman
      const newLoan = {
        id: crypto.randomUUID(),
        user_id: loanData.user_id,
        component_id: loanData.component_id,
        borrow_date: loanData.borrow_date,
        return_date: loanData.return_date,
        reason: loanData.reason,
        status: 'pending',
        notes: null,
        is_deleted: false,
        deleted_at: null,
        created_at: new Date().toISOString()
      };

      let res = await supabase
        .from('loans')
        .insert([newLoan])
        .select(`
          *,
          user:users(id, name, nim_nip, role),
          component:components(id, name, category, location, stock)
        `)
        .single();

      // Fallback jika tabel loans belum dimigrasi kolom is_deleted
      if (res.error && isColumnMissingError(res.error)) {
        const fallbackLoan = { ...newLoan };
        delete fallbackLoan.is_deleted;
        delete fallbackLoan.deleted_at;
        res = await supabase
          .from('loans')
          .insert([fallbackLoan])
          .select(`
            *,
            user:users(id, name, nim_nip, role),
            component:components(id, name, category, location, stock)
          `)
          .single();
      }

      if (res.error) throw res.error;
      return res.data;
    }

    // Local in-memory fallback
    const comp = localComponents.find(c => c.id === loanData.component_id);
    if (!comp) {
      throw new Error('Komponen tidak ditemukan.');
    }
    if (comp.stock <= 0) {
      throw new Error('Stok barang sudah habis (0 unit). Tidak dapat mengajukan peminjaman.');
    }
    // Kurangi stok saat diajukan
    comp.stock -= 1;

    const newLoan = {
      id: crypto.randomUUID(),
      user_id: loanData.user_id,
      component_id: loanData.component_id,
      borrow_date: loanData.borrow_date,
      return_date: loanData.return_date,
      reason: loanData.reason,
      status: 'pending',
      notes: null,
      is_deleted: false,
      deleted_at: null,
      created_at: new Date().toISOString()
    };
    localLoans.unshift(newLoan);
    const user = localUsers.find(u => u.id === newLoan.user_id);
    return {
      ...newLoan,
      user: user ? { id: user.id, name: user.name, nim_nip: user.nim_nip, role: user.role } : null,
      component: { ...comp }
    };
  },

  async updateLoanStatus(id, status, notes, return_photo) {
    if (supabase) {
      const { data: currentLoan } = await supabase
        .from('loans')
        .select('component_id, status')
        .eq('id', id)
        .single();

      // Jika DITOLAK (rejected) dan sebelumnya berstatus pending atau approved:
      // Kembalikan stok modul (+1) ke inventaris karena peminjaman tidak jadi
      if (status === 'rejected' && currentLoan && (currentLoan.status === 'pending' || currentLoan.status === 'approved')) {
        const { data: comp } = await supabase
          .from('components')
          .select('stock')
          .eq('id', currentLoan.component_id)
          .single();

        if (comp) {
          await supabase
            .from('components')
            .update({ stock: comp.stock + 1 })
            .eq('id', currentLoan.component_id);
        }
      }

      // Jika telah DIKEMBALIKAN (returned) dan sebelumnya berstatus approved atau returning:
      // Kembalikan stok modul (+1) ke inventaris laboratorium
      if (status === 'returned' && currentLoan && currentLoan.status !== 'returned') {
        const { data: comp } = await supabase
          .from('components')
          .select('stock')
          .eq('id', currentLoan.component_id)
          .single();

        if (comp) {
          await supabase
            .from('components')
            .update({ stock: comp.stock + 1 })
            .eq('id', currentLoan.component_id);
        }
      }

      const updatePayload = {
        status,
        updated_at: new Date().toISOString()
      };
      if (notes !== undefined) updatePayload.notes = notes;
      if (return_photo !== undefined) updatePayload.return_photo = return_photo;

      let res = await supabase
        .from('loans')
        .update(updatePayload)
        .eq('id', id)
        .select(`
          *,
          user:users(id, name, nim_nip, role),
          component:components(id, name, category, location, stock)
        `)
        .single();

      // Fallback otomatis jika kolom return_photo belum ditambahkan di Supabase
      if (res.error && updatePayload.return_photo && (res.error.code === 'PGRST204' || (res.error.message && res.error.message.includes('return_photo')))) {
        delete updatePayload.return_photo;
        res = await supabase
          .from('loans')
          .update(updatePayload)
          .eq('id', id)
          .select(`
            *,
            user:users(id, name, nim_nip, role),
            component:components(id, name, category, location, stock)
          `)
          .single();
      }

      if (res.error) throw res.error;
      return res.data;
    }

    const loanIndex = localLoans.findIndex(l => l.id === id);
    if (loanIndex === -1) return null;

    const previousStatus = localLoans[loanIndex].status;
    localLoans[loanIndex].status = status;
    if (notes !== undefined) {
      localLoans[loanIndex].notes = notes;
    }
    if (return_photo !== undefined) {
      localLoans[loanIndex].return_photo = return_photo;
    }

    // Jika ditolak, kembalikan stok (+1)
    if (status === 'rejected' && (previousStatus === 'pending' || previousStatus === 'approved')) {
      const comp = localComponents.find(c => c.id === localLoans[loanIndex].component_id);
      if (comp) {
        comp.stock += 1;
      }
    }

    // Jika returned, kembalikan stok (+1)
    if (status === 'returned' && previousStatus !== 'returned') {
      const comp = localComponents.find(c => c.id === localLoans[loanIndex].component_id);
      if (comp) {
        comp.stock += 1;
      }
    }

    const updatedLoan = localLoans[loanIndex];
    const user = localUsers.find(u => u.id === updatedLoan.user_id);
    const component = localComponents.find(c => c.id === updatedLoan.component_id);
    return {
      ...updatedLoan,
      user: user ? { id: user.id, name: user.name, nim_nip: user.nim_nip, role: user.role } : null,
      component: component ? { ...component } : null
    };
  },

  // Soft / Hard Delete Permohonan Peminjaman
  async deleteLoan(id, isHardDelete = false) {
    const now = new Date().toISOString();

    if (supabase) {
      // 1. Ambil data loan sebelum dihapus untuk cek status & component_id
      const { data: loan } = await supabase
        .from('loans')
        .select('*')
        .eq('id', id)
        .maybeSingle();

      if (!loan) return null;

      // 2. Jika permohonan belum berstatus soft-deleted dan berstatus aktif, kembalikan stok (+1) ke komponen
      if (!loan.is_deleted && ['pending', 'approved', 'returning'].includes(loan.status)) {
        const { data: comp } = await supabase
          .from('components')
          .select('stock')
          .eq('id', loan.component_id)
          .single();

        if (comp) {
          await supabase
            .from('components')
            .update({ stock: comp.stock + 1 })
            .eq('id', loan.component_id);
        }
      }

      // Hard Delete
      if (isHardDelete) {
        const { data, error } = await supabase
          .from('loans')
          .delete()
          .eq('id', id)
          .select()
          .single();
        if (error) throw error;
        return data;
      }

      // 3. Update is_deleted = true (Soft Delete)
      const { data, error } = await supabase
        .from('loans')
        .update({ is_deleted: true, deleted_at: now })
        .eq('id', id)
        .select()
        .single();

      if (error) {
        // Fallback jika kolom is_deleted belum ada di tabel Supabase
        if (isColumnMissingError(error)) {
          const { data: fbData, error: fbErr } = await supabase
            .from('loans')
            .delete()
            .eq('id', id)
            .select()
            .single();
          if (fbErr) throw fbErr;
          return fbData;
        }
        throw error;
      }
      return data;
    }

    // Local fallback
    const index = localLoans.findIndex(l => l.id === id);
    if (index === -1) return null;
    const loan = localLoans[index];

    if (!loan.is_deleted && ['pending', 'approved', 'returning'].includes(loan.status)) {
      const comp = localComponents.find(c => c.id === loan.component_id);
      if (comp) {
        comp.stock += 1;
      }
    }

    if (isHardDelete) {
      return localLoans.splice(index, 1)[0];
    }

    loan.is_deleted = true;
    loan.deleted_at = now;
    return loan;
  },

  // Pulihkan Permohonan Peminjaman (Restore Soft Delete)
  async restoreLoan(id) {
    if (supabase) {
      const { data: loan } = await supabase
        .from('loans')
        .select('*')
        .eq('id', id)
        .maybeSingle();

      if (!loan) return null;

      // Jika loan yang dipulihkan masih berstatus aktif, potong stok (-1) kembali jika stok cukup
      if (['pending', 'approved', 'returning'].includes(loan.status)) {
        const { data: comp } = await supabase
          .from('components')
          .select('stock')
          .eq('id', loan.component_id)
          .single();

        if (comp && comp.stock > 0) {
          await supabase
            .from('components')
            .update({ stock: comp.stock - 1 })
            .eq('id', loan.component_id);
        }
      }

      const { data, error } = await supabase
        .from('loans')
        .update({ is_deleted: false, deleted_at: null })
        .eq('id', id)
        .select(`
          *,
          user:users(id, name, nim_nip, role),
          component:components(id, name, category, location, stock)
        `)
        .single();

      if (error) throw error;
      return data;
    }

    // Local fallback
    const loan = localLoans.find(l => l.id === id);
    if (!loan) return null;

    if (['pending', 'approved', 'returning'].includes(loan.status)) {
      const comp = localComponents.find(c => c.id === loan.component_id);
      if (comp && comp.stock > 0) {
        comp.stock -= 1;
      }
    }

    loan.is_deleted = false;
    loan.deleted_at = null;
    return loan;
  }
};

module.exports = dbService;
