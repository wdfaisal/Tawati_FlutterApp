class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? relatedResourceType;
  final String? relatedResourceId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.relatedResourceType,
    this.relatedResourceId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    type: json['type']?.toString() ?? 'general',
    isRead: json['is_read'] == true,
    relatedResourceType: json['related_resource_type']?.toString(),
    relatedResourceId: json['related_resource_id']?.toString(),
    createdAt: DateTime.tryParse(
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now(),
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    isRead: isRead ?? this.isRead,
    relatedResourceType: relatedResourceType,
    relatedResourceId: relatedResourceId,
    createdAt: createdAt,
  );
}

class NotificationsResult {
  final List<AppNotification> notifications;
  final int unread;

  const NotificationsResult({required this.notifications, required this.unread});
}
