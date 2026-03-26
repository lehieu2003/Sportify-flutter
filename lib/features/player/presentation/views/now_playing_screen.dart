import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../viewmodels/player_view_model.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _dragValueMs;

  Future<void> _openQueueSheet(PlayerViewModel vm) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Consumer<PlayerViewModel>(
            builder: (context, queueVm, _) {
              final state = queueVm.state;
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: SportifySpacing.md),
                    const Text(
                      'Up Next',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: SportifySpacing.sm),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.queue.length,
                        itemBuilder: (context, index) {
                          final item = state.queue[index];
                          final isCurrent = index == state.queueIndex;
                          return ListTile(
                            onTap: () => queueVm.jumpToQueueIndex(index),
                            leading: Icon(
                              isCurrent ? Icons.graphic_eq : Icons.music_note,
                              color: isCurrent
                                  ? SportifyColors.primary
                                  : SportifyColors.textSecondary,
                            ),
                            title: Text(item.title),
                            subtitle: Text(item.artist),
                            trailing: IconButton(
                              onPressed: state.queue.length <= 1
                                  ? null
                                  : () => queueVm.removeFromQueueAt(index),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        final track = state.currentTrack;
        if (track == null) {
          return const Scaffold(
            body: Center(child: Text('No track is playing')),
          );
        }

        final durationMs = state.duration.inMilliseconds;
        final streamPositionMs = state.position.inMilliseconds.clamp(
          0,
          durationMs > 0 ? durationMs : 1,
        );
        final positionMs = (_dragValueMs ?? streamPositionMs.toDouble()).clamp(
          0,
          (durationMs > 0 ? durationMs : 1).toDouble(),
        ).toDouble();
        final isShuffleActive = state.shuffleEnabled;
        final repeatMode = state.repeatMode;
        final repeatIcon = switch (repeatMode) {
          'all' => Icons.repeat,
          'one' => Icons.repeat_one,
          _ => Icons.repeat,
        };
        final repeatColor = repeatMode == 'off'
            ? SportifyColors.textSecondary
            : SportifyColors.primary;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
            actions: <Widget>[
              IconButton(
                onPressed: () => _openQueueSheet(vm),
                icon: const Icon(Icons.queue_music),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: SportifyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.album, size: 120),
                  ),
                ),
                const SizedBox(height: SportifySpacing.lg),
                Text(
                  track.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: SportifySpacing.xs),
                Text(
                  track.artist,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: SportifySpacing.md),
                Slider(
                  value: positionMs,
                  max: (durationMs > 0 ? durationMs : 1).toDouble(),
                  onChanged: (value) => setState(() => _dragValueMs = value),
                  onChangeEnd: (value) async {
                    setState(() => _dragValueMs = null);
                    await vm.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_formatDuration(state.position)),
                    Text(_formatDuration(state.duration)),
                  ],
                ),
                const SizedBox(height: SportifySpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      onPressed: vm.toggleShuffle,
                      iconSize: 28,
                      color: isShuffleActive
                          ? SportifyColors.primary
                          : SportifyColors.textSecondary,
                      icon: const Icon(Icons.shuffle),
                    ),
                    IconButton(
                      onPressed: vm.previousTrack,
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: vm.togglePlayPause,
                      iconSize: 56,
                      icon: Icon(
                        state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: vm.nextTrack,
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next),
                    ),
                    IconButton(
                      onPressed: vm.cycleRepeatMode,
                      iconSize: 28,
                      color: repeatColor,
                      icon: Icon(repeatIcon),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
