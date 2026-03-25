class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'].toString(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled track',
      artist: (json['artist'] as String?)?.trim().isNotEmpty == true
          ? json['artist'] as String
          : 'Unknown artist',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
