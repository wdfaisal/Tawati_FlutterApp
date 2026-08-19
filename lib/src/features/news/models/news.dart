class News {
  final String id;
  final String title;
  final String? subtitle;
  final String content;
  final String type;
  final String? subType;
  final String? image;
  final List<String> targetRoles;
  final List<String> targetFamilies;
  final String? createdByName;
  final String? createdById;
  final String status;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime createdAt;

  News({
    required this.id,
    required this.title,
    this.subtitle,
    required this.content,
    required this.type,
    this.subType,
    this.image,
    required this.targetRoles,
    required this.targetFamilies,
    this.createdByName,
    this.createdById,
    required this.status,
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
    subType: json['sub_type'] as String?,
    image: json['image'],
    targetRoles: List<String>.from(json['target_roles'] ?? []),
    targetFamilies: List<String>.from(json['target_families'] ?? []),
    createdByName: json['created_by'] is Map
        ? (json['created_by'] as Map)['full_name']?.toString()
        : json['created_by_name']?.toString(),
    createdById: json['created_by'] is Map
        ? (json['created_by'] as Map)['_id']?.toString()
        : (json['created_by'] is String ? json['created_by'] as String : null),
    status: json['status'] ?? 'draft',
    isPublished: json['is_published'] ?? (json['status'] == 'published'),
    publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at']) : null,
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isDeath => type == 'social_occasion' && subType == 'death';
  bool get isWedding => type == 'social_occasion' && subType == 'wedding';
  bool get isCongratulation => type == 'social_occasion' && subType == 'congratulation';
  bool get isEvent => type == 'social_occasion' && subType != 'death';
  bool get isAnnouncement =>
      type == 'general' || type == 'important' || type == 'admin_alert' || type == 'platform_announcement';

  String get typeLabel {
    if (isDeath) return 'نعي';
    if (isWedding) return 'عرس';
    if (isCongratulation) return 'تهنئة';
    switch (type) {
      case 'general':
      case 'important': return 'إعلان';
      case 'admin_alert': return 'إعلان إداري';
      case 'platform_announcement': return 'إعلان المنصة';
      case 'social_occasion': return 'مناسبة';
      case 'obituary': return 'نعي';
      case 'wedding': return 'عرس';
      default: return 'خبر';
    }
  }
}
