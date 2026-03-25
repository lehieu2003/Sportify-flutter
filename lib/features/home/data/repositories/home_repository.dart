import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../services/home_api_service.dart';

abstract class HomeTracksRepository {
  Stream<List<Track>> watchTrendingTracks();
}

abstract class HomeCacheStore {
  Future<List<Track>> readTracks();
  Future<void> writeTracks(List<Track> tracks);
}

class SharedPrefsHomeCacheStore implements HomeCacheStore {
  SharedPrefsHomeCacheStore(this._prefs);

  static const _tracksKey = 'home.trending_tracks.v1';
  final SharedPreferences _prefs;

  @override
  Future<List<Track>> readTracks() async {
    final raw = _prefs.getString(_tracksKey);
    if (raw == null || raw.isEmpty) {
      return const <Track>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Track.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> writeTracks(List<Track> tracks) async {
    final payload = tracks.map((item) => item.toJson()).toList(growable: false);
    await _prefs.setString(_tracksKey, jsonEncode(payload));
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
  Stream<List<Track>> watchTrendingTracks() async* {
    final localTracks = await _cacheStore.readTracks();
    if (localTracks.isNotEmpty) {
      yield localTracks;
    }

    final remoteRaw = await _service.fetchTrendingRaw();
    final remoteTracks = remoteRaw.map(_mapRemoteTrack).toList(growable: false);
    await _cacheStore.writeTracks(remoteTracks);
    yield remoteTracks;
  }

  Track _mapRemoteTrack(Map<String, dynamic> json) {
    final id = json['id'].toString();
    return Track(
      id: id,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled track',
      artist: (json['artist'] as String?)?.trim().isNotEmpty == true
          ? json['artist'] as String
          : 'Unknown artist',
      thumbnailUrl: json['coverUrl'] as String? ?? '',
    );
  }
}
