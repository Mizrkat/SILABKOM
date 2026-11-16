import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
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
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _datasheetController = TextEditingController();

  String _selectedCategory = 'Mikrokontroler';
  bool _isLoading = false;

  final List<String> _categoryOptions = [
    'Mikrokontroler',
    'Sensor & Modul',
    'Alat Ukur & Debugger',
    'FPGA & IC',
    'Komponen Pasif & Aktuator',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _datasheetController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await ApiClient.post(
        ApiEndpoints.components,
        body: {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'stock': int.tryParse(_stockController.text.trim()) ?? 0,
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'datasheet_url': _datasheetController.text.trim(),
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
        _locationController.clear();
        _descriptionController.clear();
        _datasheetController.clear();
        setState(() {
          _selectedCategory = 'Mikrokontroler';
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
                    items: _categoryOptions.map((cat) {
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
                  const SizedBox(height: 16),

                  // Stok & Lokasi
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Lokasi Rak/Loker',
                            hintText: 'Loker A-04',
                            prefixIcon: const Icon(Icons.place, color: AppColors.secondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                            return null;
                          },
                        ),
                      ),
                    ],
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
