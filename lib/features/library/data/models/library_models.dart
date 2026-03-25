class LibraryTrack {
  const LibraryTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String coverUrl;

  factory LibraryTrack.fromJson(Map<String, dynamic> json) {
    return LibraryTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
    );
  }
}
