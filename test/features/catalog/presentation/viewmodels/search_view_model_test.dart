import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:sportify/core/network/authorized_http_client.dart';
import 'package:sportify/features/catalog/data/models/catalog_models.dart';
import 'package:sportify/features/catalog/data/repositories/catalog_repository.dart';
import 'package:sportify/features/catalog/data/services/catalog_api_service.dart';
import 'package:sportify/features/catalog/presentation/viewmodels/search_view_model.dart';

class _FakeCatalogRepository extends CatalogRepository {
  _FakeCatalogRepository() : super(service: _NoopCatalogApiService());

  String? upsertType;
  String? upsertItemId;
  String? upsertTitle;
  String? lastGenre;
  int searchCallCount = 0;

  @override
  Future<CatalogTracksPage> searchTracks({
    String? query,
    String? genre,
    int limit = 20,
    String? cursor,
  }) async {
    searchCallCount += 1;
    lastGenre = genre;
    return const CatalogTracksPage(
      items: <CatalogTrack>[
        CatalogTrack(
          id: 'track-1',
          title: 'Track',
          artist: 'Artist',
          artistId: 'artist-1',
          albumId: 'album-1',
          albumTitle: 'Album',
          coverUrl: '',
          audioUrl: '',
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<void> upsertRecentSearch({
    required String type,
    required String itemId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    upsertType = type;
    upsertItemId = itemId;
    upsertTitle = title;
  }

  @override
  Future<SearchBrowsePayload> getSearchBrowse() async {
    return const SearchBrowsePayload(discoverCards: <SearchBrowseCard>[], browseCategories: <SearchBrowseCard>[]);
  }

  @override
  Future<List<SearchRecentItem>> getRecentSearches({int limit = 20}) async {
    return const <SearchRecentItem>[];
  }
}

class _NoopCatalogApiService extends CatalogApiService {
  _NoopCatalogApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );
}

void main() {
  test('submitQuery performs search and upserts query recent', () async {
    final repository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: repository);

    await vm.submitQuery('Jung Kook');

    expect(repository.searchCallCount, 1);
    expect(repository.upsertType, 'track');
    expect(repository.upsertItemId, 'query:jung kook');
    expect(repository.upsertTitle, 'Jung Kook');
    expect(vm.state.items, isNotEmpty);
  });

  test('searchByGenre requests tracks with genre parameter', () async {
    final repository = _FakeCatalogRepository();
    final vm = SearchViewModel(repository: repository);

    await vm.searchByGenre('pop');

    expect(repository.lastGenre, 'pop');
    expect(vm.state.items.first.title, 'Track');
  });
}
