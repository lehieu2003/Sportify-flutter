import 'package:flutter/foundation.dart';

import '../../data/models/library_models.dart';
import '../../data/repositories/library_repository.dart';
import '../../../playlists/data/repositories/playlist_repository.dart';

enum LibraryTab { playlists, albums, artists, likedSongs }

class LibraryListState<T> {
  LibraryListState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasLoaded,
    required this.items,
    required this.nextCursor,
    this.errorMessage,
  });

  LibraryListState.initial()
    : isLoading = false,
      isLoadingMore = false,
      hasLoaded = false,
      items = <T>[],
      nextCursor = null,
      errorMessage = null;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final List<T> items;
  final String? nextCursor;
  final String? errorMessage;

  bool get isEmpty => hasLoaded && items.isEmpty && errorMessage == null;
  bool get hasErrorOnly => hasLoaded && items.isEmpty && errorMessage != null;
  bool get canLoadMore =>
      !isLoading &&
      !isLoadingMore &&
      nextCursor != null &&
      nextCursor!.isNotEmpty;

  LibraryListState<T> copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    List<T>? items,
    String? nextCursor,
    String? errorMessage,
  }) {
    return LibraryListState<T>(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      items: items ?? this.items,
      nextCursor: nextCursor,
      errorMessage: errorMessage,
    );
  }
}

class LibraryUiState {
  LibraryUiState({
    required this.activeTab,
    required this.playlists,
    required this.albums,
    required this.artists,
    required this.likedSongs,
  });

  LibraryUiState.initial()
    : activeTab = LibraryTab.playlists,
      playlists = LibraryListState<LibraryPlaylist>.initial(),
      albums = LibraryListState<LibraryAlbum>.initial(),
      artists = LibraryListState<LibraryArtist>.initial(),
      likedSongs = LibraryListState<LibraryTrack>.initial();

  final LibraryTab activeTab;
  final LibraryListState<LibraryPlaylist> playlists;
  final LibraryListState<LibraryAlbum> albums;
  final LibraryListState<LibraryArtist> artists;
  final LibraryListState<LibraryTrack> likedSongs;

  LibraryUiState copyWith({
    LibraryTab? activeTab,
    LibraryListState<LibraryPlaylist>? playlists,
    LibraryListState<LibraryAlbum>? albums,
    LibraryListState<LibraryArtist>? artists,
    LibraryListState<LibraryTrack>? likedSongs,
  }) {
    return LibraryUiState(
      activeTab: activeTab ?? this.activeTab,
      playlists: playlists ?? this.playlists,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      likedSongs: likedSongs ?? this.likedSongs,
    );
  }

