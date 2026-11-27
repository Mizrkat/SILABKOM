import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/lab_options.dart';
import '../../core/network/api_client.dart';

class AddComponentScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onModuleAdded;

  const AddComponentScreen({
    super.key,
    this.isEmbedded = false,
    this.onModuleAdded,
  });

  @override
  State<AddComponentScreen> createState() => _AddComponentScreenState();
}

class _AddComponentScreenState extends State<AddComponentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _datasheetController = TextEditingController();

  String _selectedCategory = LabOptions.addComponentCategories.first;
  String _selectedRoom = LabOptions.roomOptions.first;
  String? _selectedImageBase64;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    _datasheetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (mounted) {
          setState(() {
            _selectedImageBase64 = base64String;
          });
        }
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
                'Pilih Gambar Komponen / Modul',
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
              if (_selectedImageBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                  title: const Text('Hapus Gambar Pilihan', style: TextStyle(color: AppColors.statusRejected)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedImageBase64 = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String finalCategory = _selectedCategory == 'Lainnya'
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    try {
      final res = await ApiClient.post(
        ApiEndpoints.components,
        body: {
          'name': _nameController.text.trim(),
          'category': finalCategory,
          'stock': int.tryParse(_stockController.text.trim()) ?? 0,
          'location': _selectedRoom,
          'description': _descriptionController.text.trim(),
          'datasheet_url': _datasheetController.text.trim(),
          if (_selectedImageBase64 != null) 'image': _selectedImageBase64,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Komponen baru berhasil ditambahkan!'),
          backgroundColor: AppColors.statusApproved,
        ),
      );

      if (widget.isEmbedded) {
        _nameController.clear();
        _stockController.clear();
        _customCategoryController.clear();
        _descriptionController.clear();
        _datasheetController.clear();
        setState(() {
          _selectedCategory = LabOptions.addComponentCategories.first;
          _selectedRoom = LabOptions.roomOptions.first;
          _selectedImageBase64 = null;
        });
        widget.onModuleAdded?.call();
      } else {
        Navigator.pop(context, true);
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: const Text(
          'Tambah Modul Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Spesifikasi Perangkat Laboratorium',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Poin (a): Section Upload Gambar Komponen
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.image_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Gambar Komponen / Modul',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImageBase64 != null)
                              TextButton.icon(
                                onPressed: () => setState(() => _selectedImageBase64 = null),
                                icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.statusRejected),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(fontSize: 12, color: AppColors.statusRejected),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _showImagePickerOptions,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedImageBase64 != null
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: _selectedImageBase64 != null ? 1.5 : 1,
                              ),
                            ),
                            child: _selectedImageBase64 != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: LabOptions.buildComponentImage(
                                      _selectedImageBase64,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      fallback: const Center(
                                        child: Icon(Icons.broken_image, color: AppColors.textMuted),
                                      ),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.secondary),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ketuk untuk tambah gambar komponen',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Pilih dari Galeri atau ambil langsung lewat Kamera',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _showImagePickerOptions,
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(
                            _selectedImageBase64 != null ? 'Ganti Gambar Komponen' : 'Pilih / Upload Gambar',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama Modul
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Perangkat / Modul',
                      hintText: 'Misal: Raspberry Pi Pico W',
                      prefixIcon: const Icon(Icons.memory, color: AppColors.secondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Nama komponen wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kategori Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori Modul',
                      prefixIcon: const Icon(Icons.category, color: AppColors.secondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: LabOptions.addComponentCategories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                  ),

                  // Poin (e): Card Penjabaran Khusus saat Kategori 'Lainnya' dipilih
                  if (_selectedCategory == 'Lainnya') ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: AppColors.statusReturningBg.withValues(alpha: 0.65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.45)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Penjabaran Kategori "Lainnya"',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Kategori ini digunakan untuk komponen yang tidak termasuk ke dalam kategori sebelumnya (Mikrokontroler, Sensor & Modul, Alat Ukur & Debugger, FPGA & IC, Komponen Pasif & Aktuator). Tuliskan kategori spesifiknya di bawah ini:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _customCategoryController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Nama Kategori Baru / Spesifik',
                                hintText: 'Misal: Kabel & Konektor, Power Supply, Perangkat Jaringan',
                                prefixIcon: const Icon(Icons.label_outline, color: AppColors.secondary),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) {
                                if (_selectedCategory == 'Lainnya' &&
                                    (val == null || val.trim().isEmpty)) {
                                  return 'Harap tuliskan nama kategori untuk opsi Lainnya';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Jumlah Stok
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Stok',
                      hintText: 'Contoh: 10',
                      prefixIcon: const Icon(Icons.inventory, color: AppColors.secondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null || parsed < 0) return 'Stok tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Poin (b): Section Khusus Dropdown Ruangan Laboratorium
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Ruangan Laboratorium',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih ruangan laboratorium tempat penyimpanan komponen dari daftar opsi berikut:',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRoom,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Pilih Ruangan Lab',
                            prefixIcon: const Icon(Icons.place, color: AppColors.secondary),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: LabOptions.roomOptions.map((room) {
                            return DropdownMenuItem(
                              value: room,
                              child: Text(room, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRoom = val;
                              });
                            }
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Ruangan laboratorium wajib dipilih';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Opsi Ruangan Tersedia:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: LabOptions.roomOptions.map((room) {
                            final isPicked = _selectedRoom == room;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPicked
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPicked ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Text(
                                room,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isPicked ? FontWeight.bold : FontWeight.normal,
                                  color: isPicked ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi & Fitur Utama',
                      hintText: 'Penjelasan spesifikasi mikrokontroler, clock speed, pinout...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Datasheet URL
                  TextFormField(
                    controller: _datasheetController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'URL Datasheet / Dokumentasi (Opsional)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link, color: AppColors.secondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Informasi Proteksi Soft Delete
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: AppColors.secondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modul yang didaftarkan dilindungi fitur Soft Delete. Data tidak akan terhapus permanen dan dapat dipulihkan dari arsip sampah.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Simpan ke Katalog Lab',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
