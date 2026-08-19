import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/providers.dart';
import '../models/news.dart';

final newsServiceProvider = Provider<NewsService>((ref) {
  return NewsService(ref.read(apiClientProvider));
});

class NewsService {
  final ApiClient _api;

  NewsService(this._api);

  Future<List<News>> getNews({int page = 1, int limit = 20}) async {
    final response = await _api.get('/news', params: {
      'page': page,
      'limit': limit,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => News.fromJson(e)).toList();
  }

  Future<List<News>> getMyNews({int page = 1, int limit = 20}) async {
    final response = await _api.get('/news/my', params: {
      'page': page,
      'limit': limit,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => News.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getNewsById(String id) async {
    final response = await _api.get('/news/$id');
    final data = response.data;
    if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data'] as Map);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('تعذر تحميل الإعلان');
  }

  Future<void> createNews(Map<String, dynamic> body) async {
    final response = await _api.post('/news', data: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('فشل نشر الإعلان، حاول مرة أخرى');
    }
  }

  Future<void> updateNews(String id, Map<String, dynamic> body) async {
    final response = await _api.put('/news/$id', data: body);
    if (response.statusCode != 200) {
      throw Exception('فشل تعديل الإعلان');
    }
  }

  Future<void> deleteNews(String id) async {
    final response = await _api.delete('/news/$id');
    if (response.statusCode != 200) {
      throw Exception('فشل حذف الإعلان');
    }
  }

  Future<String?> uploadImage(String filePath) async {
    return _api.uploadImage(
      path: '/media/upload',
      filePath: filePath,
      filename: 'upload.jpg',
    );
  }
}
