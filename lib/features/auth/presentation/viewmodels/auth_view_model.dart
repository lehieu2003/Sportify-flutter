import 'package:flutter/foundation.dart';

import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthUiState {
  const AuthUiState({
    required this.isBootstrapping,
    required this.isAuthenticated,
    required this.isSubmitting,
    this.user,
    this.errorMessage,
  });

  const AuthUiState.initial()
    : isBootstrapping = true,
      isAuthenticated = false,
      isSubmitting = false,
      user = null,
      errorMessage = null;

  final bool isBootstrapping;
  final bool isAuthenticated;
  final bool isSubmitting;
  final AuthUser? user;
  final String? errorMessage;

  AuthUiState copyWith({
    bool? isBootstrapping,
    bool? isAuthenticated,
    bool? isSubmitting,
    AuthUser? user,
    String? errorMessage,
  }) {
    return AuthUiState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;
  AuthUiState _state = const AuthUiState.initial();

  AuthUiState get state => _state;

  Future<void> bootstrap() async {
    _state = _state.copyWith(
      isBootstrapping: true,
      isSubmitting: false,
      errorMessage: null,
    );
    notifyListeners();

    final result = await _repository.bootstrapSession();

    _state = _state.copyWith(
      isBootstrapping: false,
      isAuthenticated: result.isAuthenticated,
      user: result.user,
      errorMessage: null,
    );
    notifyListeners();
  }

  Future<void> signin({required String email, required String password}) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();

    try {
      final session = await _repository.signin(
        email: email,
        password: password,
      );
      _state = _state.copyWith(
        isSubmitting: false,
        isAuthenticated: true,
        user: session.user,
        errorMessage: null,
      );
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        isAuthenticated: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
    notifyListeners();
  }

  Future<void> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();

    try {
      final session = await _repository.signup(
        fullName: fullName,
        email: email,
        password: password,
      );
      _state = _state.copyWith(
        isSubmitting: false,
        isAuthenticated: true,
        user: session.user,
        errorMessage: null,
      );
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        isAuthenticated: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
    notifyListeners();
  }

  Future<void> signout() async {
    await _repository.signoutRemote();
    _state = _state.copyWith(
      isAuthenticated: false,
      user: null,
      errorMessage: null,
      isSubmitting: false,
      isBootstrapping: false,
    );
    notifyListeners();
  }

  Future<void> signoutAll() async {
    await _repository.signoutAllRemote();
    _state = _state.copyWith(
      isAuthenticated: false,
      user: null,
      errorMessage: null,
      isSubmitting: false,
      isBootstrapping: false,
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    String? fullName,
    String? imageUrl,
  }) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();

    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        imageUrl: imageUrl,
      );
      _state = _state.copyWith(
        isSubmitting: false,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
    notifyListeners();
  }

  void clearError() {
    if (_state.errorMessage == null) return;
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}
