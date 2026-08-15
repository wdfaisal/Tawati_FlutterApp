import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../models/news.dart';

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

  Future<void> createNews(Map<String, dynamic> body) async {
    final response = await _api.post('/admin/news', data: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('فشل نشر الإعلان، حاول مرة أخرى');
    }
  }

  Future<String?> uploadImage(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'upload.jpg'),
    });
    final response = await _api.post('/upload', data: form);
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    final data = response.data['data'];
    if (data is Map<String, dynamic>) return data['url'] as String?;
    return null;
  }
}
