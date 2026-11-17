import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../widgets/server_config_dialog.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userId;
  String _userName = 'Memuat...';
  String _userNim = '-';
  String _userRole = 'student';
  String? _userAvatar;
  String _currentApiUrl = '';
  bool _isUpdating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final uid = await SessionManager.getUserId();
    final name = await SessionManager.getUserName() ?? 'Pengguna';
    final nim = await SessionManager.getUserNim() ?? '-';
    final role = await SessionManager.getUserRole();
    final avatar = await SessionManager.getUserAvatar();
    final url = await SessionManager.getCustomApiUrl();

    if (mounted) {
      setState(() {
        _userId = uid;
        _userName = name;
        _userNim = nim;
        _userRole = role;
        _userAvatar = avatar;
        _currentApiUrl = url;
      });
    }

    // Ambil data terbaru dari backend jika ID tersedia
    if (uid != null) {
      try {
        final res = await ApiClient.get(ApiEndpoints.profileById(uid));
        if (res != null && res['data'] != null && mounted) {
          final data = res['data'];
          final freshName = data['name']?.toString() ?? name;
          final freshAvatar = data['avatar']?.toString() ?? avatar;
          await SessionManager.saveUserName(freshName);
          await SessionManager.saveUserAvatar(freshAvatar);
          setState(() {
            _userName = freshName;
            _userAvatar = freshAvatar;
          });
        }
      } catch (_) {
        // Abaikan jika server offline, gunakan cache lokal SessionManager
      }
    }
  }

  // Dialog untuk Ganti Nama
  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: _userName);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Ganti Nama Mahasiswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan nama lengkap baru Anda:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person, color: AppColors.secondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama tidak boleh kosong';
                  if (val.trim().length < 3) return 'Nama minimal 3 karakter';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && updated != _userName) {
      await _updateProfile(newName: updated);
    }
  }

  // Pilih foto profil dari galeri / kamera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _updateProfile(newAvatar: base64String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ubah Foto Profil Mahasiswa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pilih dari Galeri Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_userAvatar != null && _userAvatar!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: AppColors.statusRejected)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateProfile(removeAvatar: true);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Kirim update ke backend & perbarui sesi
  Future<void> _updateProfile({String? newName, String? newAvatar, bool removeAvatar = false}) async {
    if (_userId == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final Map<String, dynamic> body = {'id': _userId};
      if (newName != null) body['name'] = newName;
      if (removeAvatar) {
        body['avatar'] = null;
      } else if (newAvatar != null) {
        body['avatar'] = newAvatar;
      }

      final res = await ApiClient.put(ApiEndpoints.updateProfile, body: body);

      if (mounted) {
        if (newName != null) {
          await SessionManager.saveUserName(newName);
          if (mounted) {
            setState(() {
              _userName = newName;
            });
          }
        }
        if (removeAvatar) {
          await SessionManager.saveUserAvatar(null);
          if (mounted) {
            setState(() {
              _userAvatar = null;
            });
          }
        } else if (newAvatar != null) {
          await SessionManager.saveUserAvatar(newAvatar);
          if (mounted) {
            setState(() {
              _userAvatar = newAvatar;
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res?['message'] ?? 'Profil berhasil diperbarui!'),
              backgroundColor: AppColors.statusApproved,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.clearSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Dialog untuk mengubah Base URL API saat pengujian di smartphone Android fisik
  Future<void> _showEditApiUrlDialog() async {
    final changed = await ServerConfigDialog.show(context);
    if (changed == true && mounted) {
      final updatedUrl = await SessionManager.getCustomApiUrl();
      setState(() {
        _currentApiUrl = updatedUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alamat server diperbarui ke: $updatedUrl'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    }
  }

  Widget _buildAvatarWidget(bool isAssistant) {
    Widget avatarContent;

    if (_userAvatar != null && _userAvatar!.isNotEmpty) {
      try {
        final commaIndex = _userAvatar!.indexOf(',');
        final data = commaIndex != -1 ? _userAvatar!.substring(commaIndex + 1) : _userAvatar!;
        final bytes = base64Decode(data);
        avatarContent = CircleAvatar(
          radius: 44,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        avatarContent = CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
          child: Icon(
            isAssistant ? Icons.admin_panel_settings : Icons.school,
            size: 46,
            color: AppColors.primary,
          ),
        );
      }
    } else {
      avatarContent = CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
        child: Icon(
          isAssistant ? Icons.admin_panel_settings : Icons.school,
          size: 46,
          color: AppColors.primary,
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.6), width: 3),
          ),
          child: avatarContent,
        ),
        // Kamera icon badge untuk ganti foto profil
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isUpdating ? null : _showImagePickerOptions,
              child: const Padding(
                padding: EdgeInsets.all(7.0),
                child: Icon(Icons.camera_alt, size: 17, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAssistant = _userRole == 'assistant';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil & Informasi Lab',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card (Lebar tetap konsisten dan tidak terpengaruh panjang nama)
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    _buildAvatarWidget(isAssistant),
                    const SizedBox(height: 8),

                    // Tombol cepat ganti foto
                    TextButton.icon(
                      onPressed: _isUpdating ? null : _showImagePickerOptions,
                      icon: const Icon(Icons.camera_enhance_outlined, size: 15, color: AppColors.primary),
                      label: Text(
                        _userAvatar != null ? 'Ganti Foto Profil' : 'Upload Foto Profil',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Nama Mahasiswa dengan Tombol Edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                          tooltip: 'Ganti Nama Mahasiswa',
                          onPressed: _isUpdating ? null : _showEditNameDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '${isAssistant ? 'NIP' : 'NIM'}: $_userNim',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAssistant ? AppColors.primary : AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAssistant ? 'ASISTEN LABORATORIUM' : 'MAHASISWA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    if (_isUpdating) ...[
                      const SizedBox(height: 14),
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

            // About SILABKOM
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SILABKOM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sistem Informasi Laboratorium Teknik Komputer Universitas Diponegoro',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Departemen Teknik Komputer\nFakultas Teknik - Universitas Diponegoro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistem digitalisasi layanan inventarisasi modul praktikum, komponen elektronika tertanam, alat ukur, dan sirkulasi peminjaman perangkat laboratorium berbasis mobile Android.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Gedung Kuliah Bersama / Gedung B Lantai 2, Kampus UNDIP Tembalang, Semarang, Jawa Tengah.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Server & Network Connectivity Card
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lan, size: 20, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Text(
                              'Koneksi RESTful API',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showEditApiUrlDialog,
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Ganti URL', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentApiUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Identitas Tugas Akhir PPB
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nama Sistem', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('SILABKOM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mata Kuliah', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Praktikum PPB (Semester 5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tahun Akademik', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('2026 / 2027', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Versi Aplikasi', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('v1.0.0 (Release Build)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Logout
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: AppColors.statusRejected),
              label: const Text(
                'Keluar dari Aplikasi (Logout)',
                style: TextStyle(
                  color: AppColors.statusRejected,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.statusRejected),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
