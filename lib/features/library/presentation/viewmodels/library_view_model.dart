import 'package:flutter/foundation.dart';

import '../../data/models/library_models.dart';
import '../../data/repositories/library_repository.dart';
import '../../../playlists/data/repositories/playlist_repository.dart';

class LibraryUiState {
  const LibraryUiState({
    required this.isLoading,
    required this.items,
    required this.playlists,
    required this.albums,
    required this.artists,
    this.errorMessage,
  });

  const LibraryUiState.initial()
    : isLoading = false,
      items = const <LibraryTrack>[],
      playlists = const <LibraryPlaylist>[],
      albums = const <LibraryAlbum>[],
      artists = const <LibraryArtist>[],
      errorMessage = null;

  final bool isLoading;
  final List<LibraryTrack> items;
  final List<LibraryPlaylist> playlists;
  final List<LibraryAlbum> albums;
  final List<LibraryArtist> artists;
  final String? errorMessage;

  LibraryUiState copyWith({
    bool? isLoading,
    List<LibraryTrack>? items,
    List<LibraryPlaylist>? playlists,
    List<LibraryAlbum>? albums,
    List<LibraryArtist>? artists,
    String? errorMessage,
  }) {
    return LibraryUiState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      playlists: playlists ?? this.playlists,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      errorMessage: errorMessage,
    );
  }
}

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({
    required LibraryRepository repository,
    required PlaylistRepository playlistRepository,
  }) : _repository = repository;

  final LibraryRepository _repository;
  LibraryUiState _state = const LibraryUiState.initial();

  LibraryUiState get state => _state;

  Future<void> loadSavedTracks() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.getSavedTracks(limit: 100),
        _repository.getOwnedPlaylists(limit: 50),
        _repository.getSavedAlbums(limit: 50),
        _repository.getFollowedArtists(limit: 50),
      ]);
      _state = _state.copyWith(
        isLoading: false,
        items: results[0] as List<LibraryTrack>,
        playlists: (results[1] as CursorPage<LibraryPlaylist>).items,
        albums: (results[2] as CursorPage<LibraryAlbum>).items,
        artists: (results[3] as CursorPage<LibraryArtist>).items,
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
