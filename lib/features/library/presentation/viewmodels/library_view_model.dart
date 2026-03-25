import 'package:flutter/foundation.dart';

import '../../data/models/library_models.dart';
import '../../data/repositories/library_repository.dart';

class LibraryUiState {
  const LibraryUiState({
    required this.isLoading,
    required this.items,
    this.errorMessage,
  });

  const LibraryUiState.initial()
    : isLoading = false,
      items = const <LibraryTrack>[],
      errorMessage = null;

  final bool isLoading;
  final List<LibraryTrack> items;
  final String? errorMessage;

  LibraryUiState copyWith({
    bool? isLoading,
    List<LibraryTrack>? items,
    String? errorMessage,
  }) {
    return LibraryUiState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel({required LibraryRepository repository})
    : _repository = repository;

  final LibraryRepository _repository;
  LibraryUiState _state = const LibraryUiState.initial();

  LibraryUiState get state => _state;

  Future<void> loadSavedTracks() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final items = await _repository.getSavedTracks(limit: 100);
      _state = _state.copyWith(
        isLoading: false,
        items: items,
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
