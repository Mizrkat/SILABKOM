import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/loan_model.dart';

class BorrowDetailScreen extends StatefulWidget {
  final LoanModel loan;

  const BorrowDetailScreen({super.key, required this.loan});

  @override
  State<BorrowDetailScreen> createState() => _BorrowDetailScreenState();
}

class _BorrowDetailScreenState extends State<BorrowDetailScreen> {
  late LoanModel _currentLoan;
  bool _isAssistant = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isAst = await SessionManager.isAssistant();
    if (mounted) {
      setState(() {
        _isAssistant = isAst;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      try {
        final parsed = DateTime.parse(dateStr);
        return DateFormat('dd MMMM yyyy').format(parsed);
      } catch (_) {
        return dateStr;
      }
    }
  }

  Future<void> _updateStatus(String status, {String? notes, String? returnPhoto}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final Map<String, dynamic> body = {
        'status': status,
        'notes': notes ?? _currentLoan.notes ?? '',
      };
      if (returnPhoto != null) {
        body['return_photo'] = returnPhoto;
      }

      final res = await ApiClient.patch(
        ApiEndpoints.updateLoanStatus(_currentLoan.id),
        body: body,
      );

      if (res != null && res['data'] != null) {
        setState(() {
          _currentLoan = LoanModel.fromJson(res['data']);
        });

        if (!mounted) return;
        Color snackBg = AppColors.statusApproved;
        if (status == 'rejected') snackBg = AppColors.statusRejected;
        if (status == 'returning') snackBg = AppColors.statusReturning;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Status peminjaman berhasil diperbarui!'),
            backgroundColor: snackBg,
          ),
        );
        Navigator.pop(context, true); // Kembali dengan flag perubahan data
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Modal Kamera untuk Mahasiswa saat mengembalikan barang
  void _showReturnCameraModal() {
    File? selectedImage;
    String? base64Image;
    final notesController = TextEditingController();
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pengembalian Modul Lab',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modul: ${_currentLoan.component?.name ?? "Komponen"}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.camera_alt, size: 20, color: AppColors.secondary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Silakan foto bukti fisik barang yang ditaruh di lab/meja asisten untuk diverifikasi.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Area Preview Foto
                    if (selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              selectedImage!,
                              height: 190,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  selectedImage = null;
                                  base64Image = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // Tombol Kamera & Galeri
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final photo = await picker.pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 700,
                                  maxHeight: 700,
                                  imageQuality: 65,
                                );
                                if (photo != null) {
                                  final bytes = await File(photo.path).readAsBytes();
                                  setModalState(() {
                                    selectedImage = File(photo.path);
                                    base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                  });
                                }
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Buka Kamera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final photo = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 700,
                                  maxHeight: 700,
                                  imageQuality: 65,
                                );
                                if (photo != null) {
                                  final bytes = await File(photo.path).readAsBytes();
                                  setModalState(() {
                                    selectedImage = File(photo.path);
                                    base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Dari Galeri'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Catatan Pengembalian
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Catatan Pengembalian (Opsional)',
                        hintText: 'Misal: Modul & kabel jumper ditaruh di loker...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Submit Pengembalian
                    ElevatedButton(
                      onPressed: selectedImage == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _updateStatus(
                                'returning',
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : 'Mahasiswa telah menyerahkan modul ke lab dan mengunggah foto bukti fisik.',
                                returnPhoto: base64Image,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusReturning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        selectedImage == null
                            ? 'Ambil Foto Barang Terlebih Dahulu'
                            : 'Kirim Bukti Pengembalian',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectDialog() {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Permohonan Pinjam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Berikan catatan atau alasan penolakan kepada mahasiswa:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Misal: Modul sedang dipreservasi untuk praktikum...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = notesController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              _updateStatus('rejected', notes: reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Permohonan'),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus Permohonan Pinjam (Fitur Asisten - Soft Delete)
  void _showDeleteLoanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusRejected),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Permohonan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Permohonan peminjaman ini akan dipindahkan ke arsip sampah (Soft Delete).\n\nJika belum berstatus dikembalikan, stok kuota komponen otomatis dipulihkan ke katalog, dan Anda dapat memulihkan permohonan ini sewaktu-waktu jika salah memencet.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = true;
              });
              try {
                final res = await ApiClient.delete(ApiEndpoints.loanById(_currentLoan.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Permohonan peminjaman berhasil dipindahkan ke arsip sampah!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                Navigator.pop(context, true); // Kembali & segarkan antrean
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus permohonan: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pindahkan ke Sampah'),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus Permanen Permohonan Pinjam (Fitur Asisten - Hard Delete)
  void _showHardDeleteLoanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.statusRejected),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Permanen Permohonan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.statusRejected),
              ),
            ),
          ],
        ),
        content: const Text(
          'Peringatan: Data permohonan peminjaman ini akan dihapus secara PERMANEN dari basis data.\n\nTindakan ini TIDAK DAPAT dibatalkan. Apakah Anda yakin?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = true;
              });
              try {
                final res = await ApiClient.delete('${ApiEndpoints.loanById(_currentLoan.id)}?hard=true');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Permohonan peminjaman berhasil dihapus secara permanen!'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
                Navigator.pop(context, true); // Kembali & segarkan antrean
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus permanen: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  // Pulihkan Permohonan Pinjam dari Arsip Sampah
  Future<void> _restoreLoan() async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final res = await ApiClient.post(ApiEndpoints.restoreLoan(_currentLoan.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message'] ?? 'Permohonan pinjam berhasil dipulihkan!'),
          backgroundColor: AppColors.statusApproved,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulihkan permohonan: $e'),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildPhotoView(String photoStr) {
    Widget imageWidget;
    if (photoStr.startsWith('http')) {
      imageWidget = Image.network(
        photoStr,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      try {
        final clean = photoStr.contains(',') ? photoStr.split(',').last : photoStr;
        imageWidget = Image.memory(
          base64Decode(clean),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {
        imageWidget = const SizedBox(
          height: 100,
          child: Center(child: Icon(Icons.broken_image, size: 40, color: AppColors.textMuted)),
        );
      }
    }

    return Card(
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
            const Row(
              children: [
                Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Foto Bukti Pengembalian Fisik',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comp = _currentLoan.component;
    final user = _currentLoan.user;

    Color statusColor;
    Color statusBgColor;
    switch (_currentLoan.status.toLowerCase()) {
      case 'approved':
        statusColor = AppColors.statusApproved;
        statusBgColor = AppColors.statusApprovedBg;
        break;
      case 'returning':
        statusColor = AppColors.statusReturning;
        statusBgColor = AppColors.statusReturningBg;
        break;
      case 'rejected':
        statusColor = AppColors.statusRejected;
        statusBgColor = AppColors.statusRejectedBg;
        break;
      case 'returned':
        statusColor = AppColors.statusReturned;
        statusBgColor = AppColors.statusReturnedBg;
        break;
      case 'pending':
      default:
        statusColor = AppColors.statusPending;
        statusBgColor = AppColors.statusPendingBg;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Permohonan Pinjam',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isAssistant) ...[
            if (_currentLoan.isDeleted) ...[
              IconButton(
                icon: const Icon(Icons.restore_from_trash, color: Colors.white),
                tooltip: 'Pulihkan Permohonan',
                onPressed: _isProcessing ? null : _restoreLoan,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                tooltip: 'Hapus Permanen',
                onPressed: _isProcessing ? null : _showHardDeleteLoanDialog,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Hapus Permohonan (Soft Delete)',
                onPressed: _isProcessing ? null : _showDeleteLoanDialog,
              ),
            ],
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _currentLoan.isApproved
                            ? Icons.verified
                            : _currentLoan.isReturning
                                ? Icons.pending_actions
                                : _currentLoan.isRejected
                                    ? Icons.cancel
                                    : _currentLoan.isReturned
                                        ? Icons.task_alt
                                        : Icons.hourglass_top,
                        color: statusColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Permohonan',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentLoan.statusDisplay.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Rincian Peminjam & Komponen
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
                    const Text(
                      'Informasi Pemohon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildRow(Icons.person, 'Nama Mahasiswa', user?.name ?? 'Mahasiswa Lab'),
                    const SizedBox(height: 12),
                    _buildRow(Icons.badge, 'NIM', user?.nimNip ?? '-'),
                    const SizedBox(height: 20),

                    const Text(
                      'Komponen yang Dipinjam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildRow(Icons.memory, 'Nama Perangkat', comp?.name ?? 'Modul Hardware'),
                    const SizedBox(height: 12),
                    _buildRow(Icons.category, 'Kategori', comp?.category ?? '-'),
                    const SizedBox(height: 12),
                    _buildRow(Icons.place, 'Lokasi Rak / Loker', comp?.location ?? '-'),
                    const SizedBox(height: 20),

                    const Text(
                      'Jadwal & Keperluan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildRow(Icons.calendar_today, 'Tanggal Pinjam', _formatDate(_currentLoan.borrowDate)),
                    const SizedBox(height: 12),
                    _buildRow(Icons.event_repeat, 'Batas Kembali', _formatDate(_currentLoan.returnDate)),
                    const SizedBox(height: 12),
                    _buildRow(Icons.notes, 'Alasan / Proyek', _currentLoan.reason),
                    if (_currentLoan.notes != null && _currentLoan.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildRow(Icons.comment, 'Catatan', _currentLoan.notes!, isHighlight: true),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tampilkan Foto Bukti jika ada
            if (_currentLoan.returnPhoto != null && _currentLoan.returnPhoto!.isNotEmpty) ...[
              _buildPhotoView(_currentLoan.returnPhoto!),
              const SizedBox(height: 16),
            ],

            // ==============================================================================
            // AKSI BERBASIS ROLE (MAHASISWA & ASISTEN)
            // ==============================================================================

            // 1. Aksi Khusus Mahasiswa
            if (!_isAssistant) ...[
              if (_currentLoan.isApproved) ...[
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showReturnCameraModal,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Kembalikan Barang (Buka Kamera)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusReturning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (_currentLoan.isReturning) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusReturningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusReturning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, color: AppColors.statusReturning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Foto pengembalian telah dikirim. Menunggu asisten lab mengonfirmasi penerimaan fisik barang di lab.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.statusReturning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // 2. Aksi Khusus Asisten Lab (Soft Delete / Restore / Hard Delete)
            if (_isAssistant) ...[
              if (_currentLoan.isDeleted) ...[
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _restoreLoan,
                  icon: const Icon(Icons.restore_from_trash, color: Colors.white),
                  label: const Text(
                    'Pulihkan Permohonan ke Antrean Aktif',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusApproved,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showHardDeleteLoanDialog,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'Hapus Permanen Permohonan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRejected,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                // Kasus 1: Peminjaman baru butuh approval
                if (_currentLoan.isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _showRejectDialog,
                          icon: const Icon(Icons.close, color: AppColors.statusRejected),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(color: AppColors.statusRejected, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.statusRejected),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _updateStatus('approved', notes: 'Disetujui oleh asisten lab.'),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Setujui Pinjam',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusApproved,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // Kasus 2: Mahasiswa sudah serahkan barang & upload foto kamera (Status Returning)
                else if (_currentLoan.isReturning) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.statusApprovedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.statusApproved, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mahasiswa telah mengunggah bukti fisik pengembalian. Silakan periksa alat di lab dan klik konfirmasi di bawah:',
                            style: TextStyle(fontSize: 12, color: AppColors.statusApproved, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus('returned', notes: 'Dikonfirmasi diterima oleh asisten lab.'),
                    icon: const Icon(Icons.verified, color: Colors.white),
                    label: const Text(
                      'Konfirmasi Barang Telah Dikembalikan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusApproved,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]
                // Kasus 3: Barang sedang dipinjam (bisa konfirmasi manual langsung jika mahasiswa mengembalikan tanpa aplikasi)
                else if (_currentLoan.isApproved) ...[
                  OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus('returned', notes: 'Alat telah dikembalikan langsung secara manual.'),
                    icon: const Icon(Icons.assignment_turned_in, color: AppColors.primary),
                    label: const Text('Konfirmasi Pengembalian Manual'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                // Tombol Hapus Permohonan (Aksi Asisten Lab)
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _showDeleteLoanDialog,
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                  label: const Text(
                    'Pindahkan ke Sampah (Soft Delete)',
                    style: TextStyle(color: AppColors.statusRejected, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusRejected),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isHighlight ? AppColors.statusPending : AppColors.secondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? AppColors.statusPending : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
