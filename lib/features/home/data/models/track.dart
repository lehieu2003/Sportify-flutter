class Track {
  const Track({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;

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
      thumbnailUrl:
          (json['thumbnailUrl'] ?? json['coverUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
