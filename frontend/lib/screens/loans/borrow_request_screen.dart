import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/session_manager.dart';
import '../../models/loan_model.dart';
import 'borrow_detail_screen.dart';

class BorrowRequestScreen extends StatefulWidget {
  const BorrowRequestScreen({super.key});

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  List<LoanModel> _loans = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'Semua';
  bool _isAssistant = false;
  bool _showTrash = false;
  String? _userId;

  List<String> get _statusFilters => [
        'Semua',
        'Pending',
        'Approved',
        'Returning',
        'Returned',
        'Rejected',
      ];

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final isAst = await SessionManager.isAssistant();
    final uid = await SessionManager.getUserId();
    setState(() {
      _isAssistant = isAst;
      _userId = uid;
    });
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, String> query = {};
      // Jika mahasiswa, hanya ambil riwayat miliknya
      if (!_isAssistant && _userId != null) {
        query['user_id'] = _userId!;
      }
      if (_showTrash) {
        query['is_deleted'] = 'true';
      } else {
        query['is_deleted'] = 'false';
        if (_selectedStatus != 'Semua') {
          query['status'] = _selectedStatus.toLowerCase();
        }
      }

      final res = await ApiClient.get(ApiEndpoints.loans, queryParams: query);
      if (res != null && res['data'] != null) {
        final List list = res['data'];
        setState(() {
          _loans = list.map((item) => LoanModel.fromJson(item)).toList();
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.statusApproved;
      case 'returning':
        return const Color(0xFF0284C7);
      case 'rejected':
        return AppColors.statusRejected;
      case 'returned':
        return AppColors.statusReturned;
      case 'pending':
      default:
        return AppColors.statusPending;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.statusApprovedBg;
      case 'returning':
        return const Color(0xFFE0F2FE);
      case 'rejected':
        return AppColors.statusRejectedBg;
      case 'returned':
        return AppColors.statusReturnedBg;
      case 'pending':
      default:
        return AppColors.statusPendingBg;
    }
  }

  void _showQuickDeleteLoanDialog(LoanModel loan) {
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
        content: Text(
          'Permohonan pinjam "${loan.component?.name ?? 'Modul'}" oleh ${loan.user?.name ?? 'Mahasiswa'} akan dipindahkan ke arsip sampah (Soft Delete).\n\nStok modul akan otomatis dipulihkan ke katalog, dan permohonan dapat dipulihkan sewaktu-waktu jika salah memencet.',
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
                final res = await ApiClient.delete(ApiEndpoints.loanById(loan.id));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res?['message'] ?? 'Permohonan pinjam berhasil dipindahkan ke arsip sampah!'),
                    backgroundColor: AppColors.statusApproved,
                  ),
                );
                _fetchLoans();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus: $e'),
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
                _fetchLoans();
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
          'Peringatan: Data permohonan pinjam "${loan.component?.name ?? 'Modul'}" oleh ${loan.user?.name ?? 'Mahasiswa'} akan dihapus secara PERMANEN dari basis data.\n\nTindakan ini TIDAK DAPAT dibatalkan. Apakah Anda yakin?',
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
                _fetchLoans();
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

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isAssistant ? 'Antrean Peminjaman Lab' : 'Riwayat Peminjaman Anda',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _isAssistant ? 'Tinjau & konfirmasi peminjaman alat' : 'Pantau status pengajuan modul Anda',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Segarkan Antrean',
            onPressed: _fetchLoans,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLoans,
        color: AppColors.primary,
        child: Column(
          children: [
            // Banner Arsip Terhapus (Trash Mode Khusus Asisten)
            if (_showTrash && _isAssistant)
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
                        'Menampilkan Arsip Permohonan Terhapus (Soft Delete). Klik "Pulihkan" atau "Hapus Permanen".',
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
                        _fetchLoans();
                      },
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusRejected),
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Status Chips (Hanya tampil saat mode aktif / bukan arsip)
            if (!_showTrash)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                  children: _statusFilters.map((st) {
                    final isSelected = _selectedStatus == st;
                    String label = st;
                    if (st == 'Pending') label = 'Menunggu';
                    if (st == 'Approved') label = 'Disetujui';
                    if (st == 'Returning') label = 'Menunggu Kembali';
                    if (st == 'Returned') label = 'Dikembalikan';
                    if (st == 'Rejected') label = 'Ditolak';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          label,
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
                              _selectedStatus = st;
                            });
                            _fetchLoans();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Loan List Content
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
                                const Icon(Icons.error_outline, size: 48, color: AppColors.statusRejected),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _fetchLoans,
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
                      : _loans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_turned_in_outlined,
                                      size: 56, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada data peminjaman',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isAssistant
                                        ? 'Belum ada antrean permohonan dari mahasiswa.'
                                        : 'Anda belum mengajukan peminjaman alat.',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _loans.length,
                              itemBuilder: (context, index) {
                                final loan = _loans[index];
                                final compName = loan.component?.name ?? 'Modul Hardware';
                                final borrowerName = loan.user?.name ?? 'Mahasiswa';
                                final borrowerNim = loan.user?.nimNip ?? '-';
                                final statusColor = _getStatusColor(loan.status);
                                final statusBgColor = _getStatusBgColor(loan.status);

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
                                      final changed = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BorrowDetailScreen(loan: loan),
                                        ),
                                      );
                                      if (changed == true) {
                                        _fetchLoans();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header Card: Komponen & Status Badge
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  compName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _showTrash ? AppColors.statusRejectedBg : statusBgColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _showTrash ? 'TERHAPUS' : loan.statusDisplay,
                                                  style: TextStyle(
                                                    color: _showTrash ? AppColors.statusRejected : statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              if (!_showTrash && _isAssistant) ...[
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: AppColors.statusRejected,
                                                  ),
                                                  tooltip: 'Hapus Permohonan (Soft Delete)',
                                                  onPressed: () => _showQuickDeleteLoanDialog(loan),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Info Peminjam
                                          Row(
                                            children: [
                                              const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$borrowerName ($borrowerNim)',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),

                                          // Rentang Waktu
                                          Row(
                                            children: [
                                              const Icon(Icons.date_range, size: 14, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_formatDate(loan.borrowDate)} s.d. ${_formatDate(loan.returnDate)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),

                                          // Tombol Arsip (Pulihkan & Hapus Permanen) atau Ringkasan & Rincian
                                          if (_showTrash && _isAssistant) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _showRestoreLoanDialog(loan),
                                                    icon: const Icon(Icons.restore_from_trash, size: 14),
                                                    label: const Text(
                                                      'Pulihkan',
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
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
                                                    label: const Text(
                                                      'Hapus Permanen',
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
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
                                          ] else ...[
                                            // Keperluan & Petunjuk Klik
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    loan.reason,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textMuted,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Row(
                                                  children: [
                                                    Text(
                                                      'Rincian',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.secondary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                                                  ],
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
