class HomeMediaItem {
  const HomeMediaItem({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.trackImageUrl,
    this.audioUrl = '',
    this.albumId,
    this.trackCount,
    this.latestTrackId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? trackImageUrl;
  final String audioUrl;
  final String? albumId;
  final int? trackCount;
  final String? latestTrackId;
}
