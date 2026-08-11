import '../../../core/api_client.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    final data = response.data['data'];
    return {
      'user': User.fromJson(data['user']),
      'access_token': data['access_token'] as String,
      'refresh_token': data['refresh_token'] as String,
    };
  }

  Future<void> sendOtp({required String phone}) async {
    await _api.post('/auth/request-otp', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> setPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    final response = await _api.post('/auth/set-password', data: {
      'phone': phone,
      'otp': otp,
      'password': password,
    });
    final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
    return {
      'needs_family_setup': data['needs_family_setup'] == true,
      'user_id': data['user_id'],
    };
  }

  Future<void> setupFamily({
    required String userId,
    required String spouseName,
    List<Map<String, dynamic>> children = const [],
  }) async {
    await _api.post('/auth/first-login/setup-family', data: {
      'userId': userId,
      'spouseName': spouseName,
      'children': children,
    });
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _api.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    final data = response.data['data'];
    return {
      'user': User.fromJson(data['user']),
      'access_token': data['access_token'] as String,
      'refresh_token': data['refresh_token'] as String,
    };
  }

  Future<User> getMe() async {
    final response = await _api.get('/auth/me');
    return User.fromJson(response.data['data']);
  }

  Future<void> logout({String? refreshToken}) async {
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // Best-effort server-side revocation; client session is cleared regardless.
      }
    }
  }
}
