import '../models/jam_models.dart';
import '../services/jam_api_service.dart';

class JamRepository {
  JamRepository({required JamApiService service}) : _service = service;

  final JamApiService _service;

  Future<JamSession> createSession({String? title}) =>
      _service.createSession(title: title);

  Future<JamSession?> getActiveSession() => _service.getActiveSession();

  Future<JamSession> joinByCode(String inviteCode) =>
      _service.joinByCode(inviteCode);

  Future<JamSession> getSessionById(String sessionId) =>
      _service.getSessionById(sessionId);

  Future<JamSession> syncQueue({
    required String sessionId,
    required List<String> trackIds,
    required int queueIndex,
    String? currentTrackId,
  }) => _service.syncQueue(
    sessionId: sessionId,
    trackIds: trackIds,
    queueIndex: queueIndex,
    currentTrackId: currentTrackId,
  );

  Future<Map<String, dynamic>> leaveSession(String sessionId) =>
      _service.leaveSession(sessionId);

  Future<Map<String, dynamic>> endSession(String sessionId) =>
      _service.endSession(sessionId);
}
