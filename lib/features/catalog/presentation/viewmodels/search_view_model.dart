import 'package:flutter/foundation.dart';

import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';

class SearchUiState {
  const SearchUiState({
    required this.isLoading,
    required this.items,
    required this.query,
    required this.activeGenre,
    required this.nextCursor,
    required this.discoverCards,
    required this.browseCategories,
    required this.recentSearches,
    this.errorMessage,
  });

  const SearchUiState.initial()
    : isLoading = false,
      items = const <CatalogTrack>[],
      query = '',
      activeGenre = null,
      nextCursor = null,
      discoverCards = const <SearchBrowseCard>[],
      browseCategories = const <SearchBrowseCard>[],
      recentSearches = const <SearchRecentItem>[],
      errorMessage = null;

  final bool isLoading;
  final List<CatalogTrack> items;
  final String query;
  final String? activeGenre;
  final String? nextCursor;
  final List<SearchBrowseCard> discoverCards;
  final List<SearchBrowseCard> browseCategories;
  final List<SearchRecentItem> recentSearches;
  final String? errorMessage;

  SearchUiState copyWith({
    bool? isLoading,
    List<CatalogTrack>? items,
    String? query,
    String? activeGenre,
    bool clearActiveGenre = false,
    String? nextCursor,
    List<SearchBrowseCard>? discoverCards,
    List<SearchBrowseCard>? browseCategories,
    List<SearchRecentItem>? recentSearches,
    String? errorMessage,
  }) {
    return SearchUiState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      query: query ?? this.query,
      activeGenre: clearActiveGenre ? null : (activeGenre ?? this.activeGenre),
      nextCursor: nextCursor,
      discoverCards: discoverCards ?? this.discoverCards,
      browseCategories: browseCategories ?? this.browseCategories,
      recentSearches: recentSearches ?? this.recentSearches,
      errorMessage: errorMessage,
    );
  }
}

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({required CatalogRepository repository})
    : _repository = repository;

  final CatalogRepository _repository;
  SearchUiState _state = const SearchUiState.initial();

  SearchUiState get state => _state;

  Future<void> _upsertQueryRecent(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    try {
      await _repository.upsertRecentSearch(
        type: 'track',
        itemId: 'query:${normalized.toLowerCase()}',
        title: normalized,
        subtitle: 'Search query',
      );
    } catch (_) {}
  }

  Future<void> loadLanding() async {
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.getSearchBrowse(),
        _repository.getRecentSearches(limit: 20),
      ]);
      final browse = results[0] as SearchBrowsePayload;
      final recent = results[1] as List<SearchRecentItem>;
      _state = _state.copyWith(
        discoverCards: browse.discoverCards,
        browseCategories: browse.browseCategories,
        recentSearches: recent,
        errorMessage: null,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        query: '',
        clearActiveGenre: true,
        items: const <CatalogTrack>[],
        nextCursor: null,
        errorMessage: null,
      );
      notifyListeners();
      await loadLanding();
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      query: query,
      clearActiveGenre: true,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final page = await _repository.searchTracks(query: query, limit: 20);
      _state = _state.copyWith(
        isLoading: false,
        items: page.items,
        clearActiveGenre: true,
        nextCursor: page.nextCursor,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        items: const <CatalogTrack>[],
        clearActiveGenre: true,
        nextCursor: null,
        errorMessage: 'Failed to search tracks.',
      );
    }
    notifyListeners();
  }

  Future<void> submitQuery(String query) async {
    final normalized = query.trim();
    await search(normalized);
    if (normalized.isEmpty) return;
    await _upsertQueryRecent(normalized);
    await loadLanding();
  }

  Future<void> searchByGenre(String genreSlug) async {
    final normalized = genreSlug.trim();
    if (normalized.isEmpty) return;
    _state = _state.copyWith(
      isLoading: true,
      query: normalized,
      activeGenre: normalized,
      items: const <CatalogTrack>[],
      nextCursor: null,
      errorMessage: null,
    );
    notifyListeners();
    try {
      final page = await _repository.searchTracks(genre: normalized, limit: 20);
      _state = _state.copyWith(
        isLoading: false,
        items: page.items,
        activeGenre: normalized,
        nextCursor: page.nextCursor,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        items: const <CatalogTrack>[],
        activeGenre: normalized,
        nextCursor: null,
        errorMessage: 'Failed to search tracks.',
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.isLoading ||
        _state.nextCursor == null ||
        _state.nextCursor!.isEmpty) {
      return;
    }
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final page = await _repository.searchTracks(
        query: _state.activeGenre == null ? _state.query : null,
        genre: _state.activeGenre,
        limit: 20,
        cursor: _state.nextCursor,
      );
      _state = _state.copyWith(
        isLoading: false,
        items: <CatalogTrack>[..._state.items, ...page.items],
        nextCursor: page.nextCursor,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load more tracks.',
      );
    }
    notifyListeners();
  }

  Future<void> addRecentFromTrack(CatalogTrack track) async {
    final albumId = track.albumId;
    if (albumId == null || albumId.isEmpty) return;
    try {
      await _repository.upsertRecentSearch(
        type: 'album',
        itemId: albumId,
        title: track.albumTitle?.trim().isNotEmpty == true
            ? track.albumTitle!
            : track.title,
        subtitle: track.artist,
        imageUrl: track.coverUrl,
      );
      await loadLanding();
    } catch (_) {}
  }

  Future<void> removeRecent(String recentId) async {
    try {
      await _repository.deleteRecentSearch(recentId);
      _state = _state.copyWith(
        recentSearches: _state.recentSearches
            .where((it) => it.id != recentId)
            .toList(growable: false),
      );
      notifyListeners();
    } catch (_) {}
  }
}
