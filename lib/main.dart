import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/data/services/home_api_service.dart';
import 'features/home/presentation/viewmodels/home_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final service = HomeApiService(http.Client());
  final cache = SharedPrefsHomeCacheStore(prefs);
  final repository = HomeRepository(service: service, cacheStore: cache);
  final viewModel = HomeViewModel(repository: repository);

  runApp(SportifyApp(homeViewModel: viewModel));
}
