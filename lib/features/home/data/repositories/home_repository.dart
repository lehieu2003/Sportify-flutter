import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../models/home_feed.dart';
import '../models/track.dart';
import '../services/home_api_service.dart';

abstract class HomeTracksRepository {
  Stream<HomeFeed> watchHomeFeed();
}

abstract class HomeCacheStore {
  Future<HomeFeed> readFeed();
  Future<void> writeFeed(HomeFeed feed);
}

class SharedPrefsHomeCacheStore implements HomeCacheStore {
  SharedPrefsHomeCacheStore(this._prefs);

  static const _feedKey = 'home.feed.v2';
  final SharedPreferences _prefs;

  @override
  Future<HomeFeed> readFeed() async {
    final raw = _prefs.getString(_feedKey);
    if (raw == null || raw.isEmpty) {
      return HomeFeed.empty();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return HomeFeed.fromJson(decoded);
  }

  @override
  Future<void> writeFeed(HomeFeed feed) async {
    await _prefs.setString(_feedKey, jsonEncode(feed.toJson()));
  }
}

class HomeRepository implements HomeTracksRepository {
  HomeRepository({
    required HomeRemoteDataSource service,
    required HomeCacheStore cacheStore,
  }) : _service = service,
       _cacheStore = cacheStore;

  final HomeRemoteDataSource _service;
  final HomeCacheStore _cacheStore;

  @override
  Stream<HomeFeed> watchHomeFeed() async* {
    final localFeed = await _cacheStore.readFeed();
    if (localFeed.trending.isNotEmpty ||
        localFeed.madeForYou.isNotEmpty ||
        localFeed.recentlyPlayed.isNotEmpty) {
      yield localFeed;
    }

    final payload = await _service.fetchHomePayload();
    final remoteFeed = HomeFeed(
      quickAccess: payload.quickAccess.map(_mapRemoteTrack).toList(growable: false),
      recentlyPlayed: payload.recentlyPlayed.map(_mapRemoteTrack).toList(growable: false),
      madeForYou: payload.madeForYou.map(_mapRemoteTrack).toList(growable: false),
      trending: payload.trending.map(_mapRemoteTrack).toList(growable: false),
      newReleases: payload.newReleases.map(_mapRemoteTrack).toList(growable: false),
      genres: payload.genres.map(_mapRemoteGenre).toList(growable: false),
    );
    await _cacheStore.writeFeed(remoteFeed);
    yield remoteFeed;
  }

  Track _mapRemoteTrack(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString();
    return Track(
      id: json['id'].toString(),
      title: title.trim().isNotEmpty ? title : 'Untitled track',
      subtitle: (json['artist'] ?? json['artist_name'] ?? 'Unknown artist').toString(),
      thumbnailUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      audioUrl: ApiConfig.resolveUrl((json['audioUrl'] ?? json['audio_url'])?.toString()),
    );
  }

  Track _mapRemoteGenre(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString();
    return Track(
      id: (json['id'] ?? name).toString(),
      title: name.isNotEmpty ? name : 'Genre',
      subtitle: '${json['trackCount'] ?? json['track_count'] ?? 0} tracks',
      thumbnailUrl: '',
      audioUrl: '',
    );
  }
}
