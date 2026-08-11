class News {
  final String id;
  final String title;
  final String? subtitle;
  final String content;
  final String type;
  final String? image;
  final List<String> targetRoles;
  final List<String> targetFamilies;
  final String? createdByName;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    this.subtitle,
    required this.content,
    required this.type,
    this.image,
    required this.targetRoles,
    required this.targetFamilies,
    this.createdByName,
    required this.isPublished,
    this.publishedAt,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) => News(
    id: json['_id'] ?? json['id'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'],
    content: json['content'] ?? '',
    type: json['type'] ?? 'general',
    image: json['image'],
    targetRoles: List<String>.from(json['target_roles'] ?? []),
    targetFamilies: List<String>.from(json['target_families'] ?? []),
    createdByName: json['created_by_name'],
    isPublished: json['is_published'] ?? false,
    publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at']) : null,
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  String get typeLabel {
    switch (type) {
      case 'obituary': return 'نعي';
      case 'wedding': return 'عرس';
      case 'announcement': return 'إعلان';
      case 'important': return 'مهم';
      case 'admin_alert': return 'إعلان إداري';
      case 'social_occasion': return 'مناسبة اجتماعية';
      default: return 'خبر';
    }
  }
}
