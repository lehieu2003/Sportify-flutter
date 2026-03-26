import '../../../../core/config/api_config.dart';

class PlaylistDetail {
  const PlaylistDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.isPublic,
    required this.trackCount,
  });

  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final bool isPublic;
  final int trackCount;

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final rawTrackCount = json['trackCount'] ?? json['track_count'];
    final parsedTrackCount = switch (rawTrackCount) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    return PlaylistDetail(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      isPublic: json['isPublic'] == true || json['is_public'] == true,
      trackCount: parsedTrackCount,
    );
  }
}

class PlaylistTrack {
  const PlaylistTrack({
    required this.trackId,
    required this.position,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.durationMs,
  });

  final String trackId;
  final int position;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int durationMs;

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
    final rawPosition = json['position'];
    final position = switch (rawPosition) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    final rawDuration = json['durationMs'] ?? json['duration_ms'];
    final durationMs = switch (rawDuration) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    return PlaylistTrack(
      trackId: (json['trackId'] ?? json['track_id'] ?? '').toString(),
      position: position,
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? json['artist_name'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      audioUrl: ApiConfig.resolveUrl((json['audioUrl'] ?? json['audio_url'])?.toString()),
      durationMs: durationMs,
    );
  }
}
