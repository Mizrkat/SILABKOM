class ComponentModel {
  final String id;
  final String name;
  final String category;
  final int stock;
  final String location;
  final String description;
  final String datasheetUrl;
  final String? image;
  final String? createdAt;
  final bool isDeleted;
  final String? deletedAt;

  ComponentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.location,
    required this.description,
    required this.datasheetUrl,
    this.image,
    this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  bool get isAvailable => stock > 0 && !isDeleted;

  factory ComponentModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString();
    return ComponentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      location: json['location']?.toString() ?? '-',
      description: json['description']?.toString() ?? '',
      datasheetUrl: json['datasheet_url']?.toString() ?? '',
      image: (rawImage != null && rawImage.isNotEmpty) ? rawImage : null,
      createdAt: json['created_at']?.toString(),
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 'true',
      deletedAt: json['deleted_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'stock': stock,
      'location': location,
      'description': description,
      'datasheet_url': datasheetUrl,
      'image': image,
      'created_at': createdAt,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt,
    };
  }
}
