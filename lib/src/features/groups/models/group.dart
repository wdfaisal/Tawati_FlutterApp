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
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isOnline;

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
    this.lastMessage,
    this.lastMessageAt,
    this.isOnline = false,
  });

  bool get isViewOnly => myPermission == 'view_only';
  bool get isMutedByAdmin => myMemberStatus == 'muted';

  Group copyWith({
    bool? isMember,
    String? role,
    int? unreadCount,
    String? myPermission,
    String? myMemberStatus,
  }) => Group(
    id: id,
    name: name,
    description: description,
    image: image,
    type: type,
    createdByName: createdByName,
    memberCount: memberCount,
    messageCount: messageCount,
    isMember: isMember ?? this.isMember,
    role: role ?? this.role,
    unreadCount: unreadCount ?? this.unreadCount,
    myPermission: myPermission ?? this.myPermission,
    myMemberStatus: myMemberStatus ?? this.myMemberStatus,
    createdAt: createdAt,
  );

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    image: json['image'] ?? json['avatar_image'],
    type: json['type'] ?? 'general',
    createdByName: json['created_by_name'],
    memberCount: json['member_count'] ?? json['memberCount'] ?? 0,
    messageCount: json['message_count'] ?? json['messageCount'] ?? 0,
    isMember: json['is_member'] ?? json['isMember'] ?? false,
    role: json['role'] ?? json['my_role'],
    unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
    myPermission: json['my_permission'],
    myMemberStatus: json['my_member_status'],
    createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    lastMessage: json['last_message']?.toString() ?? json['lastMessage']?.toString(),
    lastMessageAt: DateTime.tryParse(
      json['last_message_at']?.toString() ?? json['lastMessageAt']?.toString() ?? '',
    ),
    isOnline: json['is_online'] ?? json['isOnline'] ?? false,
  );
}

class MessageReaction {
  final String userId;
  final String emoji;

  MessageReaction({required this.userId, required this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        userId: json['user_id']?.toString() ?? '',
        emoji: json['emoji']?.toString() ?? '',
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
  final List<MessageReaction> reactions;

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
    this.reactions = const [],
  });

  GroupMessage copyWith({
    String? id,
    String? sendStatus,
    List<MessageReaction>? reactions,
  }) => GroupMessage(
    id: id ?? this.id,
    groupId: groupId,
    senderId: senderId,
    senderName: senderName,
    senderAvatar: senderAvatar,
    content: content,
    type: type,
    createdAt: createdAt,
    sendStatus: sendStatus ?? this.sendStatus,
    reactions: reactions ?? this.reactions,
  );

  static List<MessageReaction> _parseReactions(dynamic raw) {
    final list = raw as List<dynamic>? ?? const [];
    return list
        .map((e) => MessageReaction.fromJson(
              e is Map
                  ? e.map((k, v) => MapEntry(k.toString(), v))
                  : <String, dynamic>{},
            ))
        .toList();
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender_id'];
    final String senderId;
    final String senderName;
    final String? senderAvatar;
    if (sender is Map) {
      senderId = sender['_id']?.toString() ?? '';
      senderName = sender['full_name']?.toString() ?? '';
      senderAvatar = sender['avatar_image']?.toString();
    } else {
      senderId = sender?.toString() ?? '';
      senderName = json['sender_name']?.toString() ?? '';
      senderAvatar = json['sender_avatar']?.toString();
    }
    return GroupMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: json['content']?.toString() ?? '',
      type: json['content_type']?.toString() ?? json['type']?.toString() ?? 'text',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      reactions: _parseReactions(json['reactions']),
    );
  }

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
      reactions: _parseReactions(json['reactions']),
    );
  }
}
