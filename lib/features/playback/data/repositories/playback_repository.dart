import '../services/playback_api_service.dart';

class PlaybackRepository {
  PlaybackRepository({required PlaybackApiService service}) : _service = service;

  final PlaybackApiService _service;

  Future<Map<String, dynamic>> getState() => _service.getState();
  Future<Map<String, dynamic>> getQueue() => _service.getQueue();

  Future<Map<String, dynamic>> updateState({
    String? currentTrackId,
    int? queueIndex,
    bool? isPlaying,
    int? positionMs,
  }) {
    return _service.updateState(
      currentTrackId: currentTrackId,
      queueIndex: queueIndex,
      isPlaying: isPlaying,
      positionMs: positionMs,
    );
  }

  Future<Map<String, dynamic>> setQueue({
    required List<String> trackIds,
    required int currentIndex,
  }) {
    return _service.setQueue(
      trackIds: trackIds,
      currentIndex: currentIndex,
    );
  }

  Future<Map<String, dynamic>> next() => _service.next();
  Future<Map<String, dynamic>> previous() => _service.previous();
}
