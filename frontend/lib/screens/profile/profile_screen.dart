import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/session_manager.dart';
import '../../widgets/server_config_dialog.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Memuat...';
  String _userNim = '-';
  String _userRole = 'student';
  String _currentApiUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await SessionManager.getUserName() ?? 'Pengguna';
    final nim = await SessionManager.getUserNim() ?? '-';
    final role = await SessionManager.getUserRole();
    final url = await SessionManager.getCustomApiUrl();

    if (mounted) {
      setState(() {
        _userName = name;
        _userNim = nim;
        _userRole = role;
        _currentApiUrl = url;
      });
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
          children: [
            // User Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                      child: Icon(
                        isAssistant ? Icons.admin_panel_settings : Icons.school,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _userName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                  ],
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
