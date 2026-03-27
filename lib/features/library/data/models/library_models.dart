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
      coverUrl: ApiConfig.resolveUrl(
        (json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      audioUrl: ApiConfig.resolveUrl(
        (json['audioUrl'] ?? json['audio_url'])?.toString(),
      ),
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
    this.ownerName = '',
    this.memberRole = '',
    this.isOwner = false,
    this.isCollaborative = false,
  });

  final String id;
  final String title;
  final String description;
  final int trackCount;
  final bool isPublic;
  final String ownerName;
  final String memberRole;
  final bool isOwner;
  final bool isCollaborative;

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
      ownerName: (json['ownerName'] ?? '').toString(),
      memberRole: (json['memberRole'] ?? '').toString(),
      isOwner: json['isOwner'] == true,
      isCollaborative: json['isCollaborative'] == true,
    );
  }
}

class LibraryAlbum {
  const LibraryAlbum({
    required this.id,
    required this.artistId,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.trackCount,
  });

  final String id;
  final String artistId;
  final String title;
  final String artist;
  final String coverUrl;
  final int trackCount;

  factory LibraryAlbum.fromJson(Map<String, dynamic> json) {
    return LibraryAlbum(
      id: (json['id'] ?? '').toString(),
      artistId: (json['artistId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl(
        (json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      trackCount: switch (json['trackCount']) {
        int value => value,
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
    );
  }
}

class LibraryArtist {
  const LibraryArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.albumCount,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int albumCount;

  factory LibraryArtist.fromJson(Map<String, dynamic> json) {
    return LibraryArtist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: ApiConfig.resolveUrl(
        (json['imageUrl'] ?? json['image_url'])?.toString(),
      ),
      albumCount: switch (json['albumCount']) {
        int value => value,
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
    );
  }
}

class CursorPage<T> {
  const CursorPage({required this.items, required this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}
