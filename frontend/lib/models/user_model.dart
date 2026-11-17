class UserModel {
  final String id;
  final String name;
  final String nimNip;
  final String role; // 'student' | 'assistant'
  final String? avatar;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.nimNip,
    required this.role,
    this.avatar,
    this.createdAt,
  });

  bool get isAssistant => role == 'assistant';
  bool get isStudent => role == 'student';

  String get roleDisplayTitle => isAssistant ? 'Asisten Laboratorium' : 'Mahasiswa';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nimNip: json['nim_nip']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      avatar: json['avatar']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nim_nip': nimNip,
      'role': role,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }
}
