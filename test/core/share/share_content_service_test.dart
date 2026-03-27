import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/core/share/share_content_service.dart';

void main() {
  group('ShareContentService', () {
    const service = ShareContentService();

    test('buildTrackPayload includes track/artist/deeplink', () {
      final payload = service.buildTrackPayload(
        trackId: 'track-123',
        title: 'Standing Next to You',
        artist: 'Jung Kook',
      );

      expect(payload.subject, 'Standing Next to You - Jung Kook');
      expect(payload.text, contains('Standing Next to You - Jung Kook'));
      expect(payload.text, contains('sportify://track/track-123'));
    });

    test('buildTrackPayload falls back for missing metadata', () {
      final payload = service.buildTrackPayload(
        trackId: 'track-xyz',
        title: ' ',
        artist: ' ',
      );

      expect(payload.subject, 'Unknown track - Unknown artist');
      expect(payload.text, contains('sportify://track/track-xyz'));
    });
  });
}
