import 'package:flutter/foundation.dart';

import '../../data/models/playlist_models.dart';
import '../../data/repositories/collaborative_playlist_repository.dart';

class PlaylistMembersState {
  const PlaylistMembersState({
    required this.isLoading,
    required this.isMutating,
    required this.members,
    this.errorMessage,
    this.latestInviteCode,
  });

  const PlaylistMembersState.initial()
    : isLoading = false,
      isMutating = false,
      members = const <PlaylistMember>[],
      errorMessage = null,
      latestInviteCode = null;

  final bool isLoading;
  final bool isMutating;
  final List<PlaylistMember> members;
  final String? errorMessage;
  final String? latestInviteCode;

  PlaylistMembersState copyWith({
    bool? isLoading,
    bool? isMutating,
    List<PlaylistMember>? members,
    String? errorMessage,
    String? latestInviteCode,
  }) {
    return PlaylistMembersState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      members: members ?? this.members,
      errorMessage: errorMessage,
      latestInviteCode: latestInviteCode ?? this.latestInviteCode,
    );
  }
}

class PlaylistMembersViewModel extends ChangeNotifier {
  PlaylistMembersViewModel({
    required CollaborativePlaylistRepository repository,
  }) : _repository = repository;

  final CollaborativePlaylistRepository _repository;
  PlaylistMembersState _state = const PlaylistMembersState.initial();

  PlaylistMembersState get state => _state;

  Future<void> load(String playlistId) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final members = await _repository.listMembers(playlistId);
      _state = _state.copyWith(isLoading: false, members: members);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
    notifyListeners();
  }

  Future<void> createInviteCode(String playlistId) async {
    _state = _state.copyWith(isMutating: true, errorMessage: null);
    notifyListeners();
    try {
      final invite = await _repository.createInvite(playlistId);
      _state = _state.copyWith(
        isMutating: false,
        latestInviteCode: invite.inviteCode,
      );
    } catch (error) {
      _state = _state.copyWith(
        isMutating: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
    notifyListeners();
  }

  Future<void> updateRole({
    required String playlistId,
    required String userId,
    required String role,
  }) async {
    _state = _state.copyWith(isMutating: true, errorMessage: null);
    notifyListeners();
    try {
      await _repository.updateMemberRole(
        playlistId: playlistId,
        userId: userId,
        role: role,
      );
      await load(playlistId);
    } catch (error) {
      _state = _state.copyWith(
        isMutating: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
    }
  }

  Future<void> removeMember({
    required String playlistId,
    required String userId,
  }) async {
    _state = _state.copyWith(isMutating: true, errorMessage: null);
    notifyListeners();
    try {
      await _repository.removeMember(playlistId: playlistId, userId: userId);
      await load(playlistId);
    } catch (error) {
      _state = _state.copyWith(
        isMutating: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
    }
  }

  Future<void> transferOwnership({
    required String playlistId,
    required String userId,
  }) async {
    _state = _state.copyWith(isMutating: true, errorMessage: null);
    notifyListeners();
    try {
      await _repository.transferOwnership(
        playlistId: playlistId,
        userId: userId,
      );
      await load(playlistId);
    } catch (error) {
      _state = _state.copyWith(
        isMutating: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      notifyListeners();
    }
  }
}
