import '../../../../core/config/api_config.dart';

class CatalogTrack {
  const CatalogTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.albumId,
    required this.albumTitle,
    required this.coverUrl,
    required this.audioUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String? albumId;
  final String? albumTitle;
  final String coverUrl;
  final String audioUrl;

  factory CatalogTrack.fromJson(Map<String, dynamic> json) {
    return CatalogTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      artistId: (json['artistId'] ?? '').toString(),
      albumId: json['albumId']?.toString(),
      albumTitle: json['albumTitle']?.toString(),
      coverUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      audioUrl: ApiConfig.resolveUrl((json['audioUrl'] ?? json['audio_url'])?.toString()),
    );
  }
}

class CatalogTracksPage {
  const CatalogTracksPage({
    required this.items,
    required this.nextCursor,
  });

  final List<CatalogTrack> items;
  final String? nextCursor;
}

class SearchBrowseCard {
  const SearchBrowseCard({
    required this.title,
    required this.imageUrl,
    required this.deeplinkType,
    required this.deeplinkId,
    this.colorHex,
  });

  final String title;
  final String imageUrl;
  final String deeplinkType;
  final String deeplinkId;
  final String? colorHex;

  factory SearchBrowseCard.fromJson(Map<String, dynamic> json) {
    return SearchBrowseCard(
      title: (json['title'] ?? '').toString(),
      imageUrl: ApiConfig.resolveUrl(json['imageUrl']?.toString()),
      deeplinkType: (json['deeplinkType'] ?? '').toString(),
      deeplinkId: (json['deeplinkId'] ?? '').toString(),
      colorHex: json['colorHex']?.toString(),
    );
  }
}

class SearchBrowsePayload {
  const SearchBrowsePayload({
    required this.discoverCards,
    required this.browseCategories,
  });

  final List<SearchBrowseCard> discoverCards;
  final List<SearchBrowseCard> browseCategories;
}

class SearchRecentItem {
  const SearchRecentItem({
    required this.id,
    required this.type,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  final String id;
  final String type;
  final String itemId;
  final String title;
  final String subtitle;
  final String imageUrl;

  factory SearchRecentItem.fromJson(Map<String, dynamic> json) {
    return SearchRecentItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      imageUrl: ApiConfig.resolveUrl(json['imageUrl']?.toString()),
    );
  }
}

class CatalogArtist {
  const CatalogArtist({
    required this.id,
    required this.name,
    required this.bio,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String bio;
  final String imageUrl;

  factory CatalogArtist.fromJson(Map<String, dynamic> json) {
    return CatalogArtist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
    );
  }
}

class CatalogAlbum {
  const CatalogAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.releaseDate,
  });

  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String? releaseDate;

  factory CatalogAlbum.fromJson(Map<String, dynamic> json) {
    return CatalogAlbum(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl((json['coverUrl'] ?? json['cover_url'])?.toString()),
      releaseDate: json['releaseDate']?.toString(),
    );
  }
}
