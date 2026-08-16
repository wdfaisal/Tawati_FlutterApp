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

  Future<Map<String, dynamic>> getNewsById(String id) async {
    final response = await _api.get('/news/$id');
    final data = response.data;
    if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data'] as Map);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('تعذر تحميل الإعلان');
  }

  Future<void> createNews(Map<String, dynamic> body) async {
    final response = await _api.post('/admin/news', data: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('فشل نشر الإعلان، حاول مرة أخرى');
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
