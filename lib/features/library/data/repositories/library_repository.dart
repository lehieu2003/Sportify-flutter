import '../models/library_models.dart';
import '../services/library_api_service.dart';

class LibraryRepository {
  LibraryRepository({required LibraryApiService service}) : _service = service;

  final LibraryApiService _service;

  Future<List<LibraryTrack>> getSavedTracks({int limit = 50}) {
    return _service.getSavedTracks(limit: limit);
  }

  Future<void> saveTrack(String trackId) => _service.saveTrack(trackId);
  Future<void> unsaveTrack(String trackId) => _service.unsaveTrack(trackId);
  Future<void> saveAlbum(String albumId) => _service.saveAlbum(albumId);
  Future<void> unsaveAlbum(String albumId) => _service.unsaveAlbum(albumId);
  Future<void> followArtist(String artistId) => _service.followArtist(artistId);
  Future<void> unfollowArtist(String artistId) => _service.unfollowArtist(artistId);
}
