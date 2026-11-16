import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/component_model.dart';
import 'component_detail_screen.dart';

class ComponentListScreen extends StatefulWidget {
  const ComponentListScreen({super.key});

  @override
  State<ComponentListScreen> createState() => _ComponentListScreenState();
}

class _ComponentListScreenState extends State<ComponentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ComponentModel> _components = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Semua';
  bool _isAssistant = false;
  bool _showTrash = false;

  final List<String> _categories = [
    'Semua',
    'Mikrokontroler',
    'Sensor & Modul',
    'Alat Ukur & Debugger',
    'FPGA & IC',
  ];

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchComponents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkRole() async {
    final isAst = await SessionManager.isAssistant();
    if (mounted) {
      setState(() {
        _isAssistant = isAst;
      });
    }
  }

  Future<void> _fetchComponents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, String> query = {};
      if (_selectedCategory != 'Semua') {
        query['category'] = _selectedCategory;
      }
      if (_searchController.text.trim().isNotEmpty) {
        query['search'] = _searchController.text.trim();
      }
      if (_isAssistant && _showTrash) {
        query['is_deleted'] = 'true';
      } else {
        query['is_deleted'] = 'false';
      }

      final response = await ApiClient.get(ApiEndpoints.components, queryParams: query);
      if (response != null && response['data'] != null) {
        final List list = response['data'];
        setState(() {
          _components = list.map((item) => ComponentModel.fromJson(item)).toList();
        });
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mikrokontroler':
        return Icons.memory;
      case 'sensor & modul':
        return Icons.sensors;
      case 'alat ukur & debugger':
        return Icons.build_circle_outlined;
      case 'fpga & ic':
        return Icons.developer_board;
      default:
        return Icons.category_outlined;
    }
  }

  void _showQuickDeleteComponentDialog(ComponentModel comp) {
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
          'Modul "${comp.name}" akan dipindahkan ke arsip sampah (Soft Delete) dan dapat dipulihkan sewaktu-waktu jika salah memencet.',
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
              try {
                final res = await ApiClient.delete(ApiEndpoints.componentById(comp.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Modul berhasil dipindahkan ke arsip sampah!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                _fetchComponents();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus modul: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
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

  void _showRestoreComponentDialog(ComponentModel comp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore_from_trash, color: AppColors.statusApproved),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pulihkan Modul',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Pulihkan modul "${comp.name}" kembali ke katalog laboratorium aktif?',
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
              try {
                final res = await ApiClient.post(ApiEndpoints.restoreComponent(comp.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Modul berhasil dipulihkan kembali ke katalog aktif!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                _fetchComponents();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memulihkan modul: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusApproved,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pulihkan Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showHardDeleteComponentDialog(ComponentModel comp) {
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
          'Peringatan: Modul "${comp.name}" akan dihapus secara PERMANEN dari basis data beserta riwayat peminjamannya.\n\nTindakan ini TIDAK DAPAT dibatalkan. Apakah Anda yakin?',
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
              try {
                final res = await ApiClient.delete('${ApiEndpoints.componentById(comp.id)}?hard=true');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Modul berhasil dihapus secara permanen!'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
                _fetchComponents();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus permanen: $e'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventaris Komponen Lab',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isAssistant ? 'Mode Asisten: Manajemen & Sirkulasi' : 'Peminjaman Alat & Modul Sisfo',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan Data',
            onPressed: _fetchComponents,
          ),
        ],
      ),
      floatingActionButton: null,
      body: RefreshIndicator(
        onRefresh: _fetchComponents,
        color: AppColors.primary,
        child: Column(
          children: [
            // Banner Arsip Terhapus (Trash Mode)
            if (_showTrash)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.statusRejectedBg,
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: AppColors.statusRejected),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Menampilkan Arsip Modul Terhapus (Soft Delete). Klik "Pulihkan" untuk mengembalikan modul ke katalog.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusRejected,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showTrash = false;
                        });
                        _fetchComponents();
                      },
                      child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Search Bar & Filter Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: AppColors.surface,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _fetchComponents(),
                    decoration: InputDecoration(
                      hintText: 'Cari modul, sensor, atau alat...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                _fetchComponents();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceVariant,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                                _fetchComponents();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchComponents,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Coba Lagi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _components.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada komponen ditemukan',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Coba sesuaikan kata kunci pencarian atau kategori.',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _components.length,
                              itemBuilder: (context, index) {
                                final comp = _components[index];
                                final bool hasStock = comp.stock > 0;

                                return Card(
                                  elevation: 1.5,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  color: AppColors.surface,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ComponentDetailScreen(component: comp),
                                        ),
                                      );
                                      // Selalu segarkan katalog secara realtime begitu kembali dari detail
                                      _fetchComponents();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                          // Icon Box
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(comp.category),
                                              color: AppColors.primary,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comp.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.surfaceVariant,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        comp.category,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.secondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.place_outlined,
                                                            size: 13, color: AppColors.textMuted),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          comp.location,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  comp.description,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Stock Badge
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: hasStock
                                                      ? AppColors.statusApprovedBg
                                                      : AppColors.statusRejectedBg,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  hasStock ? 'Tersedia: ${comp.stock}' : 'Stok Habis',
                                                  style: TextStyle(
                                                    color: hasStock
                                                        ? AppColors.statusApproved
                                                        : AppColors.statusRejected,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              if (!_showTrash && _isAssistant) ...[
                                                const SizedBox(height: 8),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: AppColors.statusRejected,
                                                  ),
                                                  tooltip: 'Hapus Modul (Soft Delete)',
                                                  onPressed: () => _showQuickDeleteComponentDialog(comp),
                                                ),
                                              ] else if (!_showTrash) ...[
                                                const SizedBox(height: 14),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  color: AppColors.textMuted,
                                                  size: 20,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Tombol Pulihkan & Hapus Permanen (Khusus Asisten pada Mode Arsip Sampah)
                                      if (_showTrash && _isAssistant) ...[
                                        const Divider(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showRestoreComponentDialog(comp),
                                                icon: const Icon(Icons.restore_from_trash, size: 14),
                                                label: const Text(
                                                  'Pulihkan',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.statusApproved,
                                                  side: const BorderSide(color: AppColors.statusApproved),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showHardDeleteComponentDialog(comp),
                                                icon: const Icon(Icons.delete_forever, size: 14),
                                                label: const Text(
                                                  'Hapus Permanen',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.statusRejected,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
