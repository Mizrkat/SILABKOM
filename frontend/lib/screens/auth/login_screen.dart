import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/user_model.dart';
import '../../widgets/server_config_dialog.dart';
import '../navigation/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.post(
        ApiEndpoints.login,
        body: {
          'nim_nip': _nimController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response != null && response['data'] != null) {
        final user = UserModel.fromJson(response['data']);
        await SessionManager.saveUserSession(
          id: user.id,
          name: user.name,
          nimNip: user.nimNip,
          role: user.role,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        throw ApiException(response?['message'] ?? 'Format respon tidak valid.');
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

  // Helper pengisian cepat akun demo untuk pengujian responsi
  void _fillCredentials(String nim, String pass) {
    setState(() {
      _nimController.text = nim;
      _passwordController.text = pass;
      _errorMessage = null;
    });
  }

  Future<void> _openServerConfig() async {
    final changed = await ServerConfigDialog.show(context);
    if (changed == true && mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Pengaturan Server URL API (Sangat penting saat ganti IP HP Fisik)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openServerConfig,
                    icon: const Icon(Icons.dns_outlined, size: 15, color: AppColors.secondary),
                    label: Text(
                      'Server: ${ApiEndpoints.currentBaseUrl.replaceAll('http://', '')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header Logo & Branding Lab Sistem Komputer UNDIP
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.memory_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SILABKOM',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sistem Informasi Laboratorium\nTeknik Komputer Universitas Diponegoro',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 28),

                // Card Login
                Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Masuk ke Akun',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gunakan NIM Mahasiswa atau NIP Asisten Lab',
                            style: theme.textTheme.bodySmall?.copyWith(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
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
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _openServerConfig,
                                    icon: const Icon(Icons.wifi_tethering, size: 14),
                                    label: const Text(
                                      'Ubah Alamat IP Server Laptop',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.statusRejected,
                                      side: const BorderSide(color: AppColors.statusRejected),
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Input NIM / NIP
                          TextFormField(
                            controller: _nimController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: 'NIM / NIP',
                              hintText: 'Contoh: 21120124120017',
                              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.secondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'NIM / NIP tidak boleh kosong';
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
                              hintText: '••••••••',
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Kata sandi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Tombol Login
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk ke Sistem',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Switch Demo Akun (Sangat praktis saat responsi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, size: 16, color: AppColors.statusPending),
                          const SizedBox(width: 4),
                          Text(
                            'Pintasan Uji Akun Responsi',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _fillCredentials('21120124120017', 'mahasiswa123'),
                              icon: const Icon(Icons.school, size: 16, color: AppColors.secondary),
                              label: const Text('Mahasiswa', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _fillCredentials('199801012023011001', 'asisten123'),
                              icon: const Icon(Icons.admin_panel_settings, size: 16, color: AppColors.primary),
                              label: const Text('Asisten Lab', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
