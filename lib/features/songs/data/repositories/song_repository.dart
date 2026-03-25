import '../services/song_api_service.dart';

class SongRepository {
  SongRepository({required SongApiService service}) : _service = service;

  final SongApiService _service;

  Future<List<Map<String, dynamic>>> getNews({int limit = 16}) => _service.getNews(limit: limit);
  Future<List<Map<String, dynamic>>> getPlaylist() => _service.getPlaylist();
  Future<List<Map<String, dynamic>>> getFavorites() => _service.getFavorites();
  Future<bool> isFavorite(String songId) => _service.isFavorite(songId);
  Future<Map<String, dynamic>> toggleFavorite(String songId) => _service.toggleFavorite(songId);
}
