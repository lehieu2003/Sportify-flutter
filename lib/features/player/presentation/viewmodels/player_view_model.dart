import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../listening/data/repositories/listening_repository.dart';

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
    required this.currentTrack,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    this.errorMessage,
  });

  const PlayerUiState.initial()
    : currentTrack = null,
      isPlaying = false,
      isBuffering = false,
      position = Duration.zero,
      duration = Duration.zero,
      errorMessage = null;

  final PlayerTrack? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  PlayerUiState copyWith({
    PlayerTrack? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearTrack = false,
  }) {
    return PlayerUiState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
    );
  }
}

class PlayerViewModel extends ChangeNotifier {
  PlayerViewModel({
    required ListeningRepository listeningRepository,
  }) : _listeningRepository = listeningRepository {
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
      }
    });
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      _state = _state.copyWith(duration: duration ?? Duration.zero);
      notifyListeners();
    });
  }

  final ListeningRepository _listeningRepository;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration?> _durationSub;

  PlayerUiState _state = const PlayerUiState.initial();
  bool _completedSent = false;

  PlayerUiState get state => _state;

  Future<void> playTrack(PlayerTrack track) async {
    if (track.audioUrl.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'Track has no audio url.');
      notifyListeners();
      return;
    }

    _completedSent = false;
    try {
      if (_state.currentTrack?.id != track.id) {
        await _audioPlayer.setUrl(track.audioUrl);
      }
      _state = _state.copyWith(
        currentTrack: track,
        errorMessage: null,
      );
      notifyListeners();

      await _audioPlayer.play();
      await _safeSendPlay();
    } catch (_) {
      _state = _state.copyWith(errorMessage: 'Cannot play this track.');
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_state.currentTrack == null) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        await _safeSendPause();
      } else {
        await _audioPlayer.play();
        await _safeSendPlay();
      }
    } catch (_) {
      _state = _state.copyWith(errorMessage: 'Playback action failed.');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _state = _state.copyWith(
        clearTrack: true,
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
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

  @override
  void dispose() {
    _positionSub.cancel();
    _playerStateSub.cancel();
    _durationSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
