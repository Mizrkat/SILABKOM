import 'user_model.dart';
import 'component_model.dart';

class LoanModel {
  final String id;
  final String userId;
  final String componentId;
  final String borrowDate;
  final String returnDate;
  final String reason;
  final String status; // 'pending', 'approved', 'returning', 'rejected', 'returned'
  final String? notes;
  final String? returnPhoto;
  final String? createdAt;
  final bool isDeleted;
  final String? deletedAt;
  final UserModel? user;
  final ComponentModel? component;

  LoanModel({
    required this.id,
    required this.userId,
    required this.componentId,
    required this.borrowDate,
    required this.returnDate,
    required this.reason,
    required this.status,
    this.notes,
    this.returnPhoto,
    this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
    this.user,
    this.component,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isReturning => status.toLowerCase() == 'returning';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isReturned => status.toLowerCase() == 'returned';

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'returning':
        return 'Menunggu Konfirmasi Kembali';
      case 'rejected':
        return 'Ditolak';
      case 'returned':
        return 'Dikembalikan';
      case 'pending':
      default:
        return 'Menunggu';
    }
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user']);
    }

    ComponentModel? parsedComponent;
    if (json['component'] != null && json['component'] is Map<String, dynamic>) {
      parsedComponent = ComponentModel.fromJson(json['component']);
    }

    return LoanModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      componentId: json['component_id']?.toString() ?? '',
      borrowDate: json['borrow_date']?.toString() ?? '',
      returnDate: json['return_date']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      returnPhoto: json['return_photo']?.toString(),
      createdAt: json['created_at']?.toString(),
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 'true',
      deletedAt: json['deleted_at']?.toString(),
      user: parsedUser,
      component: parsedComponent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'component_id': componentId,
      'borrow_date': borrowDate,
      'return_date': returnDate,
      'reason': reason,
      'status': status,
      'notes': notes,
      'return_photo': returnPhoto,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt,
      'created_at': createdAt,
    };
  }
}
