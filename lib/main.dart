import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/authorized_http_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/data/services/home_api_service.dart';
import 'features/home/presentation/viewmodels/home_view_model.dart';

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
    onUnauthorized: authViewModel.signout,
  );

  final homeService = HomeApiService(authorizedClient);
  final homeCache = SharedPrefsHomeCacheStore(prefs);
  final homeRepository = HomeRepository(
    service: homeService,
    cacheStore: homeCache,
  );
  final homeViewModel = HomeViewModel(repository: homeRepository);

  runApp(
    SportifyApp(homeViewModel: homeViewModel, authViewModel: authViewModel),
  );
}
