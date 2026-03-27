import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/authorized_http_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/catalog/data/repositories/catalog_repository.dart';
import 'features/catalog/data/services/catalog_api_service.dart';
import 'features/catalog/presentation/viewmodels/search_view_model.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/data/services/home_api_service.dart';
import 'features/home/presentation/viewmodels/home_view_model.dart';
import 'features/library/data/repositories/library_repository.dart';
import 'features/library/data/services/library_api_service.dart';
import 'features/library/presentation/viewmodels/library_view_model.dart';
import 'features/listening/data/repositories/listening_repository.dart';
import 'features/listening/data/services/listening_api_service.dart';
import 'features/player/presentation/viewmodels/player_view_model.dart';
import 'features/playback/data/repositories/playback_repository.dart';
import 'features/playback/data/services/playback_api_service.dart';
import 'features/playlists/data/repositories/playlist_repository.dart';
import 'features/playlists/data/repositories/collaborative_playlist_repository.dart';
import 'features/playlists/data/services/collaborative_playlist_api_service.dart';
import 'features/playlists/data/services/playlist_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Keep fallback behavior in ApiConfig when .env is missing.
  }

  final prefs = await SharedPreferences.getInstance();
  final httpClient = http.Client();

  final authService = AuthApiService(client: httpClient);
  final authRepository = AuthRepository(service: authService, prefs: prefs);
  final authViewModel = AuthViewModel(repository: authRepository);

  final authorizedClient = AuthorizedHttpClient(
    baseClient: httpClient,
    tokenProvider: authRepository.readAccessToken,
    onUnauthorized: () async {
      final refreshed = await authRepository.tryRefreshAccessToken();
      if (!refreshed) {
        await authViewModel.signout();
      }
      return refreshed;
    },
  );

  final homeService = HomeApiService(authorizedClient);
  final homeCache = SharedPrefsHomeCacheStore(prefs);
  final homeRepository = HomeRepository(
    service: homeService,
    cacheStore: homeCache,
  );
  final homeViewModel = HomeViewModel(repository: homeRepository);
  final catalogService = CatalogApiService(authorizedClient);
  final catalogRepository = CatalogRepository(service: catalogService);
  final searchViewModel = SearchViewModel(repository: catalogRepository);

  final libraryService = LibraryApiService(authorizedClient);
  final libraryRepository = LibraryRepository(service: libraryService);
  final playlistRepository = PlaylistRepository(
    service: PlaylistApiService(authorizedClient),
  );
  final collaborativePlaylistRepository = CollaborativePlaylistRepository(
    service: CollaborativePlaylistApiService(authorizedClient),
  );
  final listeningRepository = ListeningRepository(
    service: ListeningApiService(authorizedClient),
  );
  final libraryViewModel = LibraryViewModel(
    repository: libraryRepository,
    playlistRepository: playlistRepository,
  );
  final playerViewModel = PlayerViewModel(
    listeningRepository: listeningRepository,
    playbackRepository: PlaybackRepository(
      service: PlaybackApiService(authorizedClient),
    ),
  );

  runApp(
    SportifyApp(
      homeViewModel: homeViewModel,
      authViewModel: authViewModel,
      searchViewModel: searchViewModel,
      libraryViewModel: libraryViewModel,
      playerViewModel: playerViewModel,
      playlistRepository: playlistRepository,
      collaborativePlaylistRepository: collaborativePlaylistRepository,
      catalogRepository: catalogRepository,
      libraryRepository: libraryRepository,
    ),
  );
}