  LibraryListState<dynamic> stateForTab(LibraryTab tab) {
    switch (tab) {
      case LibraryTab.playlists:
        return playlists;
      case LibraryTab.albums:
        return albums;
      case LibraryTab.artists:
        return artists;
      case LibraryTab.likedSongs:
        return likedSongs;
    }
  }
}

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({
    required LibraryRepository repository,
    required PlaylistRepository playlistRepository,
  }) : _repository = repository;

  final LibraryRepository _repository;
  LibraryUiState _state = LibraryUiState.initial();

  LibraryUiState get state => _state;

  Future<void> bootstrap() async {
    await _ensureTabLoaded(_state.activeTab);
  }

  Future<void> setTab(LibraryTab tab) async {
    if (_state.activeTab == tab) return;
    _state = _state.copyWith(activeTab: tab);
    notifyListeners();
    await _ensureTabLoaded(tab);
  }

  Future<void> _ensureTabLoaded(LibraryTab tab) async {
    final current = _state.stateForTab(tab);
    if (current.hasLoaded || current.isLoading) return;
    await refreshTab(tab);
  }

  Future<void> refreshCurrentTab() async {
    await refreshTab(_state.activeTab);
  }

  Future<void> refreshTab(LibraryTab tab) async {
    switch (tab) {
      case LibraryTab.playlists:
        await _loadPlaylists(refresh: true);
      case LibraryTab.albums:
        await _loadAlbums(refresh: true);
      case LibraryTab.artists:
        await _loadArtists(refresh: true);
      case LibraryTab.likedSongs:
        await _loadLikedSongs(refresh: true);
    }
  }

  Future<void> loadMoreCurrentTab() async {
    switch (_state.activeTab) {
      case LibraryTab.playlists:
        await _loadPlaylists(refresh: false);
      case LibraryTab.albums:
        await _loadAlbums(refresh: false);
      case LibraryTab.artists:
        await _loadArtists(refresh: false);
      case LibraryTab.likedSongs:
        return;
    }
  }

  Future<void> loadSavedTracks() async {
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      _loadLikedSongs(refresh: true),
      _loadPlaylists(refresh: true),
      _loadAlbums(refresh: true),
      _loadArtists(refresh: true),
    ]);
  }

  Future<void> _loadLikedSongs({required bool refresh}) async {
    final current = _state.likedSongs;
    if (current.isLoading || current.isLoadingMore) return;
    _state = _state.copyWith(
      likedSongs: current.copyWith(
        isLoading: refresh,
        isLoadingMore: false,
        errorMessage: null,
        hasLoaded: current.hasLoaded,
      ),
    );
    notifyListeners();

    try {
      final items = await _repository.getSavedTracks(limit: 100);
      _state = _state.copyWith(
        likedSongs: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          items: items,
          nextCursor: null,
          errorMessage: null,
        ),
      );
    } catch (_) {
      _state = _state.copyWith(
        likedSongs: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          errorMessage: 'Failed to load liked songs.',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _loadPlaylists({required bool refresh}) async {
    final current = _state.playlists;
    if (current.isLoading || current.isLoadingMore) return;
    if (!refresh && !current.canLoadMore) return;

    _state = _state.copyWith(
      playlists: current.copyWith(
        isLoading: refresh,
        isLoadingMore: !refresh,
        errorMessage: null,
      ),
    );
    notifyListeners();

    try {
      final page = await _repository.getOwnedPlaylists(
        limit: 30,
        cursor: refresh ? null : current.nextCursor,
      );
      final incoming = page.items.toList(growable: false)
        ..sort((a, b) {
          final bTime = DateTime.tryParse(b.updatedAt);
          final aTime = DateTime.tryParse(a.updatedAt);
          if (aTime == null && bTime == null) return b.id.compareTo(a.id);
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          final byTime = bTime.compareTo(aTime);
          if (byTime != 0) return byTime;
          return b.id.compareTo(a.id);
        });
      final merged = refresh
          ? incoming
          : <LibraryPlaylist>[...current.items, ...incoming];
      _state = _state.copyWith(
        playlists: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          items: merged,
          nextCursor: page.nextCursor,
          errorMessage: null,
        ),
      );
    } catch (_) {
      _state = _state.copyWith(
        playlists: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          errorMessage: 'Failed to load playlists.',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _loadAlbums({required bool refresh}) async {
    final current = _state.albums;
    if (current.isLoading || current.isLoadingMore) return;
    if (!refresh && !current.canLoadMore) return;

    _state = _state.copyWith(
      albums: current.copyWith(
        isLoading: refresh,
        isLoadingMore: !refresh,
        errorMessage: null,
      ),
    );
    notifyListeners();

    try {
      final page = await _repository.getSavedAlbums(
        limit: 30,
        cursor: refresh ? null : current.nextCursor,
      );
      final merged = refresh
          ? page.items
          : <LibraryAlbum>[...current.items, ...page.items];
      _state = _state.copyWith(
        albums: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          items: merged,
          nextCursor: page.nextCursor,
          errorMessage: null,
        ),
      );
    } catch (_) {
      _state = _state.copyWith(
        albums: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          errorMessage: 'Failed to load albums.',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _loadArtists({required bool refresh}) async {
    final current = _state.artists;
    if (current.isLoading || current.isLoadingMore) return;
    if (!refresh && !current.canLoadMore) return;

    _state = _state.copyWith(
      artists: current.copyWith(
        isLoading: refresh,
        isLoadingMore: !refresh,
        errorMessage: null,
      ),
    );
    notifyListeners();

    try {
      final page = await _repository.getFollowedArtists(
        limit: 30,
        cursor: refresh ? null : current.nextCursor,
      );
      final merged = refresh
          ? page.items
          : <LibraryArtist>[...current.items, ...page.items];
      _state = _state.copyWith(
        artists: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          items: merged,
          nextCursor: page.nextCursor,
          errorMessage: null,
        ),
      );
    } catch (_) {
      _state = _state.copyWith(
        artists: current.copyWith(
          isLoading: false,
          isLoadingMore: false,
          hasLoaded: true,
          errorMessage: 'Failed to load artists.',
        ),
      );
    }
    notifyListeners();
  }

  Future<void> unsaveTrack(String trackId) async {
    try {
      await _repository.unsaveTrack(trackId);
      _state = _state.copyWith(
        likedSongs: _state.likedSongs.copyWith(
          items: _state.likedSongs.items
              .where((item) => item.id != trackId)
              .toList(growable: false),
        ),
      );
      notifyListeners();
    } catch (_) {}
  }
}
