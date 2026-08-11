class Group {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String type;
  final String? createdByName;
  final int memberCount;
  final int messageCount;
  final bool isMember;
  final String? role;
  final int unreadCount;
  final String? myPermission;
  final String? myMemberStatus;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.type,
    this.createdByName,
    required this.memberCount,
    this.messageCount = 0,
    required this.isMember,
    this.role,
    this.unreadCount = 0,
    this.myPermission,
    this.myMemberStatus,
    required this.createdAt,
  });

  bool get isViewOnly => myPermission == 'view_only';
  bool get isMutedByAdmin => myMemberStatus == 'muted';

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    image: json['image'],
    type: json['type'] ?? 'general',
    createdByName: json['created_by_name'],
    memberCount: json['member_count'] ?? 0,
    messageCount: json['message_count'] ?? 0,
    isMember: json['is_member'] ?? false,
    role: json['role'] ?? json['my_role'],
    unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
    myPermission: json['my_permission'],
    myMemberStatus: json['my_member_status'],
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type;
  final DateTime createdAt;
  final String sendStatus;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.createdAt,
    this.sendStatus = 'sent',
  });

  GroupMessage copyWith({String? id, String? sendStatus}) => GroupMessage(
    id: id ?? this.id,
    groupId: groupId,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    content: content,
    type: type,
    createdAt: createdAt,
    sendStatus: sendStatus ?? this.sendStatus,
  );

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
    id: json['_id'] ?? json['id'] ?? '',
    groupId: json['group_id'] ?? '',
    senderId: json['sender_id'] ?? '',
    senderName: json['sender_name'] ?? '',
    senderAvatar: json['sender_avatar'],
    content: json['content'] ?? '',
    type: json['type'] ?? 'text',
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
  );

  factory GroupMessage.fromSocketJson(Map<String, dynamic> json) {
    final sender = json['sender_id'];
    final String senderId;
    final String senderName;
    final String? senderAvatar;
    if (sender is Map) {
      senderId = sender['_id']?.toString() ?? json['sender_id']?.toString() ?? '';
      senderName = sender['full_name']?.toString() ?? '';
      senderAvatar = sender['avatar_image']?.toString();
    } else {
      senderId = sender?.toString() ?? '';
      senderName = json['sender_name']?.toString() ?? '';
      senderAvatar = json['sender_avatar']?.toString();
    }
    return GroupMessage(
      id: json['_id'] ?? json['id'] ?? '',
      groupId: json['group_id']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: json['content']?.toString() ?? '',
      type: json['content_type']?.toString() ?? json['type']?.toString() ?? 'text',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
