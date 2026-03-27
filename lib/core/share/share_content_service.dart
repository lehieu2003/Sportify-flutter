import 'package:share_plus/share_plus.dart';

class SharePayload {
  const SharePayload({required this.subject, required this.text});

  final String subject;
  final String text;
}

class ShareContentService {
  const ShareContentService();

  SharePayload buildTrackPayload({
    required String trackId,
    required String title,
    required String artist,
    String? albumTitle,
  }) {
    final safeTitle = title.trim().isEmpty ? 'Unknown track' : title.trim();
    final safeArtist = artist.trim().isEmpty ? 'Unknown artist' : artist.trim();
    final safeAlbum = albumTitle?.trim();
    final deepLink = 'sportify://track/$trackId';
    final albumLine = (safeAlbum != null && safeAlbum.isNotEmpty)
        ? '\nAlbum: $safeAlbum'
        : '';
    final text =
        'Listening on Sportify:\n$safeTitle - $safeArtist$albumLine\n$deepLink';
    return SharePayload(subject: '$safeTitle - $safeArtist', text: text);
  }

  Future<void> sharePayload(SharePayload payload) async {
    await Share.share(payload.text, subject: payload.subject);
  }

  Future<void> shareTrack({
    required String trackId,
    required String title,
    required String artist,
    String? albumTitle,
  }) async {
    final payload = buildTrackPayload(
      trackId: trackId,
      title: title,
      artist: artist,
      albumTitle: albumTitle,
    );
    await sharePayload(payload);
  }
}
