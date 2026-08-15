import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(apiClientProvider));
});

final notificationsProvider = FutureProvider.autoDispose<NotificationsResult>((ref) {
  return ref.read(notificationServiceProvider).getNotifications();
});
