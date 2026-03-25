import '../services/listening_api_service.dart';

class ListeningRepository {
  ListeningRepository({required ListeningApiService service}) : _service = service;

  final ListeningApiService _service;

  Future<void> play(String trackId, {int? progressMs}) {
    return _service.sendEvent(
      trackId: trackId,
      eventType: 'play',
      progressMs: progressMs,
      clientTs: DateTime.now(),
    );
  }

  Future<void> pause(String trackId, {int? progressMs}) {
    return _service.sendEvent(
      trackId: trackId,
      eventType: 'pause',
      progressMs: progressMs,
      clientTs: DateTime.now(),
    );
  }

  Future<void> skip(String trackId, {int? progressMs}) {
    return _service.sendEvent(
      trackId: trackId,
      eventType: 'skip',
      progressMs: progressMs,
      clientTs: DateTime.now(),
    );
  }

  Future<void> complete(String trackId, {int? progressMs}) {
    return _service.sendEvent(
      trackId: trackId,
      eventType: 'complete',
      progressMs: progressMs,
      clientTs: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> getRecent({int limit = 20}) {
    return _service.getRecent(limit: limit);
  }
}
