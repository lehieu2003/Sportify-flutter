import '../models/catalog_models.dart';
import '../services/catalog_api_service.dart';

class CatalogRepository {
  CatalogRepository({required CatalogApiService service}) : _service = service;

  final CatalogApiService _service;

  Future<CatalogTracksPage> searchTracks({
    String? query,
    String? genre,
    int limit = 20,
    String? cursor,
  }) {
    return _service.listTracks(
      query: query,
      genre: genre,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<CatalogTrack> getTrackById(String trackId) {
    return _service.getTrackById(trackId);
  }

  Future<CatalogArtist> getArtistById(String artistId) {
    return _service.getArtistById(artistId);
  }

  Future<CatalogAlbum> getAlbumById(String albumId) {
    return _service.getAlbumById(albumId);
  }

  Future<List<CatalogTrack>> getAlbumTracks(String albumId) {
    return _service.getAlbumTracks(albumId);
  }
}
