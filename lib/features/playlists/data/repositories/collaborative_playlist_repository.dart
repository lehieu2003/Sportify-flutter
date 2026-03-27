import '../models/playlist_models.dart';
import '../services/collaborative_playlist_api_service.dart';

class CollaborativePlaylistRepository {
  CollaborativePlaylistRepository({
    required CollaborativePlaylistApiService service,
  }) : _service = service;

  final CollaborativePlaylistApiService _service;

  Future<List<PlaylistMember>> listMembers(String playlistId) =>
      _service.listMembers(playlistId);

  Future<PlaylistInvite> createInvite(
    String playlistId, {
    int? expiresInHours,
    int? maxUses,
  }) => _service.createInvite(
    playlistId,
    expiresInHours: expiresInHours,
    maxUses: maxUses,
  );

  Future<JoinPlaylistResult> joinByCode(String inviteCode) =>
      _service.joinByCode(inviteCode);

  Future<void> updateMemberRole({
    required String playlistId,
    required String userId,
    required String role,
  }) => _service.updateMemberRole(
    playlistId: playlistId,
    userId: userId,
    role: role,
  );

  Future<void> removeMember({
    required String playlistId,
    required String userId,
  }) => _service.removeMember(playlistId: playlistId, userId: userId);

  Future<void> transferOwnership({
    required String playlistId,
    required String userId,
  }) => _service.transferOwnership(playlistId: playlistId, userId: userId);
}
