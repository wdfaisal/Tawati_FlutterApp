import '../../../core/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _api;

  NotificationService(this._api);

  Future<NotificationsResult> getNotifications() async {
    final response = await _api.get('/notifications');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final list = data['notifications'] as List<dynamic>? ?? [];
    return NotificationsResult(
      notifications: list
          .map((e) => AppNotification.fromJson(
                e is Map ? e.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{},
              ))
          .toList(),
      unread: data['unread'] as int? ?? 0,
    );
  }

  Future<void> markAsRead({List<String>? ids}) async {
    await _api.post('/notifications/read', data: {'ids': ids ?? []});
  }
}
