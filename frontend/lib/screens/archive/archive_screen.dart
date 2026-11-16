import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/component_model.dart';
import '../../models/loan_model.dart';

class ArchiveScreen extends StatefulWidget {
  final VoidCallback? onRestored;

  const ArchiveScreen({super.key, this.onRestored});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ComponentModel> _deletedComponents = [];
  bool _isLoadingComponents = true;
  String? _componentsError;

  List<LoanModel> _deletedLoans = [];
  bool _isLoadingLoans = true;
  String? _loansError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDeletedComponents();
    _fetchDeletedLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeletedComponents() async {
    setState(() {
      _isLoadingComponents = true;
      _componentsError = null;
    });

    try {
      final res = await ApiClient.get(
        ApiEndpoints.components,
        queryParams: {'is_deleted': 'true'},
      );
      if (res != null && res['data'] != null) {
        final List list = res['data'];
        setState(() {
          _deletedComponents = list.map((item) => ComponentModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _componentsError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComponents = false;
        });
      }
    }
  }

  Future<void> _fetchDeletedLoans() async {
    setState(() {
      _isLoadingLoans = true;
      _loansError = null;
    });

    try {
      final res = await ApiClient.get(
        ApiEndpoints.loans,
        queryParams: {'is_deleted': 'true'},
      );
      if (res != null && res['data'] != null) {
        final List list = res['data'];
        setState(() {
          _deletedLoans = list.map((item) => LoanModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        _loansError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLoans = false;
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

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  // --- DIALOG MODUL ---
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
                _fetchDeletedComponents();
                widget.onRestored?.call();
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
          'Peringatan: Modul "${comp.name}" akan dihapus secara PERMANEN dari basis data beserta seluruh riwayat peminjamannya.\n\nTindakan ini TIDAK DAPAT dibatalkan. Lanjutkan?',
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
                _fetchDeletedComponents();
                widget.onRestored?.call();
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

  // --- DIALOG PERMOHONAN ---
  void _showRestoreLoanDialog(LoanModel loan) {
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
                'Pulihkan Permohonan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Pulihkan permohonan pinjam "${loan.component?.name ?? 'Modul'}" oleh ${loan.user?.name ?? 'Mahasiswa'} kembali ke antrean aktif?',
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
                final res = await ApiClient.post(ApiEndpoints.restoreLoan(loan.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Permohonan pinjam berhasil dipulihkan!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                _fetchDeletedLoans();
                widget.onRestored?.call();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memulihkan: $e'),
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

  void _showHardDeleteLoanDialog(LoanModel loan) {
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
        content: Text(
          'Peringatan: Data permohonan pinjam "${loan.component?.name ?? 'Modul'}" oleh ${loan.user?.name ?? 'Mahasiswa'} akan dihapus secara PERMANEN dari basis data.\n\nTindakan ini TIDAK DAPAT dibatalkan. Lanjutkan?',
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
                final res = await ApiClient.delete('${ApiEndpoints.loanById(loan.id)}?hard=true');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Permohonan pinjam berhasil dihapus secara permanen!'),
                    backgroundColor: AppColors.statusRejected,
                  ),
                );
                _fetchDeletedLoans();
                widget.onRestored?.call();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arsip & Sampah Lab',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kelola data modul & permohonan yang diarsip (Soft Delete)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan Arsip',
            onPressed: () {
              _fetchDeletedComponents();
              _fetchDeletedLoans();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.memory, size: 20), text: 'Modul Terhapus'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Permohonan Terhapus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComponentsTabView(),
          _buildLoansTabView(),
        ],
      ),
    );
  }

  Widget _buildComponentsTabView() {
    if (_isLoadingComponents) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_componentsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
              const SizedBox(height: 12),
              Text(_componentsError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchDeletedComponents,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_deletedComponents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 14),
            Text(
              'Arsip Modul Kosong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Tidak ada modul yang berada di arsip sampah.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDeletedComponents,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedComponents.length,
        itemBuilder: (context, index) {
          final comp = _deletedComponents[index];

          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getCategoryIcon(comp.category), color: AppColors.statusRejected, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comp.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    comp.category,
                                    style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 2),
                                    Text(comp.location, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TERHAPUS',
                          style: TextStyle(color: AppColors.statusRejected, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (comp.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comp.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestoreComponentDialog(comp),
                          icon: const Icon(Icons.restore_from_trash, size: 14),
                          label: const Text('Pulihkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusApproved,
                            side: const BorderSide(color: AppColors.statusApproved),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showHardDeleteComponentDialog(comp),
                          icon: const Icon(Icons.delete_forever, size: 14),
                          label: const Text('Hapus Permanen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusRejected,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoansTabView() {
    if (_isLoadingLoans) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_loansError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
              const SizedBox(height: 12),
              Text(_loansError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchDeletedLoans,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_deletedLoans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 14),
            Text(
              'Arsip Permohonan Kosong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Tidak ada permohonan pinjam di arsip sampah.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDeletedLoans,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedLoans.length,
        itemBuilder: (context, index) {
          final loan = _deletedLoans[index];
          final compName = loan.component?.name ?? 'Modul Hardware';
          final borrowerName = loan.user?.name ?? 'Mahasiswa';
          final borrowerNim = loan.user?.nimNip ?? '-';

          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          compName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TERHAPUS',
                          style: TextStyle(color: AppColors.statusRejected, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '$borrowerName ($borrowerNim)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(loan.borrowDate)} s.d. ${_formatDate(loan.returnDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (loan.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      loan.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestoreLoanDialog(loan),
                          icon: const Icon(Icons.restore_from_trash, size: 14),
                          label: const Text('Pulihkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusApproved,
                            side: const BorderSide(color: AppColors.statusApproved),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showHardDeleteLoanDialog(loan),
                          icon: const Icon(Icons.delete_forever, size: 14),
                          label: const Text('Hapus Permanen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusRejected,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
