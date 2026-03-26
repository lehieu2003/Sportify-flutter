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

  Future<List<CatalogTrack>> getArtistTopTracks(String artistId, {int limit = 10}) {
    return _service.getArtistTopTracks(artistId, limit: limit);
  }

  Future<CatalogTracksPage> getArtistAlbums({
    required String artistId,
    int limit = 20,
    String? cursor,
  }) {
    return _service.getArtistAlbums(
      artistId: artistId,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<SearchBrowsePayload> getSearchBrowse() {
    return _service.getSearchBrowse();
  }

  Future<List<SearchRecentItem>> getRecentSearches({int limit = 20}) {
    return _service.getRecentSearches(limit: limit);
  }

  Future<void> upsertRecentSearch({
    required String type,
    required String itemId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) {
    return _service.upsertRecentSearch(
      type: type,
      itemId: itemId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
  }

  Future<void> deleteRecentSearch(String recentId) {
    return _service.deleteRecentSearch(recentId);
  }
}
