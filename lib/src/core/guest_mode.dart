import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

/// Global guest-mode flag.
///
/// The router listens to this value so protected screens are redirected to the
/// login screen as soon as a visitor tries to open them.
final ValueNotifier<bool> guestModeNotifier = ValueNotifier<bool>(false);

/// Thrown by [ApiClient] when a visitor attempts a write operation.
class GuestModeException implements Exception {
  const GuestModeException();

  @override
  String toString() => 'guest_mode';
}

/// Persists the "browse as visitor" choice between app launches.
class GuestSession {
  static const _storageKey = 'guest_mode';
  static const _storage = FlutterSecureStorage();

  static Future<bool> isActive() async {
    try {
      return await _storage.read(key: _storageKey) == '1';
    } catch (_) {
      return false;
    }
  }

  static Future<void> enable() async {
    try {
      await _storage.write(key: _storageKey, value: '1');
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }
}

/// Routes a visitor is not allowed to open.
bool isProtectedGuestRoute(String path) {
  const exact = {
    '/family-tree',
    '/groups/chat',
    '/my-donations',
    '/admin/donations',
    '/admin/donation-detail',
    '/admin/donation-reports',
    '/join-requests',
    '/notifications',
    '/add-announcement',
    '/add-obituary',
    '/my-announcements',
    '/account-documentation',
    '/family-setup',
    '/first-login',
  };
  if (exact.contains(path)) return true;
  return path.startsWith('/join-request/') || path.startsWith('/admin/');
}

/// Shows the "sign in to continue" dialog.
///
/// Returns `true` when the visitor chose to go to the login screen.
Future<bool> showGuestLoginPrompt(
  BuildContext context, {
  String? message,
}) async {
  final goToLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        icon: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: AppColors.primary, size: 26),
        ),
        title: const Text(
          'هذه الميزة للأعضاء',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message ??
              'أنت تتصفح الآن كزائر. سجّل الدخول بحسابك للاستفادة من هذه الميزة والوصول إلى كل خدمات تواتي.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 13,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'لاحقاً',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (goToLogin == true && context.mounted) {
    context.goNamed('login');
  }
  return goToLogin == true;
}
