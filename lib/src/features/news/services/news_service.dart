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
}
