import 'package:flutter/foundation.dart';

import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';

class SearchUiState {
  const SearchUiState({
    required this.isLoading,
    required this.items,
    required this.query,
    required this.nextCursor,
    this.errorMessage,
  });

  const SearchUiState.initial()
    : isLoading = false,
      items = const <CatalogTrack>[],
      query = '',
      nextCursor = null,
      errorMessage = null;

  final bool isLoading;
  final List<CatalogTrack> items;
  final String query;
  final String? nextCursor;
  final String? errorMessage;

  SearchUiState copyWith({
    bool? isLoading,
    List<CatalogTrack>? items,
    String? query,
    String? nextCursor,
    String? errorMessage,
  }) {
    return SearchUiState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      query: query ?? this.query,
      nextCursor: nextCursor,
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

  Future<void> search(String query) async {
    _state = _state.copyWith(isLoading: true, query: query, errorMessage: null);
    notifyListeners();

    try {
      final page = await _repository.searchTracks(query: query, limit: 20);
      _state = _state.copyWith(
        isLoading: false,
        items: page.items,
        nextCursor: page.nextCursor,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        items: const <CatalogTrack>[],
        nextCursor: null,
        errorMessage: 'Failed to search tracks.',
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.isLoading || _state.nextCursor == null || _state.nextCursor!.isEmpty) {
      return;
    }
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final page = await _repository.searchTracks(
        query: _state.query,
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
}
