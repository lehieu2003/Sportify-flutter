import '../services/playlist_api_service.dart';

class PlaylistRepository {
  PlaylistRepository({required PlaylistApiService service}) : _service = service;

  final PlaylistApiService _service;

  Future<Map<String, dynamic>> createPlaylist({
    required String title,
    String? description,
    String? coverUrl,
    bool isPublic = false,
  }) {
    return _service.createPlaylist(
      title: title,
      description: description,
      coverUrl: coverUrl,
      isPublic: isPublic,
    );
  }

  Future<Map<String, dynamic>> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? coverUrl,
    bool? isPublic,
  }) {
    return _service.updatePlaylist(
      playlistId: playlistId,
      title: title,
      description: description,
      coverUrl: coverUrl,
      isPublic: isPublic,
    );
  }

  Future<void> deletePlaylist(String playlistId) => _service.deletePlaylist(playlistId);
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) =>
      _service.getPlaylistTracks(playlistId);
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    int? position,
  }) => _service.addTrackToPlaylist(playlistId: playlistId, trackId: trackId, position: position);
  Future<void> reorderTrack({
    required String playlistId,
    required String trackId,
    required int newPosition,
  }) => _service.reorderTrack(playlistId: playlistId, trackId: trackId, newPosition: newPosition);
  Future<void> removeTrack({
    required String playlistId,
    required String trackId,
  }) => _service.removeTrack(playlistId: playlistId, trackId: trackId);
}
