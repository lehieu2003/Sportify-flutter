import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:sportify/core/network/authorized_http_client.dart';
import 'package:sportify/features/catalog/data/models/catalog_models.dart';
import 'package:sportify/features/catalog/data/repositories/catalog_repository.dart';
import 'package:sportify/features/catalog/data/services/catalog_api_service.dart';
import 'package:sportify/features/catalog/presentation/viewmodels/search_view_model.dart';
import 'package:sportify/features/catalog/presentation/views/search_screen.dart';
import 'package:sportify/features/library/data/models/library_models.dart';
import 'package:sportify/features/library/data/repositories/library_repository.dart';
import 'package:sportify/features/library/data/services/library_api_service.dart';
import 'package:sportify/features/playlists/data/models/playlist_models.dart';
import 'package:sportify/features/playlists/data/repositories/playlist_repository.dart';
import 'package:sportify/features/playlists/data/services/playlist_api_service.dart';

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
  _FakeCatalogRepository() : super(service: _FakeCatalogApiService());

  @override
  Future<SearchBrowsePayload> getSearchBrowse() async {
    return const SearchBrowsePayload(
      discoverCards: <SearchBrowseCard>[
        SearchBrowseCard(
          title: 'Discover A',
          imageUrl: '',
          deeplinkType: 'album',
          deeplinkId: 'album-1',
        ),
      ],
      browseCategories: <SearchBrowseCard>[
        SearchBrowseCard(
          title: 'Nhạc',
          imageUrl: '',
          deeplinkType: 'genre',
          deeplinkId: 'Pop',
          colorHex: '#D84093',
        ),
      ],
    );
  }

  @override
  Future<List<SearchRecentItem>> getRecentSearches({int limit = 20}) async {
    return const <SearchRecentItem>[
      SearchRecentItem(
        id: 'recent-album',
        type: 'album',
        itemId: 'album-1',
        title: 'Recent Album',
        subtitle: 'Album Artist',
        imageUrl: '',
      ),
      SearchRecentItem(
        id: 'recent-artist',
        type: 'artist',
        itemId: 'artist-1',
        title: 'Recent Artist',
        subtitle: 'Artist',
        imageUrl: '',
      ),
      SearchRecentItem(
        id: 'recent-playlist',
        type: 'playlist',
        itemId: 'playlist-1',
        title: 'Recent Playlist',
        subtitle: 'Playlist',
        imageUrl: '',
      ),
    ];
  }

  @override
  Future<CatalogAlbum> getAlbumById(String albumId) async {
    return const CatalogAlbum(
      id: 'album-1',
      title: 'Test Album',
      artist: 'Test Artist',
      coverUrl: '',
    );
  }

  @override
  Future<List<CatalogTrack>> getAlbumTracks(String albumId) async {
    return const <CatalogTrack>[
      CatalogTrack(
        id: 'track-1',
        title: 'Track One',
        artist: 'Test Artist',
        artistId: 'artist-1',
        albumId: 'album-1',
        albumTitle: 'Test Album',
        coverUrl: '',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
    ];
  }

  @override
  Future<CatalogArtist> getArtistById(String artistId) async {
    return const CatalogArtist(
      id: 'artist-1',
      name: 'Test Artist',
      bio: '',
      imageUrl: '',
    );
  }

  @override
  Future<List<CatalogTrack>> getArtistTopTracks(String artistId, {int limit = 10}) async {
    return const <CatalogTrack>[
      CatalogTrack(
        id: 'artist-track-1',
        title: 'Artist Track',
        artist: 'Test Artist',
        artistId: 'artist-1',
        albumId: 'album-1',
        albumTitle: 'Test Album',
        coverUrl: '',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
    ];
  }

  @override
  Future<CatalogTracksPage> getArtistAlbums({
    required String artistId,
    int limit = 20,
    String? cursor,
  }) async {
    return const CatalogTracksPage(
      items: <CatalogTrack>[
        CatalogTrack(
          id: 'album-track-1',
          title: 'Album Track',
          artist: 'Test Artist',
          artistId: 'artist-1',
          albumId: 'album-1',
          albumTitle: 'Test Album',
          coverUrl: '',
          audioUrl: '',
        ),
      ],
      nextCursor: null,
    );
  }
}

class _FakeLibraryApiService extends LibraryApiService {
  _FakeLibraryApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );
}

