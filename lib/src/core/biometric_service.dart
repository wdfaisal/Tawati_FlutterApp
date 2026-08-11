import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = kIsWeb
      ? const FlutterSecureStorage()
      : const FlutterSecureStorage();

  static const _enabledKey = 'biometric_enabled';

  Future<bool> isDeviceCapable() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasEnrolledBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'تسجيل الدخول via البصمة'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _enabledKey);
    return val == 'true';
  }

  Future<void> setEnabled(bool value) async {
    if (value) {
      await _storage.write(key: _enabledKey, value: 'true');
    } else {
      await _storage.delete(key: _enabledKey);
    }
  }
}
