class HomeMediaItem {
  const HomeMediaItem({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.audioUrl = '',
    this.albumId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String audioUrl;
  final String? albumId;
}
