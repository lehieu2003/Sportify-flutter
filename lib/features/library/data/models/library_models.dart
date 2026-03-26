import '../../../../core/config/api_config.dart';

class LibraryTrack {
  const LibraryTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;

  factory LibraryTrack.fromJson(Map<String, dynamic> json) {
    return LibraryTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      audioUrl: ApiConfig.resolveUrl((json['audioUrl'] ?? json['audio_url'])?.toString()),
    );
  }
}

class LibraryPlaylist {
  const LibraryPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.trackCount,
    required this.isPublic,
  });

  final String id;
  final String title;
  final String description;
  final int trackCount;
  final bool isPublic;

  factory LibraryPlaylist.fromJson(Map<String, dynamic> json) {
    final rawTrackCount = json['trackCount'];
    final parsedTrackCount = switch (rawTrackCount) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    final rawPublic = json['isPublic'];
    final parsedPublic = switch (rawPublic) {
      bool value => value,
      String value => value.toLowerCase() == 'true',
      _ => false,
    };
    return LibraryPlaylist(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      trackCount: parsedTrackCount,
      isPublic: parsedPublic,
    );
  }
}
