import '../api_client.dart';

class AppConfigService {
  final ApiClient _api;
  AppConfigService(this._api);

  Future<Map<String, dynamic>> fetchConfig() async {
    final res = await _api.get('/app-config');
    return res.data['data'] as Map<String, dynamic> ?? {};
  }
}
