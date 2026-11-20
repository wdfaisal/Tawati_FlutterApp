/// Central build-time configuration for the app.
///
/// Resolution order for the API address:
///   1. `--dart-define=API_BASE_URL=...` (always wins)
///   2. debug/profile builds → the LAN address of the dev machine
///   3. release builds       → the production API
///
/// ```bash
/// # local backend over the LAN (this is also the debug default)
/// flutter run --dart-define=API_BASE_URL=http://10.164.137.182:3000/api/v1
///
/// # Android emulator talking to the host machine
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
///
/// # release build straight to production (no flag needed)
/// flutter build apk --release
/// ```
library;

import 'package:flutter/foundation.dart';

/// API root of the development backend on this machine's Wi-Fi/LAN address.
///
/// Change this one line when the router hands out a different IP, or pass
/// `--dart-define=API_BASE_URL=...` and leave the code untouched.
const String kLanApiBaseUrl = 'http://10.164.137.182:3000/api/v1';

/// API root used by release builds.
const String kProductionApiBaseUrl = 'http://54.251.69.36/api/v1';

const String _definedApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Full API root, e.g. `http://10.131.76.182:3000/api/v1`.
final String kApiBaseUrl = _definedApiBaseUrl.isNotEmpty
    ? _definedApiBaseUrl
    : (kReleaseMode ? kProductionApiBaseUrl : kLanApiBaseUrl);

/// Server root without the `/api/v1` suffix — used by Socket.IO and media URLs.
final String kServerOrigin =
    kApiBaseUrl.replaceFirst(RegExp(r'/api/v1$|/api$'), '');

/// Kept for backwards compatibility with existing imports.
final String kApiBase = kApiBaseUrl;

/// Alias kept for backwards compatibility with existing imports.
final String kMediaOrigin = kServerOrigin;

/// Turns a relative upload path (`/uploads/a.jpg`) into an absolute URL that
/// points at the same backend the API calls go to.
///
/// Works across environments because it follows [kApiBaseUrl] instead of
/// hard-coding a host.
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final value = url.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('//')) return 'https:$value';
  return value.startsWith('/') ? '$kServerOrigin$value' : '$kServerOrigin/$value';
}

/// True when the app is pointed at a plain-HTTP (non-TLS) backend, which only
/// happens in local development.
bool get isLocalBackend => kApiBaseUrl.startsWith('http://');
