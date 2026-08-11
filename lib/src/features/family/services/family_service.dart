import '../../../core/api_client.dart';
import '../models/family.dart';

class FamilyService {
  final ApiClient _api;

  FamilyService(this._api);

  Future<Family> getMyFamily() async {
    final response = await _api.get('/families/my');
    final data = response.data['data'] as Map<String, dynamic>;
    final familyMap = Map<String, dynamic>.from(data['family']);
    familyMap['members'] = data['members'];
    return Family.fromJson(familyMap);
  }

  Future<Family> getFamilyTree(String familyId) async {
    final response = await _api.get('/families/$familyId/tree');
    return Family.fromJson(response.data['data']);
  }
}
