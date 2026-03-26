import 'package:flutter/foundation.dart';

import '../../data/models/library_models.dart';
import '../../data/repositories/library_repository.dart';
import '../../../playlists/data/repositories/playlist_repository.dart';

class LibraryUiState {
  const LibraryUiState({
    required this.isLoading,
    required this.items,
    required this.playlists,
    this.errorMessage,
  });

  const LibraryUiState.initial()
    : isLoading = false,
      items = const <LibraryTrack>[],
      playlists = const <LibraryPlaylist>[],
      errorMessage = null;

  final bool isLoading;
  final List<LibraryTrack> items;
  final List<LibraryPlaylist> playlists;
  final String? errorMessage;

  LibraryUiState copyWith({
    bool? isLoading,
    List<LibraryTrack>? items,
    List<LibraryPlaylist>? playlists,
    String? errorMessage,
  }) {
    return LibraryUiState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      playlists: playlists ?? this.playlists,
      errorMessage: errorMessage,
    );
  }
}

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({
    required LibraryRepository repository,
    required PlaylistRepository playlistRepository,
  }) : _repository = repository,
       _playlistRepository = playlistRepository;

  final LibraryRepository _repository;
  final PlaylistRepository _playlistRepository;
  LibraryUiState _state = const LibraryUiState.initial();

  LibraryUiState get state => _state;

  Future<void> loadSavedTracks() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final itemsFuture = _repository.getSavedTracks(limit: 100);
      final playlistsFuture = _playlistRepository.listPlaylists(limit: 50);
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        itemsFuture,
        playlistsFuture,
      ]);
      final items = results[0] as List<LibraryTrack>;
      final playlistsRaw = results[1] as List<Map<String, dynamic>>;
      final playlists = playlistsRaw
          .map(LibraryPlaylist.fromJson)
          .toList(growable: false);
      _state = _state.copyWith(
        isLoading: false,
        items: items,
        playlists: playlists,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library.',
      );
    }
    notifyListeners();
  }

  Future<void> unsaveTrack(String trackId) async {
    try {
      await _repository.unsaveTrack(trackId);
      _state = _state.copyWith(
        items: _state.items.where((item) => item.id != trackId).toList(growable: false),
      );
      notifyListeners();
    } catch (_) {}
  }
}
