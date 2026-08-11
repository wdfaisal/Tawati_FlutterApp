import '../../../core/api_client.dart';
import '../models/group.dart';

class GroupService {
  final ApiClient _api;

  GroupService(this._api);

  Future<List<Group>> getGroups({int page = 1, int limit = 20}) async {
    final response = await _api.get('/groups', params: {
      'page': page,
      'limit': limit,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Group.fromJson(e)).toList();
  }

  Future<Group> getGroupDetail(String id) async {
    final response = await _api.get('/groups/$id');
    return Group.fromJson(response.data['data']);
  }

  Future<void> joinGroup(String id) async {
    await _api.post('/groups/$id/join');
  }

  Future<void> leaveGroup(String id) async {
    await _api.delete('/groups/$id/join');
  }

  Future<void> markGroupRead(String id) async {
    await _api.post('/groups/$id/read');
  }

  Future<GroupMessagesResult> getMessages(String groupId) async {
    final response = await _api.get('/groups/$groupId/messages');
    final list = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return GroupMessagesResult(
      messages: list.map((e) => GroupMessage.fromJson(e)).toList(),
      myPermission: meta['my_permission'] as String?,
      myRole: meta['my_role'] as String?,
      myMemberStatus: meta['my_member_status'] as String?,
    );
  }

  Future<GroupMessage> sendMessage(String groupId, String content) async {
    final response = await _api.post('/groups/$groupId/messages', data: {
      'content': content,
    });
    return GroupMessage.fromJson(response.data['data']);
  }

  Future<GroupMessage> reactToMessage(
    String groupId,
    String messageId,
    String emoji,
  ) async {
    final response = await _api.post(
      '/groups/$groupId/messages/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return GroupMessage.fromJson(response.data['data']);
  }
}

class GroupMessagesResult {
  final List<GroupMessage> messages;
  final String? myPermission;
  final String? myRole;
  final String? myMemberStatus;

  GroupMessagesResult({
    required this.messages,
    this.myPermission,
    this.myRole,
    this.myMemberStatus,
  });
}
