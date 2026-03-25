import 'track.dart';

class HomeFeed {
  const HomeFeed({
    required this.quickAccess,
    required this.recentlyPlayed,
    required this.madeForYou,
    required this.trending,
    required this.newReleases,
    required this.genres,
  });

  final List<Track> quickAccess;
  final List<Track> recentlyPlayed;
  final List<Track> madeForYou;
  final List<Track> trending;
  final List<Track> newReleases;
  final List<Track> genres;

  factory HomeFeed.empty() {
    return const HomeFeed(
      quickAccess: <Track>[],
      recentlyPlayed: <Track>[],
      madeForYou: <Track>[],
      trending: <Track>[],
      newReleases: <Track>[],
      genres: <Track>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'quickAccess': quickAccess.map((item) => item.toJson()).toList(growable: false),
      'recentlyPlayed': recentlyPlayed.map((item) => item.toJson()).toList(growable: false),
      'madeForYou': madeForYou.map((item) => item.toJson()).toList(growable: false),
      'trending': trending.map((item) => item.toJson()).toList(growable: false),
      'newReleases': newReleases.map((item) => item.toJson()).toList(growable: false),
      'genres': genres.map((item) => item.toJson()).toList(growable: false),
    };
  }

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    List<Track> parseList(String key) {
      final raw = json[key] as List<dynamic>? ?? const <dynamic>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Track.fromJson)
          .toList(growable: false);
    }

    return HomeFeed(
      quickAccess: parseList('quickAccess'),
      recentlyPlayed: parseList('recentlyPlayed'),
      madeForYou: parseList('madeForYou'),
      trending: parseList('trending'),
      newReleases: parseList('newReleases'),
      genres: parseList('genres'),
    );
  }
}
