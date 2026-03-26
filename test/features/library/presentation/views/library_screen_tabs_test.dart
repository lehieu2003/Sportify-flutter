import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:sportify/core/network/authorized_http_client.dart';
import 'package:sportify/features/library/data/models/library_models.dart';
import 'package:sportify/features/library/data/repositories/library_repository.dart';
import 'package:sportify/features/library/data/services/library_api_service.dart';
import 'package:sportify/features/library/presentation/viewmodels/library_view_model.dart';
import 'package:sportify/features/library/presentation/views/library_screen.dart';
import 'package:sportify/features/playlists/data/repositories/playlist_repository.dart';
import 'package:sportify/features/playlists/data/services/playlist_api_service.dart';

class _FakeLibraryApiService extends LibraryApiService {
  _FakeLibraryApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );

  @override
  Future<List<LibraryTrack>> getSavedTracks({int limit = 50}) async {
    return const <LibraryTrack>[
      LibraryTrack(
        id: '1',
        title: 'Downloaded Track',
        artist: 'Artist',
        coverUrl: '',
        audioUrl: '',
      ),
    ];
  }

  @override
  Future<CursorPage<LibraryPlaylist>> getOwnedPlaylists({int limit = 20, String? cursor}) async {
    return const CursorPage<LibraryPlaylist>(
      items: <LibraryPlaylist>[
        LibraryPlaylist(
          id: 'p1',
          title: 'Playlist A',
          description: '',
          trackCount: 2,
          isPublic: true,
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<CursorPage<LibraryAlbum>> getSavedAlbums({int limit = 20, String? cursor}) async {
    return const CursorPage<LibraryAlbum>(
      items: <LibraryAlbum>[
        LibraryAlbum(
          id: 'a1',
          artistId: 'ar1',
          title: 'Album A',
          artist: 'Artist A',
          coverUrl: '',
          trackCount: 10,
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<CursorPage<LibraryArtist>> getFollowedArtists({int limit = 20, String? cursor}) async {
    return const CursorPage<LibraryArtist>(
      items: <LibraryArtist>[
        LibraryArtist(
          id: 'ar1',
          name: 'Artist A',
          imageUrl: '',
          albumCount: 3,
        ),
      ],
      nextCursor: null,
    );
  }
}

void main() {
  testWidgets('LibraryScreen switches tabs and renders corresponding content', (tester) async {
    final vm = LibraryViewModel(
      repository: LibraryRepository(service: _FakeLibraryApiService()),
      playlistRepository: PlaylistRepository(
        service: PlaylistApiService(
          AuthorizedHttpClient(baseClient: http.Client(), tokenProvider: () => null),
        ),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<LibraryViewModel>.value(value: vm),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LibraryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Playlist A'), findsOneWidget);

    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('Album A'), findsOneWidget);

    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('Artist A'), findsOneWidget);
  });
}
