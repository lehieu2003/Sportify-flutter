# Sportify Mobile

Flutter mobile app scaffolded to follow local agent skills in `.agents/skills`:
- `flutter-architecting-apps`
- `flutter-managing-state`
- `flutter-handling-http-and-json`
- `flutter-caching-data`
- `flutter-testing-apps`

## Architecture Standard

This project uses a layered approach by feature:

```text
lib/
  app.dart
  main.dart
  features/
    home/
      data/
        models/
        services/
        repositories/
      presentation/
        viewmodels/
        views/
```

Rules currently enforced:
- UI in `views` is lean and state-driven.
- ViewModel (`ChangeNotifier`) handles UI state and user intents.
- Repository is the SSOT for feature data.
- Service is stateless and only wraps remote HTTP.
- Cache store (`SharedPreferences`) is owned by data layer.

## Setup

1. Install Flutter SDK `3.8+`.
2. From project root:

```bash
flutter pub get
flutter run
```

## Quality Gates

Run these before commit:

```bash
flutter analyze
flutter test
flutter test integration_test/app_test.dart
```

## Feature Workflow (Skill-Aligned)

When adding a new feature:
1. Define immutable models in `data/models`.
2. Add stateless API service in `data/services`.
3. Add repository in `data/repositories` (cache + mapping + SSOT).
4. Add ViewModel in `presentation/viewmodels`.
5. Add screen/widgets in `presentation/views`.
6. Add unit + widget + integration tests.
