import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../viewmodels/player_view_model.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

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
        final positionMs = state.position.inMilliseconds.clamp(
          0,
          durationMs > 0 ? durationMs : 1,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Now Playing')),
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
                  value: positionMs.toDouble(),
                  max: (durationMs > 0 ? durationMs : 1).toDouble(),
                  onChanged: (value) => vm.seek(Duration(milliseconds: value.toInt())),
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
