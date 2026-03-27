import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/jam_models.dart';
import '../../data/repositories/jam_repository.dart';

enum JamPollingStatus { stopped, running, paused, error }

class JamUiState {
  const JamUiState({
    required this.session,
    required this.isLoading,
    required this.isSubmitting,
    required this.isSyncingQueue,
    required this.pollingStatus,
    required this.consecutiveErrors,
    this.errorMessage,
  });

  const JamUiState.initial()
    : session = null,
      isLoading = false,
      isSubmitting = false,
      isSyncingQueue = false,
      pollingStatus = JamPollingStatus.stopped,
      consecutiveErrors = 0,
      errorMessage = null;

  final JamSession? session;
  final bool isLoading;
  final bool isSubmitting;
  final bool isSyncingQueue;
  final JamPollingStatus pollingStatus;
  final int consecutiveErrors;
  final String? errorMessage;

  bool get hasActiveSession => session?.isActive == true;
  bool get isHost => session?.isHost == true;

  JamUiState copyWith({
    JamSession? session,
    bool clearSession = false,
    bool? isLoading,
    bool? isSubmitting,
    bool? isSyncingQueue,
    JamPollingStatus? pollingStatus,
    int? consecutiveErrors,
    String? errorMessage,
  }) {
    return JamUiState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSyncingQueue: isSyncingQueue ?? this.isSyncingQueue,
      pollingStatus: pollingStatus ?? this.pollingStatus,
      consecutiveErrors: consecutiveErrors ?? this.consecutiveErrors,
      errorMessage: errorMessage,
    );
  }
}

class JamViewModel extends ChangeNotifier {
  JamViewModel({required JamRepository repository}) : _repository = repository;

  static const Duration _pollingInterval = Duration(seconds: 7);
  static const int _maxConsecutiveErrors = 5;

  final JamRepository _repository;
  JamUiState _state = const JamUiState.initial();
  Timer? _pollTimer;
  String? _pollingSessionId;
  bool _isPollingRequestInFlight = false;

  JamUiState get state => _state;

  Future<void> loadActiveSession() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final session = await _repository.getActiveSession();
      _state = _state.copyWith(
        session: session,
        isLoading: false,
        pollingStatus: JamPollingStatus.stopped,
        consecutiveErrors: 0,
      );
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(error),
      );
    }
    notifyListeners();
  }

  Future<JamSession?> createSession({String? title}) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();
    try {
      final session = await _repository.createSession(title: title);
      _state = _state.copyWith(
        session: session,
        isSubmitting: false,
        consecutiveErrors: 0,
      );
      notifyListeners();
      return session;
    } catch (error) {
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: _normalizeError(error),
      );
      notifyListeners();
      return null;
    }
  }

  Future<JamSession?> joinByCode(String inviteCode) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();
    try {
      final session = await _repository.joinByCode(inviteCode);
      _state = _state.copyWith(
        session: session,
        isSubmitting: false,
        consecutiveErrors: 0,
      );
      notifyListeners();
      return session;
    } catch (error) {
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: _normalizeError(error),
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> loadSession(String sessionId, {bool silent = false}) async {
    if (!silent) {
      _state = _state.copyWith(isLoading: true, errorMessage: null);
      notifyListeners();
    }
    try {
      final session = await _repository.getSessionById(sessionId);
      _state = _state.copyWith(
        session: session,
        isLoading: false,
        consecutiveErrors: 0,
        pollingStatus: _state.pollingStatus == JamPollingStatus.paused
            ? JamPollingStatus.paused
            : JamPollingStatus.running,
        errorMessage: null,
      );
      if (!session.isActive) {
        stopPolling();
      }
    } catch (error) {
      if (!silent) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: _normalizeError(error),
        );
      }
      if (silent) {
        final nextErrors = _state.consecutiveErrors + 1;
        _state = _state.copyWith(
          consecutiveErrors: nextErrors,
          pollingStatus: nextErrors >= _maxConsecutiveErrors
              ? JamPollingStatus.error
              : JamPollingStatus.running,
          errorMessage: nextErrors >= _maxConsecutiveErrors
              ? 'Connection lost. Tap to retry.'
              : _state.errorMessage,
        );
        if (nextErrors >= _maxConsecutiveErrors) {
          stopPolling(setErrorStatus: true);
        }
      }
    }
    notifyListeners();
  }

  Future<void> syncQueueAsHost({
    required String sessionId,
    required List<String> trackIds,
    required int queueIndex,
    String? currentTrackId,
  }) async {
    if (!_state.isHost) {
      _state = _state.copyWith(
        errorMessage: 'You do not have permission to sync queue.',
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(isSyncingQueue: true, errorMessage: null);
    notifyListeners();
    try {
      final session = await _repository.syncQueue(
        sessionId: sessionId,
        trackIds: trackIds,
        queueIndex: queueIndex,
        currentTrackId: currentTrackId,
      );
      _state = _state.copyWith(session: session, isSyncingQueue: false);
    } catch (error) {
      _state = _state.copyWith(
        isSyncingQueue: false,
        errorMessage: _normalizeError(error),
      );
    }
    notifyListeners();
  }

  Future<void> leaveSession(String sessionId) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();
    try {
      await _repository.leaveSession(sessionId);
      stopPolling();
      _state = _state.copyWith(isSubmitting: false, clearSession: true);
    } catch (error) {
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: _normalizeError(error),
      );
    }
    notifyListeners();
  }

  Future<void> endSession(String sessionId) async {
    _state = _state.copyWith(isSubmitting: true, errorMessage: null);
    notifyListeners();
    try {
      await _repository.endSession(sessionId);
      stopPolling();
      _state = _state.copyWith(isSubmitting: false, clearSession: true);
    } catch (error) {
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: _normalizeError(error),
      );
    }
    notifyListeners();
  }

  void startPolling(String sessionId) {
    _pollingSessionId = sessionId;
    _pollTimer?.cancel();
    _state = _state.copyWith(
      pollingStatus: JamPollingStatus.running,
      consecutiveErrors: 0,
      errorMessage: null,
    );
    notifyListeners();
    _pollTimer = Timer.periodic(_pollingInterval, (_) => _pollTick());
  }

  void stopPolling({bool setErrorStatus = false}) {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPollingRequestInFlight = false;
    _state = _state.copyWith(
      pollingStatus: setErrorStatus
          ? JamPollingStatus.error
          : JamPollingStatus.stopped,
    );
    notifyListeners();
  }

  void pausePolling() {
    if (_pollTimer == null) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _state = _state.copyWith(pollingStatus: JamPollingStatus.paused);
    notifyListeners();
  }

  void resumePollingIfNeeded() {
    final session = _state.session;
    if (session == null || !session.isActive) return;
    _pollingSessionId ??= session.id;
    if (_pollTimer != null) return;
    startPolling(_pollingSessionId!);
  }

  Future<void> retryPollingNow() async {
    final sessionId = _pollingSessionId ?? _state.session?.id;
    if (sessionId == null) return;
    _state = _state.copyWith(
      consecutiveErrors: 0,
      errorMessage: null,
      pollingStatus: JamPollingStatus.running,
    );
    notifyListeners();
    await loadSession(sessionId, silent: true);
    if (_state.session?.isActive == true && _pollTimer == null) {
      startPolling(sessionId);
    }
  }

  Future<void> _pollTick() async {
    final sessionId = _pollingSessionId;
    if (sessionId == null || _isPollingRequestInFlight) return;
    _isPollingRequestInFlight = true;
    try {
      await loadSession(sessionId, silent: true);
    } finally {
      _isPollingRequestInFlight = false;
    }
  }

  String _normalizeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
