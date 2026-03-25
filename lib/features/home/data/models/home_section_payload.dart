class HomeSectionPayload {
  const HomeSectionPayload({
    required this.quickAccess,
    required this.recentlyPlayed,
    required this.madeForYou,
    required this.trending,
    required this.newReleases,
    required this.genres,
  });

  final List<Map<String, dynamic>> quickAccess;
  final List<Map<String, dynamic>> recentlyPlayed;
  final List<Map<String, dynamic>> madeForYou;
  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> newReleases;
  final List<Map<String, dynamic>> genres;
}
