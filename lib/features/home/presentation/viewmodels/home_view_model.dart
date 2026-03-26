import 'package:flutter/foundation.dart';

import '../../data/models/home_feed.dart';
import '../../data/models/track.dart';
import '../../data/repositories/home_repository.dart';
import '../models/home_media_item.dart';

class HomeUiState {
  const HomeUiState({
    required this.isLoading,
    required this.quickAccess,
    required this.recentlyPlayed,
    required this.madeForYou,
    required this.trending,
    required this.newReleases,
    required this.genres,
    this.errorMessage,
  });

  const HomeUiState.initial()
    : isLoading = false,
      quickAccess = const <HomeMediaItem>[],
      recentlyPlayed = const <HomeMediaItem>[],
      madeForYou = const <HomeMediaItem>[],
      trending = const <HomeMediaItem>[],
      newReleases = const <HomeMediaItem>[],
      genres = const <HomeMediaItem>[],
      errorMessage = null;

  final bool isLoading;
  final List<HomeMediaItem> quickAccess;
  final List<HomeMediaItem> recentlyPlayed;
  final List<HomeMediaItem> madeForYou;
  final List<HomeMediaItem> trending;
  final List<HomeMediaItem> newReleases;
  final List<HomeMediaItem> genres;
  final String? errorMessage;

  HomeUiState copyWith({
    bool? isLoading,
    List<HomeMediaItem>? quickAccess,
    List<HomeMediaItem>? recentlyPlayed,
    List<HomeMediaItem>? madeForYou,
    List<HomeMediaItem>? trending,
    List<HomeMediaItem>? newReleases,
    List<HomeMediaItem>? genres,
    String? errorMessage,
  }) {
    return HomeUiState(
      isLoading: isLoading ?? this.isLoading,
      quickAccess: quickAccess ?? this.quickAccess,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      madeForYou: madeForYou ?? this.madeForYou,
      trending: trending ?? this.trending,
      newReleases: newReleases ?? this.newReleases,
      genres: genres ?? this.genres,
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

  HomeMediaItem _toItem(Track track) {
    final albumId = track.albumId?.trim();
    return HomeMediaItem(
      id: albumId != null && albumId.isNotEmpty ? albumId : track.id,
      title: track.title,
      subtitle: track.subtitle,
      imageUrl: track.thumbnailUrl,
      audioUrl: track.audioUrl,
      albumId: albumId,
      trackCount: track.trackCount,
      latestTrackId: track.latestTrackId,
    );
  }

  List<HomeMediaItem> _toAlbumItems(List<Track> tracks) {
    final mapped = tracks.map(_toItem);
    final unique = <String, HomeMediaItem>{};
    for (final item in mapped) {
      final albumId = item.albumId?.trim();
      if (albumId == null || albumId.isEmpty) {
        continue;
      }
      final key = 'album:$albumId';
      unique.putIfAbsent(key, () => item);
    }
    return <HomeMediaItem>[...unique.values];
  }

  HomeUiState _fromFeed(HomeFeed feed) {
    return _state.copyWith(
      isLoading: false,
      quickAccess: _toAlbumItems(feed.quickAccess),
      recentlyPlayed: _toAlbumItems(feed.recentlyPlayed),
      madeForYou: _toAlbumItems(feed.madeForYou),
      trending: _toAlbumItems(feed.trending),
      newReleases: _toAlbumItems(feed.newReleases),
      genres: feed.genres.map(_toItem).toList(growable: false),
      errorMessage: null,
    );
  }

  Future<void> loadHomeFeed() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      await for (final data in _repository.watchHomeFeed()) {
        _state = _fromFeed(data);
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
