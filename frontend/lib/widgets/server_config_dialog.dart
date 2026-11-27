import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/session_manager.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiEndpoints.currentBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _setPreset(String url) {
    setState(() {
      _urlController.text = url;
      _testResult = null;
    });
  }

  Future<void> _testConnection() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final uri = Uri.parse(inputUrl);
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        String serverName = 'Server RESTful API Aktif';
        try {
          final data = jsonDecode(res.body);
          if (data['name'] != null) serverName = data['name'];
        } catch (_) {}
        setState(() {
          _testSuccess = true;
          _testResult = '✅ Terhubung! $serverName';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = '⚠️ Server merespon status HTTP ${res.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _testSuccess = false;
        _testResult = '❌ Waktu koneksi habis (Timeout). Pastikan HP dan Laptop terhubung ke Wi-Fi yang sama.';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = '❌ Gagal terhubung: Cek IP Laptop Anda atau Firewall Windows.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveAndApply() async {
    String cleanUrl = _urlController.text.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }

    await SessionManager.saveCustomApiUrl(cleanUrl);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Server API',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih server Cloud Vercel atau server lokal',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Info Box Penjelasan Server
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secara default aplikasi terhubung ke server Cloud Vercel (dapat diakses dari jaringan mana saja). Gunakan IP lokal atau 10.0.2.2 hanya jika ingin menguji backend lokal.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pilihan Preset Cepat
              const Text(
                'Pilihan Preset Cepat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.cloud_done, size: 14, color: AppColors.primary),
                    label: const Text('Cloud Vercel (Default)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    onPressed: () => _setPreset(ApiEndpoints.defaultBaseUrl),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.phone_android, size: 14, color: AppColors.secondary),
                    label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => _setPreset('http://10.0.2.2:3000'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.computer, size: 14, color: AppColors.textMuted),
                    label: const Text('Localhost (Port 3000)', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => _setPreset('http://localhost:3000'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input TextField
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Alamat Server Base URL',
                  hintText: ApiEndpoints.defaultBaseUrl,
                  prefixIcon: const Icon(Icons.link, color: AppColors.secondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Uji Koneksi
              OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.network_check, size: 18),
                label: Text(_isTesting ? 'Menguji Koneksi...' : 'Uji Tes Koneksi ke Server'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Hasil Tes
              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _testSuccess ? AppColors.statusApprovedBg : AppColors.statusRejectedBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess ? AppColors.statusApproved : AppColors.statusRejected,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _testSuccess ? AppColors.statusApproved : AppColors.statusRejected,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Actions Simpan & Batal
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveAndApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Simpan & Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