class _FakeLibraryRepository extends LibraryRepository {
  _FakeLibraryRepository() : super(service: _FakeLibraryApiService());

  @override
  Future<CursorPage<LibraryArtist>> getFollowedArtists({int limit = 20, String? cursor}) async {
    return const CursorPage<LibraryArtist>(
      items: <LibraryArtist>[],
      nextCursor: null,
    );
  }
}

class _FakePlaylistApiService extends PlaylistApiService {
  _FakePlaylistApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );
}

class _FakePlaylistRepository extends PlaylistRepository {
  _FakePlaylistRepository() : super(service: _FakePlaylistApiService());

  @override
  Future<PlaylistDetail> getPlaylistById(String playlistId) async {
    return const PlaylistDetail(
      id: 'playlist-1',
      title: 'Playlist Detail',
      description: '',
      coverUrl: '',
      isPublic: true,
      trackCount: 1,
    );
  }

  @override
  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId) async {
    return const <PlaylistTrack>[
      PlaylistTrack(
        trackId: 'track-1',
        position: 1,
        title: 'Playlist Track',
        artist: 'Artist',
        coverUrl: '',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        durationMs: 120000,
      ),
    ];
  }
}

Widget _buildSearchApp({
  required SearchViewModel vm,
  required CatalogRepository catalogRepository,
  required LibraryRepository libraryRepository,
  required PlaylistRepository playlistRepository,
}) {
  return MultiProvider(
    providers: <SingleChildWidget>[
      ChangeNotifierProvider<SearchViewModel>.value(value: vm),
      Provider<CatalogRepository>.value(value: catalogRepository),
      Provider<LibraryRepository>.value(value: libraryRepository),
      Provider<PlaylistRepository>.value(value: playlistRepository),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SearchScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('SearchScreen renders recent searches in default state', (tester) async {
    final catalogRepository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: catalogRepository);

    await tester.pumpWidget(
      _buildSearchApp(
        vm: vm,
        catalogRepository: catalogRepository,
        libraryRepository: _FakeLibraryRepository(),
        playlistRepository: _FakePlaylistRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Recent Album'), findsOneWidget);
  });

  testWidgets('SearchScreen opens album detail from discover card', (tester) async {
    final catalogRepository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: catalogRepository);

    await tester.pumpWidget(
      _buildSearchApp(
        vm: vm,
        catalogRepository: catalogRepository,
        libraryRepository: _FakeLibraryRepository(),
        playlistRepository: _FakePlaylistRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discover A'));
    await tester.pumpAndSettle();

    expect(find.text('Test Album'), findsWidgets);
  });

  testWidgets('SearchScreen opens artist detail from recent item', (tester) async {
    final catalogRepository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: catalogRepository);

    await tester.pumpWidget(
      _buildSearchApp(
        vm: vm,
        catalogRepository: catalogRepository,
        libraryRepository: _FakeLibraryRepository(),
        playlistRepository: _FakePlaylistRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Recent Artist'),
      120,
      scrollable: listFinder,
    );
    await tester.drag(listFinder, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recent Artist'));
    await tester.pumpAndSettle();

    expect(find.text('Popular'), findsOneWidget);
  });

  testWidgets('SearchScreen opens playlist detail from recent item', (tester) async {
    final catalogRepository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: catalogRepository);

    await tester.pumpWidget(
      _buildSearchApp(
        vm: vm,
        catalogRepository: catalogRepository,
        libraryRepository: _FakeLibraryRepository(),
        playlistRepository: _FakePlaylistRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Recent Playlist'),
      120,
      scrollable: listFinder,
    );
    await tester.tap(find.text('Recent Playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Playlist Detail'), findsOneWidget);
  });
}
