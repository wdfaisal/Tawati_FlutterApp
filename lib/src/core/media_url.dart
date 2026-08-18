const String kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://54.251.69.36/api/v1',
);

final String kMediaOrigin = kApiBase.replaceFirst(RegExp(r'/api/v1$|/api$'), '');

String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '$kMediaOrigin$url';
}
