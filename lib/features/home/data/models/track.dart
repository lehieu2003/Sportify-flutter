import '../../../../core/config/api_config.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.audioUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String audioUrl;

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
      audioUrl: ApiConfig.resolveUrl(
        (json['audioUrl'] ?? json['audio_url'])?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
    };
  }
}
