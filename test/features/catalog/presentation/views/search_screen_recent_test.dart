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

class _FakeCatalogApiService extends CatalogApiService {
  _FakeCatalogApiService()
      : super(
          AuthorizedHttpClient(
            baseClient: http.Client(),
            tokenProvider: () => null,
          ),
        );

  @override
  Future<SearchBrowsePayload> getSearchBrowse() async {
    return const SearchBrowsePayload(
      discoverCards: <SearchBrowseCard>[
        SearchBrowseCard(
          title: 'Discover A',
          imageUrl: '',
          deeplinkType: 'album',
          deeplinkId: '11111111-1111-1111-1111-111111111111',
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
        id: '22222222-2222-2222-2222-222222222222',
        type: 'album',
        itemId: '11111111-1111-1111-1111-111111111111',
        title: 'Recent Album',
        subtitle: 'Recent Artist',
        imageUrl: '',
      ),
    ];
  }
}

void main() {
  testWidgets('SearchScreen renders recent searches in default state', (tester) async {
    final vm = SearchViewModel(
      repository: CatalogRepository(service: _FakeCatalogApiService()),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<SearchViewModel>.value(value: vm),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SearchScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Recent Album'), findsOneWidget);
  });
}
