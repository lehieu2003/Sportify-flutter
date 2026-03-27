import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../../listening/data/repositories/listening_repository.dart';
import '../../../playback/data/repositories/playback_repository.dart';
import '../services/playback_action_coordinator.dart';

class PlayerTrack {
  const PlayerTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.coverUrl,
  });

  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverUrl;
}

class PlayerUiState {
  const PlayerUiState({
    required this.queue,
    required this.queueIndex,
    required this.currentTrack,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.shuffleEnabled,
    required this.repeatMode,
    required this.isQueueMutating,
    this.errorMessage,
  });

  const PlayerUiState.initial()
    : queue = const <PlayerTrack>[],
      queueIndex = 0,
      currentTrack = null,
      isPlaying = false,
      isBuffering = false,
      position = Duration.zero,
      duration = Duration.zero,
      shuffleEnabled = false,
      repeatMode = 'off',
      isQueueMutating = false,
      errorMessage = null;

  final List<PlayerTrack> queue;
  final int queueIndex;
  final PlayerTrack? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final bool shuffleEnabled;
  final String repeatMode;
  final bool isQueueMutating;
  final String? errorMessage;

  PlayerUiState copyWith({
    PlayerTrack? currentTrack,
    List<PlayerTrack>? queue,
    int? queueIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    bool? shuffleEnabled,
    String? repeatMode,
    bool? isQueueMutating,
    String? errorMessage,
    bool clearTrack = false,
  }) {
    return PlayerUiState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      isQueueMutating: isQueueMutating ?? this.isQueueMutating,
      errorMessage: errorMessage,
    );
  }
}

class _QueueMutationSnapshot {
  const _QueueMutationSnapshot({
    required this.queue,
    required this.queueIndex,
    required this.currentTrack,
    required this.isPlaying,
    required this.position,
  });

  final List<PlayerTrack> queue;
  final int queueIndex;
  final PlayerTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
}

