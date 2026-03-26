import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:sportify/core/network/authorized_http_client.dart';
import 'package:sportify/features/catalog/data/models/catalog_models.dart';
import 'package:sportify/features/catalog/data/repositories/catalog_repository.dart';
import 'package:sportify/features/catalog/data/services/catalog_api_service.dart';
import 'package:sportify/features/catalog/presentation/views/album_detail_screen.dart';

class _FakeCatalogApiService extends CatalogApiService {
  _FakeCatalogApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );
}

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository({
    this.shouldThrow = false,
    this.tracks = const <CatalogTrack>[],
  }) : super(service: _FakeCatalogApiService());

  final bool shouldThrow;
  final List<CatalogTrack> tracks;

  @override
  Future<CatalogAlbum> getAlbumById(String albumId) async {
    if (shouldThrow) throw Exception('boom');
    return const CatalogAlbum(
      id: 'album-1',
      title: 'Test Album',
      artist: 'Test Artist',
      coverUrl: '',
    );
  }

  @override
  Future<List<CatalogTrack>> getAlbumTracks(String albumId) async {
    if (shouldThrow) throw Exception('boom');
    return tracks;
  }
}

void main() {
  testWidgets('AlbumDetailScreen renders loaded state', (tester) async {
    final repository = _FakeCatalogRepository(
      tracks: const <CatalogTrack>[
        CatalogTrack(
          id: 'track-1',
          title: 'Track One',
          artist: 'Artist',
          artistId: 'artist-1',
          albumId: 'album-1',
          albumTitle: 'Test Album',
          coverUrl: '',
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CatalogRepository>.value(value: repository),
        ],
        child: const MaterialApp(
          home: AlbumDetailScreen(albumId: 'album-1'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Test Album'), findsOneWidget);
    expect(find.text('Track One'), findsOneWidget);
    expect(find.text('Play all'), findsOneWidget);
  });

  testWidgets('AlbumDetailScreen renders error state', (tester) async {
    final repository = _FakeCatalogRepository(shouldThrow: true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CatalogRepository>.value(value: repository),
        ],
        child: const MaterialApp(
          home: AlbumDetailScreen(albumId: 'album-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to load album.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
