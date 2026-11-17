import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/user_model.dart';
import '../navigation/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedAvatarBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
        setState(() {
          _selectedAvatarBase64 = base64String;
        });
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
                'Pilih Foto Profil Mahasiswa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Ambil dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Gunakan Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedAvatarBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                  title: const Text('Hapus Foto Pilihan', style: TextStyle(color: AppColors.statusRejected)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedAvatarBase64 = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.post(
        ApiEndpoints.register,
        body: {
          'name': _nameController.text.trim(),
          'nim_nip': _nimController.text.trim(),
          'password': _passwordController.text,
          if (_selectedAvatarBase64 != null) 'avatar': _selectedAvatarBase64,
        },
      );

      if (response != null && response['data'] != null) {
        final user = UserModel.fromJson(response['data']);
        await SessionManager.saveUserSession(
          id: user.id,
          name: user.name,
          nimNip: user.nimNip,
          role: user.role,
          avatar: _selectedAvatarBase64 ?? user.avatar,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang di SILABKOM, ${user.name}! Akun berhasil dibuat.'),
            backgroundColor: AppColors.statusApproved,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        throw ApiException(response?['message'] ?? 'Format respon registrasi tidak valid.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatarPreview() {
    Widget imageWidget;
    if (_selectedAvatarBase64 != null) {
      try {
        final commaIndex = _selectedAvatarBase64!.indexOf(',');
        final data = commaIndex != -1 ? _selectedAvatarBase64!.substring(commaIndex + 1) : _selectedAvatarBase64!;
        final bytes = base64Decode(data);
        imageWidget = CircleAvatar(
          radius: 46,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        imageWidget = const CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.surfaceVariant,
          child: Icon(Icons.school, size: 48, color: AppColors.primary),
        );
      }
    } else {
      imageWidget = const CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.school, size: 48, color: AppColors.primary),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 3),
          ),
          child: imageWidget,
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showImagePickerOptions,
              child: const Padding(
                padding: EdgeInsets.all(7.0),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Daftar Akun Mahasiswa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Center(
                  child: Column(
                    children: [
                      _buildAvatarPreview(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showImagePickerOptions,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.primary),
                        label: Text(
                          _selectedAvatarBase64 != null ? 'Ganti Foto Profil' : 'Pasang Foto Profil (Opsional)',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card Form
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Formulir Registrasi Mahasiswa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Daftarkan NIM Anda untuk meminjam modul & komponen lab.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pesan Error jika ada
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.statusRejectedBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.statusRejected.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.statusRejected, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.statusRejected,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Input Nama Lengkap
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap Mahasiswa',
                              hintText: 'Contoh: Radhine Muhammad Rossie',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              if (val.trim().length < 3) {
                                return 'Nama terlalu pendek (minimal 3 karakter)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Input NIM
                          TextFormField(
                            controller: _nimController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'NIM Mahasiswa',
                              hintText: 'Contoh: 21120124120017',
                              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.secondary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'NIM wajib diisi';
                              }
                              if (val.trim().length < 5) {
                                return 'NIM minimal 5 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Input Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: 'Minimal 6 karakter',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (val.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Input Konfirmasi Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Ulangi Kata Sandi',
                              hintText: 'Ketik ulang kata sandi',
                              prefixIcon: const Icon(Icons.lock_reset, color: AppColors.secondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (val != _passwordController.text) {
                                return 'Kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tombol Submit
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Daftar Akun Mahasiswa',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Link Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah memiliki akun? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk Sekarang',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
