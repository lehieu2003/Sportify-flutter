import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/config/api_config.dart';
import '../../../listening/data/repositories/listening_repository.dart';
import '../../../playback/data/repositories/playback_repository.dart';

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
      errorMessage: errorMessage,
    );
  }
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
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) async {
      final processingState = playerState.processingState;
      _state = _state.copyWith(
        isPlaying: playerState.playing,
        isBuffering: processingState == ProcessingState.loading ||
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
  bool _isRestoring = false;
  Timer? _seekSyncDebounce;
  final Random _random = Random();

  PlayerUiState get state => _state;

  Future<void> restoreSession() async {
    if (_isRestoring) return;
    _isRestoring = true;
    try {
      final responses = await Future.wait<dynamic>(<Future<dynamic>>[
        _playbackRepository.getQueue(),
        _playbackRepository.getState(),
      ]);
      final queuePayload = responses[0] as Map<String, dynamic>;
      final statePayload = responses[1] as Map<String, dynamic>;
      final rawItems = (queuePayload['items'] as List<dynamic>? ?? const <dynamic>[]);

      final queue = rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final audioUrl = ApiConfig.resolveUrl(item['audioUrl']?.toString());
            return PlayerTrack(
              id: (item['trackId'] ?? '').toString(),
              title: (item['title'] ?? 'Untitled track').toString(),
              artist: (item['artist'] ?? 'Unknown artist').toString(),
              audioUrl: audioUrl,
              coverUrl: ApiConfig.resolveUrl(item['coverUrl']?.toString()),
            );
          })
          .where((track) => track.id.isNotEmpty && track.audioUrl.isNotEmpty)
          .toList(growable: false);

      if (queue.isEmpty) {
        await _audioPlayer.stop();
        _state = const PlayerUiState.initial();
        notifyListeners();
        return;
      }

      final queueIndex = _toInt(statePayload['queueIndex'] ?? queuePayload['currentIndex']) ?? 0;
      final safeIndex = queueIndex.clamp(0, queue.length - 1);
      final positionMs = _toInt(statePayload['positionMs']) ?? 0;
      final shuffleEnabled = statePayload['shuffleEnabled'] == true;
      final repeatMode = _parseRepeatMode(statePayload['repeatMode']);

      final sources = queue
          .map((track) => AudioSource.uri(Uri.parse(track.audioUrl)))
          .toList(growable: false);
      await _audioPlayer.setAudioSources(sources, initialIndex: safeIndex);
      if (positionMs > 0) {
        await _audioPlayer.seek(Duration(milliseconds: positionMs), index: safeIndex);
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
      _state = _state.copyWith(errorMessage: 'Failed to restore playback session.');
      notifyListeners();
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> playTrack(PlayerTrack track) async {
    await playQueue(<PlayerTrack>[track], startIndex: 0);
  }

  Future<void> playQueue(List<PlayerTrack> queue, {required int startIndex}) async {
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
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    _scheduleSeekSync(position.inMilliseconds);
  }

  Future<void> nextTrack({bool autoPlay = true}) async {
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
    if (value is String && (value == 'off' || value == 'all' || value == 'one')) {
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
      return randomIndex == current ? (current - 1 + length) % length : randomIndex;
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
