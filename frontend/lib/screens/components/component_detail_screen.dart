import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/lab_options.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/component_model.dart';

class ComponentDetailScreen extends StatefulWidget {
  final ComponentModel component;

  const ComponentDetailScreen({super.key, required this.component});

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  late ComponentModel _comp;
  bool _isAssistant = false;
  String? _currentUserId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _comp = widget.component;
    _loadUser();
    _fetchFreshComponent();
  }

  Future<void> _fetchFreshComponent() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.componentById(widget.component.id));
      if (res != null && res['data'] != null && mounted) {
        setState(() {
          _comp = ComponentModel.fromJson(res['data']);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUser() async {
    final isAst = await SessionManager.isAssistant();
    final uid = await SessionManager.getUserId();
    if (mounted) {
      setState(() {
        _isAssistant = isAst;
        _currentUserId = uid;
      });
    }
  }

  // Dialog / Modal Form Pengajuan Pinjam untuk Mahasiswa
  void _showBorrowModal() {
    DateTime borrowDate = DateTime.now();
    DateTime returnDate = DateTime.now().add(const Duration(days: 7));
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final dateFormat = DateFormat('dd MMM yyyy');

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
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Formulir Pengajuan Pinjam',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Komponen: ${_comp.name}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Divider(height: 24),

                      // Tanggal Peminjaman
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                        title: const Text('Tanggal Mulai Pinjam', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        subtitle: Text(
                          dateFormat.format(borrowDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: borrowDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                borrowDate = picked;
                                if (returnDate.isBefore(borrowDate)) {
                                  returnDate = borrowDate.add(const Duration(days: 3));
                                }
                              });
                            }
                          },
                          child: const Text('Pilih'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tanggal Pengembalian
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_repeat, color: AppColors.primary),
                        title: const Text('Batas Pengembalian', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        subtitle: Text(
                          dateFormat.format(returnDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: returnDate,
                              firstDate: borrowDate,
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                returnDate = picked;
                              });
                            }
                          },
                          child: const Text('Pilih'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input Keperluan
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Keperluan & Alasan Peminjaman',
                          hintText: 'Contoh: Pengerjaan Proyek Akhir Sistem Tertanam...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Harap jelaskan keperluan peminjaman modul ini';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tombol Submit
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(context); // Tutup modal
                                _submitLoanRequest(
                                  borrowDate: DateFormat('yyyy-MM-dd').format(borrowDate),
                                  returnDate: DateFormat('yyyy-MM-dd').format(returnDate),
                                  reason: reasonController.text.trim(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kirim Permohonan Pinjam',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitLoanRequest({
    required String borrowDate,
    required String returnDate,
    required String reason,
  }) async {
    if (_currentUserId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiClient.post(
        ApiEndpoints.loans,
        body: {
          'user_id': _currentUserId,
          'component_id': _comp.id,
          'borrow_date': borrowDate,
          'return_date': returnDate,
          'reason': reason,
        },
      );

      if (!mounted) return;
      setState(() {
        final newStock = (_comp.stock - 1) < 0 ? 0 : (_comp.stock - 1);
        _comp = ComponentModel(
          id: _comp.id,
          name: _comp.name,
          category: _comp.category,
          stock: newStock,
          location: _comp.location,
          description: _comp.description,
          datasheetUrl: _comp.datasheetUrl,
          createdAt: _comp.createdAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Permohonan pinjam berhasil diajukan!'),
          backgroundColor: AppColors.statusApproved,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Langsung kembali ke katalog utama dengan sinyal refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Dialog Asisten untuk edit stok, ruangan (dropdown), dan gambar komponen
  void _showEditStockDialog() {
    final stockController = TextEditingController(text: _comp.stock.toString());
    final List<String> roomChoices = [
      ...LabOptions.roomOptions,
      if (!LabOptions.roomOptions.contains(_comp.location) && _comp.location.trim().isNotEmpty)
        _comp.location,
    ];
    String selectedRoom = roomChoices.contains(_comp.location)
        ? _comp.location
        : LabOptions.roomOptions.first;
    String? editedImage = _comp.image;
    bool imageChanged = false;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          Future<void> pickCompImage(ImageSource source) async {
            try {
              final XFile? picked = await picker.pickImage(
                source: source,
                maxWidth: 600,
                maxHeight: 600,
                imageQuality: 75,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setDialogState(() {
                  editedImage = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  imageChanged = true;
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengambil gambar: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Komponen Lab',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Modul: ${_comp.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Preview & Upload Gambar Komponen
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: editedImage != null && editedImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: LabOptions.buildComponentImage(
                              editedImage,
                              width: double.infinity,
                              height: 130,
                              fit: BoxFit.cover,
                              fallback: const Center(child: Icon(Icons.memory, size: 36)),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.secondary),
                              SizedBox(height: 4),
                              Text('Belum ada gambar komponen', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickCompImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 15),
                          label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickCompImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 15),
                          label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (editedImage != null && editedImage!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            editedImage = null;
                            imageChanged = true;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.statusRejected),
                        label: const Text('Hapus Gambar', style: TextStyle(fontSize: 11.5, color: AppColors.statusRejected)),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Dropdown Ruangan Laboratorium
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoom,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ruangan Laboratorium',
                      prefixIcon: Icon(Icons.meeting_room_outlined, color: AppColors.secondary),
                      border: OutlineInputBorder(),
                    ),
                    items: roomChoices.map((room) {
                      return DropdownMenuItem(
                        value: room,
                        child: Text(room, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRoom = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Jumlah Stok
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Stok Baru',
                      prefixIcon: Icon(Icons.inventory, color: AppColors.secondary),
                      border: OutlineInputBorder(),
                    ),
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
                onPressed: () async {
                  final newStock = int.tryParse(stockController.text.trim());
                  if (newStock == null || newStock < 0) return;

                  Navigator.pop(ctx);
                  setState(() {
                    _isSubmitting = true;
                  });
                  try {
                    final Map<String, dynamic> body = {
                      'stock': newStock,
                      'location': selectedRoom,
                    };
                    if (imageChanged) {
                      body['image'] = editedImage;
                    }
                    final res = await ApiClient.put(
                      ApiEndpoints.componentById(_comp.id),
                      body: body,
                    );
                    if (res != null && res['data'] != null && mounted) {
                      setState(() {
                        _comp = ComponentModel.fromJson(res['data']);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data komponen (stok, ruangan & gambar) berhasil diperbarui!'),
                          backgroundColor: AppColors.statusApproved,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal memperbarui komponen: $e'),
                          backgroundColor: AppColors.statusRejected,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog Konfirmasi Hapus Modul (Fitur Asisten Praktikum - Soft Delete)
  void _showDeleteComponentDialog() {
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
                'Hapus Modul',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Modul "${_comp.name}" akan dipindahkan ke arsip sampah (Soft Delete) dan dapat dipulihkan sewaktu-waktu jika salah memencet.',
          style: const TextStyle(fontSize: 13, height: 1.4),
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
                _isSubmitting = true;
              });
              try {
                final res = await ApiClient.delete(ApiEndpoints.componentById(_comp.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Modul berhasil dipindahkan ke arsip sampah!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                Navigator.pop(context, true); // Kembali ke list & refresh
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus modul: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _isSubmitting = false;
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

  // Dialog Konfirmasi Hapus Permanen Modul (Fitur Asisten Praktikum - Hard Delete)
  void _showHardDeleteComponentDialog() {
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
                'Hapus Permanen Modul',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.statusRejected),
              ),
            ),
          ],
        ),
        content: Text(
          'Peringatan: Modul "${_comp.name}" akan dihapus secara PERMANEN dari basis data beserta seluruh riwayat peminjamannya.\n\nTindakan ini TIDAK DAPAT dibatalkan. Apakah Anda yakin?',
          style: const TextStyle(fontSize: 13, height: 1.4),
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
                _isSubmitting = true;
              });
              try {
                final res = await ApiClient.delete('${ApiEndpoints.componentById(_comp.id)}?hard=true');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Modul berhasil dihapus secara permanen!'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
                Navigator.pop(context, true); // Kembali ke katalog & refresh
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
                    _isSubmitting = false;
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

  // Pulihkan Modul dari Arsip Sampah
  Future<void> _restoreComponent() async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      final res = await ApiClient.post(ApiEndpoints.restoreComponent(_comp.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message'] ?? 'Modul berhasil dipulihkan ke katalog aktif!'),
          backgroundColor: AppColors.statusApproved,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulihkan modul: $e'),
          backgroundColor: AppColors.statusRejected,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasStock = _comp.stock > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Detail Komponen Lab',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isAssistant) ...[
            if (_comp.isDeleted) ...[
              IconButton(
                icon: const Icon(Icons.restore_from_trash, color: Colors.white),
                tooltip: 'Pulihkan Modul',
                onPressed: _isSubmitting ? null : _restoreComponent,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                tooltip: 'Hapus Permanen Modul',
                onPressed: _isSubmitting ? null : _showHardDeleteComponentDialog,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Hapus Modul (Soft Delete)',
                onPressed: _isSubmitting ? null : _showDeleteComponentDialog,
              ),
            ],
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header Visual
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
                    if (_comp.image != null && _comp.image!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LabOptions.buildComponentImage(
                          _comp.image,
                          width: double.infinity,
                          height: 190,
                          fit: BoxFit.cover,
                          fallback: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.memory,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.memory,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _comp.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _comp.category,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hasStock ? AppColors.statusApprovedBg : AppColors.statusRejectedBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasStock ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: hasStock ? AppColors.statusApproved : AppColors.statusRejected,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasStock ? 'Stok Tersedia: ${_comp.stock} Unit' : 'Stok Kosong (0 Unit)',
                                style: TextStyle(
                                  color: hasStock ? AppColors.statusApproved : AppColors.statusRejected,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Spesifikasi & Lokasi
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
                      'Informasi & Lokasi Fisik',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: Icons.place,
                      label: 'Ruangan Laboratorium',
                      value: _comp.location,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Deskripsi & Spesifikasi',
                      value: _comp.description,
                      color: AppColors.primary,
                    ),
                    if (_comp.datasheetUrl.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.link,
                        label: 'Datasheet / Referensi',
                        value: _comp.datasheetUrl,
                        color: AppColors.accent,
                        isLink: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Role Conditional Action Buttons (Hanya Asisten yang dapat Soft/Hard Delete atau Restore)
            if (_isAssistant) ...[
              if (_comp.isDeleted) ...[
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _restoreComponent,
                  icon: const Icon(Icons.restore_from_trash, color: Colors.white),
                  label: const Text(
                    'Pulihkan Modul ke Katalog Aktif',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusApproved,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _showHardDeleteComponentDialog,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'Hapus Permanen Modul',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRejected,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _showEditStockDialog,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Edit Gambar, Ruangan & Stok Modul'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _showDeleteComponentDialog,
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                  label: const Text(
                    'Hapus Modul dari Katalog Lab',
                    style: TextStyle(
                      color: AppColors.statusRejected,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.statusRejected),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Aksi Khusus Mahasiswa (Tidak ada opsi Delete maupun Restore)
              if (!_comp.isDeleted)
                ElevatedButton.icon(
                  onPressed: (hasStock && !_isSubmitting) ? _showBorrowModal : null,
                  icon: const Icon(Icons.assignment_add),
                  label: Text(
                    hasStock ? 'Ajukan Peminjaman Modul' : 'Stok Sedang Habis',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isLink ? AppColors.secondary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
