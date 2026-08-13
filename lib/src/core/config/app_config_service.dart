import '../api_client.dart';

class AppConfigService {
  final ApiClient _api;
  AppConfigService(this._api);

  Future<Map<String, dynamic>> fetchConfig() async {
    try {
      final res = await _api.get('/app-config');
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
    } catch (_) {
      // Backend unreachable or config missing — fall back to defaults.
    }
    return {};
  }
}