class PlayerViewModel extends ChangeNotifier {
  PlayerViewModel({
    required ListeningRepository listeningRepository,
    required PlaybackRepository playbackRepository,
  }) : _listeningRepository = listeningRepository,
       _playbackRepository = playbackRepository {
    _positionSub = _audioPlayer.positionStream.listen((position) {
      _state = _state.copyWith(position: position, errorMessage: null);
      notifyListeners();
    });
    _playerStateSub = _audioPlayer.playerStateStream.listen((
      playerState,
    ) async {
      final processingState = playerState.processingState;
      _state = _state.copyWith(
        isPlaying: playerState.playing,
        isBuffering:
            processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering,
        duration: _audioPlayer.duration ?? _state.duration,
      );
      notifyListeners();

      if (processingState == ProcessingState.completed &&
          _state.currentTrack != null &&
          !_completedSent) {
        _completedSent = true;
        await _sendComplete();
        await nextTrack(autoPlay: true);
      }
    });
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      _state = _state.copyWith(duration: duration ?? Duration.zero);
      notifyListeners();
    });
  }

  final ListeningRepository _listeningRepository;
  final PlaybackRepository _playbackRepository;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration?> _durationSub;

  PlayerUiState _state = const PlayerUiState.initial();
  bool _completedSent = false;
  Future<void>? _restoreFuture;
  bool _hasRestoredPlayback = false;
  Timer? _seekSyncDebounce;
  final Random _random = Random();
  final PlaybackActionCoordinator _playbackActionCoordinator =
      PlaybackActionCoordinator();

  PlayerUiState get state => _state;

  Future<void> restoreSession() async {
    if (_hasRestoredPlayback) {
      await _waitForRestore();
      return;
    }
    _restoreFuture ??= _restoreSessionInternal();
    await _restoreFuture;
  }

  Future<void> _restoreSessionInternal() async {
    try {
      final responses = await Future.wait<dynamic>(<Future<dynamic>>[
        _playbackRepository.getQueue(),
        _playbackRepository.getState(),
      ]);
      final queuePayload = responses[0] as Map<String, dynamic>;
      final statePayload = responses[1] as Map<String, dynamic>;
      final rawItems =
          (queuePayload['items'] as List<dynamic>? ?? const <dynamic>[]);
      final playableItems = <({int originalIndex, PlayerTrack track})>[];
      var originalIndex = 0;
      for (final entry in rawItems.whereType<Map<String, dynamic>>()) {
        final mappedTrack = _mapQueueItem(entry);
        if (mappedTrack != null) {
          playableItems.add((originalIndex: originalIndex, track: mappedTrack));
        }
        originalIndex += 1;
      }
      final queue = playableItems
          .map((entry) => entry.track)
          .toList(growable: false);

      if (queue.isEmpty) {
        await _audioPlayer.stop();
        _state = const PlayerUiState.initial();
        notifyListeners();
        return;
      }

      final requestedIndex =
          _toInt(statePayload['queueIndex'] ?? queuePayload['currentIndex']) ??
          0;
      final safeIndex = _resolveNearestPlayableIndex(
        playableItems: playableItems,
        requestedIndex: requestedIndex,
      );
      final positionMs = _toInt(statePayload['positionMs']) ?? 0;
      final shuffleEnabled = statePayload['shuffleEnabled'] == true;
      final repeatMode = _parseRepeatMode(statePayload['repeatMode']);

      final sources = queue
          .map((track) => AudioSource.uri(Uri.parse(track.audioUrl)))
          .toList(growable: false);
      await _audioPlayer.setAudioSources(sources, initialIndex: safeIndex);
      if (positionMs > 0) {
        await _audioPlayer.seek(
          Duration(milliseconds: positionMs),
          index: safeIndex,
        );
      }

      _state = _state.copyWith(
        queue: queue,
        queueIndex: safeIndex,
        currentTrack: queue[safeIndex],
        isPlaying: false,
        isBuffering: false,
        position: Duration(milliseconds: positionMs),
        shuffleEnabled: shuffleEnabled,
        repeatMode: repeatMode,
        errorMessage: null,
      );
      notifyListeners();
    } catch (error) {
      debugPrint('restoreSession failed: $error');
      _state = _state.copyWith(
        errorMessage: 'Failed to restore playback session.',
      );
      notifyListeners();
    } finally {
      _hasRestoredPlayback = true;
      _restoreFuture = null;
    }
  }

  Future<void> playTrack(PlayerTrack track) async {
    await playQueue(<PlayerTrack>[track], startIndex: 0);
  }

  Future<void> playQueue(
    List<PlayerTrack> queue, {
    required int startIndex,
  }) async {
    await _waitForRestore();
    if (queue.isEmpty) return;
    final safeIndex = startIndex.clamp(0, queue.length - 1);
    final track = queue[safeIndex];
    if (track.audioUrl.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'Track has no audio url.');
      notifyListeners();
      return;
    }

    _completedSent = false;
    try {
      final sources = queue
          .map((item) => AudioSource.uri(Uri.parse(item.audioUrl)))
          .toList(growable: false);
      await _audioPlayer.setAudioSources(sources, initialIndex: safeIndex);
      _state = _state.copyWith(
        queue: queue,
        queueIndex: safeIndex,
        currentTrack: track,
        position: Duration.zero,
        errorMessage: null,
      );
      notifyListeners();

      await _audioPlayer.play();
      await _playbackRepository.setQueue(
        trackIds: queue.map((item) => item.id).toList(growable: false),
        currentIndex: safeIndex,
      );
      await _playbackRepository.updateState(
        currentTrackId: track.id,
        queueIndex: safeIndex,
        isPlaying: true,
        positionMs: 0,
        shuffleEnabled: _state.shuffleEnabled,
        repeatMode: _state.repeatMode,
      );
      await _safeSendPlay();
    } catch (error) {
      debugPrint('playQueue failed: $error');
      _state = _state.copyWith(errorMessage: 'Cannot play this track: $error');
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    await _waitForRestore();
    if (_state.currentTrack == null) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        await _playbackRepository.updateState(
          isPlaying: false,
          positionMs: _audioPlayer.position.inMilliseconds,
          shuffleEnabled: _state.shuffleEnabled,
          repeatMode: _state.repeatMode,
        );
        await _safeSendPause();
      } else {
        await _audioPlayer.play();
        await _playbackRepository.updateState(
          isPlaying: true,
          positionMs: _audioPlayer.position.inMilliseconds,
          shuffleEnabled: _state.shuffleEnabled,
          repeatMode: _state.repeatMode,
        );
        await _safeSendPlay();
      }
    } catch (error) {
      debugPrint('togglePlayPause failed: $error');
      _state = _state.copyWith(errorMessage: 'Playback action failed: $error');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _waitForRestore();
    try {
      await _audioPlayer.stop();
      _state = _state.copyWith(
        clearTrack: true,
        queue: const <PlayerTrack>[],
        queueIndex: 0,
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
      );
      notifyListeners();
      await _playbackRepository.updateState(
        currentTrackId: null,
        queueIndex: 0,
        isPlaying: false,
        positionMs: 0,
        shuffleEnabled: _state.shuffleEnabled,
        repeatMode: _state.repeatMode,
      );
    } catch (_) {}
  }

  Future<void> clearLocalState() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    _state = const PlayerUiState.initial();
    _hasRestoredPlayback = false;
    _restoreFuture = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _waitForRestore();
    await _audioPlayer.seek(position);
    _scheduleSeekSync(position.inMilliseconds);
  }

  Future<void> nextTrack({bool autoPlay = true}) async {
    await _waitForRestore();
    if (_state.queue.isEmpty) return;
    final targetIndex = _resolveNextIndex();
    if (targetIndex == _state.queueIndex && _state.repeatMode != 'one') return;
    final track = _state.queue[targetIndex];
    try {
      await _audioPlayer.seek(Duration.zero, index: targetIndex);
      if (autoPlay) {
        await _audioPlayer.play();
      }
      _state = _state.copyWith(
        queueIndex: targetIndex,
        currentTrack: track,
        position: Duration.zero,
        isPlaying: autoPlay,
      );
      notifyListeners();
      await _playbackRepository.next();
      await _playbackRepository.updateState(
        currentTrackId: track.id,
        queueIndex: targetIndex,
        isPlaying: autoPlay,
        positionMs: 0,
        shuffleEnabled: _state.shuffleEnabled,
        repeatMode: _state.repeatMode,
      );
      if (autoPlay) {
        await _listeningRepository.skip(track.id, progressMs: 0);
      }
    } catch (_) {}
  }

  Future<void> previousTrack({bool autoPlay = true}) async {
    await _waitForRestore();
    if (_state.queue.isEmpty) return;
    final targetIndex = _resolvePreviousIndex();
    if (targetIndex == _state.queueIndex && _state.repeatMode != 'one') {
      await seek(Duration.zero);
      return;
    }
    final track = _state.queue[targetIndex];
    try {
      await _audioPlayer.seek(Duration.zero, index: targetIndex);
      if (autoPlay) {
        await _audioPlayer.play();
      }
      _state = _state.copyWith(
        queueIndex: targetIndex,
        currentTrack: track,
        position: Duration.zero,
        isPlaying: autoPlay,
      );
      notifyListeners();
      await _playbackRepository.previous();
      await _playbackRepository.updateState(
        currentTrackId: track.id,
        queueIndex: targetIndex,
        isPlaying: autoPlay,
        positionMs: 0,
        shuffleEnabled: _state.shuffleEnabled,
        repeatMode: _state.repeatMode,
      );
      if (autoPlay) {
        await _listeningRepository.skip(track.id, progressMs: 0);
      }
    } catch (_) {}
  }

  Future<void> jumpToQueueIndex(int index, {bool autoPlay = true}) async {
    await _waitForRestore();
    if (_state.queue.isEmpty) return;
    await _runQueueMutation('select', () async {
      final snapshot = _createQueueSnapshot();
      final safeIndex = index.clamp(0, _state.queue.length - 1);
      final track = _state.queue[safeIndex];
      try {
        await _audioPlayer.seek(Duration.zero, index: safeIndex);
        if (autoPlay) {
          await _audioPlayer.play();
        } else {
          await _audioPlayer.pause();
        }
        _state = _state.copyWith(
          queueIndex: safeIndex,
          currentTrack: track,
          position: Duration.zero,
          isPlaying: autoPlay,
          errorMessage: null,
        );
        notifyListeners();
        await _withSingleRetry(
          () => _playbackRepository.selectQueueIndex(index: safeIndex),
        );
        if (!autoPlay) {
          await _withSingleRetry(
            () => _playbackRepository.updateState(
              currentTrackId: track.id,
              queueIndex: safeIndex,
              isPlaying: false,
              positionMs: 0,
              shuffleEnabled: _state.shuffleEnabled,
              repeatMode: _state.repeatMode,
            ),
          );
        }
      } catch (error) {
        debugPrint('jumpToQueueIndex failed: $error');
        await _restoreQueueSnapshot(
          snapshot,
          errorMessage: 'Failed to select queue track.',
        );
      }
    });
  }

  Future<void> removeFromQueueAt(int index) async {
    await _waitForRestore();
    final queue = _state.queue;
    if (queue.length <= 1) {
      _state = _state.copyWith(
        errorMessage: 'Cannot remove the last track in queue.',
      );
      notifyListeners();
      return;
    }
    if (index < 0 || index >= queue.length) return;
    await _runQueueMutation('remove', () async {
      final snapshot = _createQueueSnapshot();
      final removedTrackId = queue[index].id;

      final updatedQueue = List<PlayerTrack>.from(queue)..removeAt(index);
      final wasPlaying = _state.isPlaying;
      var nextIndex = _state.queueIndex;
      if (index < nextIndex) {
        nextIndex -= 1;
      } else if (index == nextIndex) {
        nextIndex = nextIndex.clamp(0, updatedQueue.length - 1);
      }
      nextIndex = nextIndex.clamp(0, updatedQueue.length - 1);

      try {
        final sources = updatedQueue
            .map((item) => AudioSource.uri(Uri.parse(item.audioUrl)))
            .toList(growable: false);
        await _audioPlayer.setAudioSources(sources, initialIndex: nextIndex);
        await _audioPlayer.seek(Duration.zero, index: nextIndex);
        if (wasPlaying) {
          await _audioPlayer.play();
        } else {
          await _audioPlayer.pause();
        }

        final currentTrack = updatedQueue[nextIndex];
        _state = _state.copyWith(
          queue: updatedQueue,
          queueIndex: nextIndex,
          currentTrack: currentTrack,
          position: Duration.zero,
          isPlaying: wasPlaying,
          errorMessage: null,
        );
        notifyListeners();

        final payload = await _withSingleRetry(
          () => _playbackRepository.removeFromQueue(trackId: removedTrackId),
        );
        if (!_isQueuePayloadAligned(
          payload,
          expectedLength: updatedQueue.length,
          expectedIndex: nextIndex,
          expectedTrackIds: updatedQueue
              .map((item) => item.id)
              .toList(growable: false),
        )) {
          await _syncQueueFallback(
            queue: updatedQueue,
            currentIndex: nextIndex,
            isPlaying: wasPlaying,
          );
        }
      } catch (error) {
        debugPrint('removeFromQueueAt failed: $error');
        await _restoreQueueSnapshot(
          snapshot,
          errorMessage: 'Failed to remove queue track.',
        );
      }
    });
  }

  Future<void> reorderQueue({
    required int fromIndex,
    required int toIndex,
  }) async {
    await _waitForRestore();
    final queue = _state.queue;
    if (queue.length <= 1) return;
    if (fromIndex < 0 ||
        fromIndex >= queue.length ||
        toIndex < 0 ||
        toIndex >= queue.length) {
      return;
    }
    if (fromIndex == toIndex) return;
    await _runQueueMutation('reorder', () async {
      final snapshot = _createQueueSnapshot();

      final updatedQueue = List<PlayerTrack>.from(queue);
      final moved = updatedQueue.removeAt(fromIndex);
      updatedQueue.insert(toIndex, moved);

      var nextIndex = _state.queueIndex;
      if (nextIndex == fromIndex) {
        nextIndex = toIndex;
      } else if (fromIndex < nextIndex && toIndex >= nextIndex) {
        nextIndex -= 1;
      } else if (fromIndex > nextIndex && toIndex <= nextIndex) {
        nextIndex += 1;
      }
      nextIndex = nextIndex.clamp(0, updatedQueue.length - 1);

      try {
        final wasPlaying = _state.isPlaying;
        final sources = updatedQueue
            .map((item) => AudioSource.uri(Uri.parse(item.audioUrl)))
            .toList(growable: false);
        await _audioPlayer.setAudioSources(sources, initialIndex: nextIndex);
        if (wasPlaying) {
          await _audioPlayer.play();
        } else {
          await _audioPlayer.pause();
        }
        final currentTrack = updatedQueue[nextIndex];
        _state = _state.copyWith(
          queue: updatedQueue,
          queueIndex: nextIndex,
          currentTrack: currentTrack,
          position: Duration.zero,
          isPlaying: wasPlaying,
          errorMessage: null,
        );
        notifyListeners();
        final payload = await _withSingleRetry(
          () => _playbackRepository.reorderQueue(
            fromIndex: fromIndex,
            toIndex: toIndex,
          ),
        );
        if (!_isQueuePayloadAligned(
          payload,
          expectedLength: updatedQueue.length,
          expectedIndex: nextIndex,
          expectedTrackIds: updatedQueue
              .map((item) => item.id)
              .toList(growable: false),
        )) {
          await _syncQueueFallback(
            queue: updatedQueue,
            currentIndex: nextIndex,
            isPlaying: wasPlaying,
          );
        }
      } catch (error) {
        debugPrint('reorderQueue failed: $error');
        await _restoreQueueSnapshot(
          snapshot,
          errorMessage: 'Failed to reorder queue.',
        );
      }
    });
  }

  Future<void> addToQueue(PlayerTrack track) async {
    await _waitForRestore();
    if (track.audioUrl.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'Track has no audio url.');
      notifyListeners();
      return;
    }

    if (_state.queue.isEmpty) {
      await playQueue(<PlayerTrack>[track], startIndex: 0);
      return;
    }

    await _runQueueMutation('add', () async {
      final snapshot = _createQueueSnapshot();
      final updatedQueue = <PlayerTrack>[...snapshot.queue, track];
      final currentIndex = snapshot.queueIndex.clamp(
        0,
        updatedQueue.length - 1,
      );

      try {
        final sources = updatedQueue
            .map((item) => AudioSource.uri(Uri.parse(item.audioUrl)))
            .toList(growable: false);
        await _audioPlayer.setAudioSources(sources, initialIndex: currentIndex);
        await _audioPlayer.seek(snapshot.position, index: currentIndex);
        if (snapshot.isPlaying) {
          await _audioPlayer.play();
        } else {
          await _audioPlayer.pause();
        }

        _state = _state.copyWith(
          queue: updatedQueue,
          queueIndex: currentIndex,
          currentTrack: updatedQueue[currentIndex],
          isPlaying: snapshot.isPlaying,
          position: snapshot.position,
          errorMessage: null,
        );
        notifyListeners();

        await _withSingleRetry(
          () => _playbackRepository.setQueue(
            trackIds: updatedQueue
                .map((item) => item.id)
                .toList(growable: false),
            currentIndex: currentIndex,
          ),
        );

        final currentTrack = _state.currentTrack;
        if (currentTrack != null) {
          await _withSingleRetry(
            () => _playbackRepository.updateState(
              currentTrackId: currentTrack.id,
              queueIndex: currentIndex,
              isPlaying: _state.isPlaying,
              positionMs: _audioPlayer.position.inMilliseconds,
              shuffleEnabled: _state.shuffleEnabled,
              repeatMode: _state.repeatMode,
            ),
          );
        }
      } catch (error) {
        debugPrint('addToQueue failed: $error');
        await _restoreQueueSnapshot(
          snapshot,
          errorMessage: 'Failed to add track to queue.',
        );
      }
    });
  }

  Future<void> toggleShuffle() async {
    final next = !_state.shuffleEnabled;
    _state = _state.copyWith(shuffleEnabled: next, errorMessage: null);
    notifyListeners();
    try {
      await _playbackRepository.updateState(
        shuffleEnabled: next,
        repeatMode: _state.repeatMode,
      );
    } catch (_) {}
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (_state.repeatMode) {
      'off' => 'all',
      'all' => 'one',
      _ => 'off',
    };
    _state = _state.copyWith(repeatMode: next, errorMessage: null);
    notifyListeners();
    try {
      await _playbackRepository.updateState(
        shuffleEnabled: _state.shuffleEnabled,
        repeatMode: next,
      );
    } catch (_) {}
  }

  Future<void> _waitForRestore() async {
    final inFlight = _restoreFuture;
    if (inFlight != null) {
      await inFlight;
    }
  }

  Future<void> _runQueueMutation(
    String actionKey,
    Future<void> Function() action,
  ) async {
    final started = _playbackActionCoordinator.tryStart(actionKey);
    if (!started) return;
    _state = _state.copyWith(isQueueMutating: true);
    notifyListeners();
    try {
      await action();
    } finally {
      _playbackActionCoordinator.finish(actionKey);
      _state = _state.copyWith(
        isQueueMutating: _playbackActionCoordinator.hasInFlightActions,
      );
      notifyListeners();
    }
  }

  PlayerTrack? _mapQueueItem(Map<String, dynamic> item) {
    final audioUrl = ApiConfig.resolveUrl(item['audioUrl']?.toString());
    final track = PlayerTrack(
      id: (item['trackId'] ?? '').toString(),
      title: (item['title'] ?? 'Untitled track').toString(),
      artist: (item['artist'] ?? 'Unknown artist').toString(),
      audioUrl: audioUrl,
      coverUrl: ApiConfig.resolveUrl(item['coverUrl']?.toString()),
    );
    if (track.id.isEmpty || track.audioUrl.isEmpty) {
      return null;
    }
    return track;
  }

  int _resolveNearestPlayableIndex({
    required List<({int originalIndex, PlayerTrack track})> playableItems,
    required int requestedIndex,
  }) {
    var bestIndex = 0;
    var bestDistance = 1 << 30;
    for (var i = 0; i < playableItems.length; i += 1) {
      final distance = (playableItems[i].originalIndex - requestedIndex).abs();
      if (distance < bestDistance) {
        bestIndex = i;
        bestDistance = distance;
      }
    }
    return bestIndex;
  }

  _QueueMutationSnapshot _createQueueSnapshot() {
    return _QueueMutationSnapshot(
      queue: List<PlayerTrack>.from(_state.queue),
      queueIndex: _state.queueIndex,
      currentTrack: _state.currentTrack,
      isPlaying: _state.isPlaying,
      position: _state.position,
    );
  }

  Future<void> _restoreQueueSnapshot(
    _QueueMutationSnapshot snapshot, {
    required String errorMessage,
  }) async {
    try {
      if (snapshot.queue.isEmpty) {
        await _audioPlayer.stop();
      } else {
        final sources = snapshot.queue
            .map((item) => AudioSource.uri(Uri.parse(item.audioUrl)))
            .toList(growable: false);
        await _audioPlayer.setAudioSources(
          sources,
          initialIndex: snapshot.queueIndex,
        );
        await _audioPlayer.seek(snapshot.position, index: snapshot.queueIndex);
        if (snapshot.isPlaying) {
          await _audioPlayer.play();
        } else {
          await _audioPlayer.pause();
        }
      }
    } catch (_) {}
    _state = _state.copyWith(
      queue: snapshot.queue,
      queueIndex: snapshot.queueIndex,
      currentTrack: snapshot.currentTrack,
      isPlaying: snapshot.isPlaying,
      position: snapshot.position,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  Future<T> _withSingleRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      if (error is ApiException && error.statusCode < 500) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return action();
    }
  }

  bool _isQueuePayloadAligned(
    Map<String, dynamic> payload, {
    required int expectedLength,
    required int expectedIndex,
    required List<String> expectedTrackIds,
  }) {
    final items = payload['items'];
    final responseLength = items is List ? items.length : -1;
    final responseIndex = _toInt(payload['currentIndex']) ?? -1;
    if (responseLength != expectedLength || responseIndex != expectedIndex) {
      return false;
    }
    final responseTrackIds = items is List
        ? items
              .whereType<Map<String, dynamic>>()
              .map((item) => (item['trackId'] ?? '').toString())
              .toList(growable: false)
        : const <String>[];
    if (responseTrackIds.length != expectedTrackIds.length) {
      return false;
    }
    for (var i = 0; i < expectedTrackIds.length; i += 1) {
      if (responseTrackIds[i] != expectedTrackIds[i]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _syncQueueFallback({
    required List<PlayerTrack> queue,
    required int currentIndex,
    required bool isPlaying,
  }) async {
    final safeIndex = currentIndex.clamp(0, queue.length - 1);
    final currentTrack = queue[safeIndex];
    await _playbackRepository.setQueue(
      trackIds: queue.map((item) => item.id).toList(growable: false),
      currentIndex: safeIndex,
    );
    await _playbackRepository.updateState(
      currentTrackId: currentTrack.id,
      queueIndex: safeIndex,
      isPlaying: isPlaying,
      positionMs: 0,
      shuffleEnabled: _state.shuffleEnabled,
      repeatMode: _state.repeatMode,
    );
  }

  Future<void> _safeSendPlay() async {
    final track = _state.currentTrack;
    if (track == null) return;
    try {
      await _listeningRepository.play(
        track.id,
        progressMs: _audioPlayer.position.inMilliseconds,
      );
    } catch (_) {}
  }

  Future<void> _safeSendPause() async {
    final track = _state.currentTrack;
    if (track == null) return;
    try {
      await _listeningRepository.pause(
        track.id,
        progressMs: _audioPlayer.position.inMilliseconds,
      );
    } catch (_) {}
  }

  Future<void> _sendComplete() async {
    final track = _state.currentTrack;
    if (track == null) return;
    try {
      await _listeningRepository.complete(
        track.id,
        progressMs: _audioPlayer.position.inMilliseconds,
      );
    } catch (_) {}
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _parseRepeatMode(dynamic value) {
    if (value is String &&
        (value == 'off' || value == 'all' || value == 'one')) {
      return value;
    }
    return 'off';
  }

  void _scheduleSeekSync(int positionMs) {
    _seekSyncDebounce?.cancel();
    _seekSyncDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        await _playbackRepository.updateState(
          positionMs: positionMs,
          shuffleEnabled: _state.shuffleEnabled,
          repeatMode: _state.repeatMode,
        );
      } catch (_) {}
    });
  }

  int _resolveNextIndex() {
    final length = _state.queue.length;
    if (length <= 1) return 0;
    final current = _state.queueIndex;
    if (_state.repeatMode == 'one') return current;
    if (_state.shuffleEnabled) {
      final randomIndex = _random.nextInt(length);
      return randomIndex == current ? (current + 1) % length : randomIndex;
    }
    final candidate = current + 1;
    if (candidate < length) return candidate;
    return _state.repeatMode == 'all' ? 0 : current;
  }

  int _resolvePreviousIndex() {
    final length = _state.queue.length;
    if (length <= 1) return 0;
    final current = _state.queueIndex;
    if (_state.repeatMode == 'one') return current;
    if (_state.shuffleEnabled) {
      final randomIndex = _random.nextInt(length);
      return randomIndex == current
          ? (current - 1 + length) % length
          : randomIndex;
    }
    final candidate = current - 1;
    if (candidate >= 0) return candidate;
    return _state.repeatMode == 'all' ? length - 1 : current;
  }

  @override
  void dispose() {
    _seekSyncDebounce?.cancel();
    _positionSub.cancel();
    _playerStateSub.cancel();
    _durationSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
