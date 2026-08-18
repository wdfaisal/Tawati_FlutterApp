const String kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://54.251.69.36/api',
);

final String kMediaOrigin = kApiBase.replaceFirst('/api', '');

String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '$kMediaOrigin$url';
}
