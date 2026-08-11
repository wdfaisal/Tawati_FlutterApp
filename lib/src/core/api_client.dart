import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _InMemoryStorage {
  final _store = <String, String>{};
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }
  Future<String?> read({required String key}) async => _store[key];
  Future<void> delete({required String key}) async => _store.remove(key);
}

class ApiClient {
  late final Dio _dio;
  final Object _storage;

  ApiClient({required String baseUrl})
      : _storage = kIsWeb ? _InMemoryStorage() : const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _read('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          }
          await clearTokens();
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> _read(String key) {
    if (kIsWeb) return (_storage as _InMemoryStorage).read(key: key);
    return (_storage as FlutterSecureStorage).read(key: key);
  }

  Future<void> _write(String key, String value) {
    if (kIsWeb) return (_storage as _InMemoryStorage).write(key: key, value: value);
    return (_storage as FlutterSecureStorage).write(key: key, value: value);
  }

  Future<void> _delete(String key) {
    if (kIsWeb) return (_storage as _InMemoryStorage).delete(key: key);
    return (_storage as FlutterSecureStorage).delete(key: key);
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _read('refresh_token');
      if (refresh == null) return false;
      final response = await Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
          .post('/auth/refresh-token', data: {'refreshToken': refresh});
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _write('access_token', data['token']);
        if (data['refreshToken'] != null) {
          await _write('refresh_token', data['refreshToken']);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _read('access_token');
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _write('access_token', accessToken);
    await _write('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() => _read('access_token');

  Future<void> clearTokens() async {
    await _delete('access_token');
    await _delete('refresh_token');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
