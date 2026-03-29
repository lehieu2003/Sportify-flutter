import '../../../../core/config/api_config.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    this.latestTrackCoverUrl,
    required this.audioUrl,
    this.albumId,
    this.albumTitle,
    this.trackCount,
    this.latestTrackId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String? latestTrackCoverUrl;
  final String audioUrl;
  final String? albumId;
  final String? albumTitle;
  final int? trackCount;
  final String? latestTrackId;

  factory Track.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? '').toString();
    final artist =
        (json['artist'] ?? json['artist_name'] ?? json['subtitle'] ?? '').toString();
    final subtitleFallback = json['trackCount'] != null
        ? '${json['trackCount']} tracks'
        : 'Unknown';
    return Track(
      id: json['id'].toString(),
      title: title.trim().isNotEmpty ? title : 'Untitled track',
      subtitle: artist.trim().isNotEmpty ? artist : subtitleFallback,
      thumbnailUrl: ApiConfig.resolveUrl(
        (json['thumbnailUrl'] ?? json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      latestTrackCoverUrl: ApiConfig.resolveUrl(
        (json['latestTrackCoverUrl'] ?? json['latest_track_cover_url'])?.toString(),
      ),
      audioUrl: ApiConfig.resolveUrl(
        (json['audioUrl'] ?? json['audio_url'])?.toString(),
      ),
      albumId: (json['albumId'] ?? json['album_id'])?.toString(),
      albumTitle: (json['albumTitle'] ?? json['album_title'])?.toString(),
      trackCount: switch (json['trackCount'] ?? json['track_count']) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      },
      latestTrackId: (json['latestTrackId'] ?? json['latest_track_id'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'latestTrackCoverUrl': latestTrackCoverUrl,
      'audioUrl': audioUrl,
      'albumId': albumId,
      'albumTitle': albumTitle,
      'trackCount': trackCount,
      'latestTrackId': latestTrackId,
    };
  }
}
