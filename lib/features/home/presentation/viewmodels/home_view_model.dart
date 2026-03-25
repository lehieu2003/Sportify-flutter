import 'package:flutter/foundation.dart';

import '../../data/models/track.dart';
import '../../data/repositories/home_repository.dart';

class HomeUiState {
  const HomeUiState({
    required this.isLoading,
    required this.tracks,
    this.errorMessage,
  });

  const HomeUiState.initial()
    : isLoading = false,
      tracks = const <Track>[],
      errorMessage = null;

  final bool isLoading;
  final List<Track> tracks;
  final String? errorMessage;

  HomeUiState copyWith({
    bool? isLoading,
    List<Track>? tracks,
    String? errorMessage,
  }) {
    return HomeUiState(
      isLoading: isLoading ?? this.isLoading,
      tracks: tracks ?? this.tracks,
      errorMessage: errorMessage,
    );
  }
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required HomeTracksRepository repository})
    : _repository = repository;

  final HomeTracksRepository _repository;
  HomeUiState _state = const HomeUiState.initial();

  HomeUiState get state => _state;

  Future<void> loadTrendingTracks() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      await for (final data in _repository.watchTrendingTracks()) {
        _state = _state.copyWith(
          isLoading: false,
          tracks: data,
          errorMessage: null,
        );
        notifyListeners();
      }
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load tracks. Pull to refresh.',
      );
      notifyListeners();
    }
  }
}
