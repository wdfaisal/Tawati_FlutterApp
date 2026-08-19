import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/providers.dart';
import '../models/join_request.dart';

final joinRequestServiceProvider = Provider<JoinRequestService>((ref) {
  return JoinRequestService(ref.read(apiClientProvider));
});

class JoinRequestService {
  final ApiClient _api;

  JoinRequestService(this._api);

  Future<List<JoinRequest>> getJoinRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    final response = await _api.get('/registration-requests', params: params);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => JoinRequest.fromJson(e)).toList();
  }

  Future<JoinRequest> getJoinRequestById(String id) async {
    final response = await _api.get('/registration-requests/$id');
    final data = response.data['data'];
    return JoinRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<void> reviewRequest({
    required String id,
    required String status,
    String? reviewNotes,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };
    if (reviewNotes != null) body['review_notes'] = reviewNotes;

    final response = await _api.put('/registration-requests/$id/review', data: body);
    if (response.statusCode != 200) {
      throw Exception('فشل تحديث حالة الطلب');
    }
  }

  Future<int> getRequestCount({String? status}) async {
    final params = <String, dynamic>{'limit': 1};
    if (status != null) params['status'] = status;

    final response = await _api.get('/registration-requests', params: params);
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return meta?['total'] as int? ?? 0;
  }
}
