import '../../../core/api_client.dart';
import '../models/initiative.dart';

class InitiativeService {
  final ApiClient _api;

  InitiativeService(this._api);

  Future<List<Initiative>> getInitiatives({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get('/initiatives', params: {
      'page': page,
      'limit': limit,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Initiative.fromJson(e)).toList();
  }

  Future<Initiative> getInitiativeDetail(String id) async {
    final response = await _api.get('/initiatives/$id');
    return Initiative.fromJson(response.data['data']);
  }

  Future<void> registerForInitiative(String id) async {
    await _api.post('/initiatives/$id/register');
  }

  Future<void> unregisterFromInitiative(String id) async {
    await _api.delete('/initiatives/$id/register');
  }
}
