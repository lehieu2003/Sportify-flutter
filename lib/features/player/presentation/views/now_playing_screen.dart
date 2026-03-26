import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: state.queue.length,
                        onReorder: (oldIndex, newIndex) {
                          if (state.queue.length <= 1) return;
                          final targetIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
                          HapticFeedback.mediumImpact();
                          queueVm.reorderQueue(fromIndex: oldIndex, toIndex: targetIndex);
                        },
                        itemBuilder: (context, index) {
                          final item = state.queue[index];
                          final isCurrent = index == state.queueIndex;
                          return ListTile(
                            key: ValueKey(item.id),
                            onTap: () => queueVm.jumpToQueueIndex(index),
                            leading: Icon(
                              isCurrent ? Icons.graphic_eq : Icons.music_note,
                              color: isCurrent
                                  ? SportifyColors.primary
                                  : SportifyColors.textSecondary,
                            ),
                            title: Text(item.title),
                            subtitle: Text(item.artist),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  onPressed: state.queue.length <= 1
                                      ? null
                                      : () => queueVm.removeFromQueueAt(index),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                if (state.queue.length > 1)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
                              ],
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

  Future<void> _showShareSheet(PlayerTrack track) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SportifySpacing.md,
            SportifySpacing.md,
            SportifySpacing.md,
            SportifySpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: SportifyColors.textDisabled,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: SportifySpacing.md),
              Container(
                width: 220,
                padding: const EdgeInsets.all(SportifySpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF292929),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 180,
                        child: _AlbumArt(imageUrl: track.coverUrl),
                      ),
                    ),
                    const SizedBox(height: SportifySpacing.sm),
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SportifyColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      track.artist,
                      style: const TextStyle(color: SportifyColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SportifySpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const <Widget>[
                  _ShareAction(icon: Icons.link, label: 'Copy link'),
                  _ShareAction(icon: Icons.camera_alt_outlined, label: 'Stories'),
                  _ShareAction(icon: Icons.message_outlined, label: 'SMS'),
                  _ShareAction(icon: Icons.more_horiz, label: 'More'),
                ],
              ),
            ],
          ),
        ),
      ),
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
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _NowPlayingBackdrop(imageUrl: track.coverUrl),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x33000000),
                      Color(0xAA000000),
                      Color(0xF0121212),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.sm,
                    SportifySpacing.md,
                    SportifySpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.expand_more, color: SportifyColors.textPrimary),
                          ),
                          const SizedBox(width: SportifySpacing.sm),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Text(
                                  'PLAYING FROM ARTIST',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SportifyColors.textSecondary,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SportifyColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showShareSheet(track),
                            icon: const Icon(Icons.more_vert, color: SportifyColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: SportifySpacing.md),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _AlbumArt(imageUrl: track.coverUrl),
                          ),
                        ),
                      ),
                      const SizedBox(height: SportifySpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SportifyColors.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: SportifySpacing.xs),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SportifyColors.textSecondary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            iconSize: 36,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: SportifyColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
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
                      const SizedBox(height: SportifySpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          IconButton(
                            onPressed: vm.toggleShuffle,
                            iconSize: 30,
                            color: isShuffleActive
                                ? SportifyColors.primary
                                : SportifyColors.textSecondary,
                            icon: const Icon(Icons.shuffle),
                          ),
                          IconButton(
                            onPressed: vm.previousTrack,
                            iconSize: 42,
                            icon: const Icon(Icons.skip_previous, color: SportifyColors.textPrimary),
                          ),
                          IconButton(
                            onPressed: vm.togglePlayPause,
                            iconSize: 84,
                            icon: Icon(
                              state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: SportifyColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: vm.nextTrack,
                            iconSize: 42,
                            icon: const Icon(Icons.skip_next, color: SportifyColors.textPrimary),
                          ),
                          IconButton(
                            onPressed: vm.cycleRepeatMode,
                            iconSize: 30,
                            color: repeatColor,
                            icon: Icon(repeatIcon),
                          ),
                        ],
                      ),
                      const SizedBox(height: SportifySpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.devices_outlined),
                          ),
                          IconButton(
                            onPressed: () => _showShareSheet(track),
                            icon: const Icon(Icons.share_outlined),
                          ),
                          IconButton(
                            onPressed: () => _openQueueSheet(vm),
                            icon: const Icon(Icons.playlist_play),
                          ),
                        ],
                      ),
                      const SizedBox(height: SportifySpacing.sm),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF108154),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
                        child: Row(
                          children: const <Widget>[
                            Text(
                              'Lyrics',
                              style: TextStyle(
                                color: SportifyColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.share_outlined, color: SportifyColors.textPrimary),
                            SizedBox(width: SportifySpacing.sm),
                            Icon(Icons.open_in_full, color: SportifyColors.textPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

class _NowPlayingBackdrop extends StatelessWidget {
  const _NowPlayingBackdrop({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(color: const Color(0xFF1A1A1A));
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A1A1A)),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: SportifyColors.surface,
        child: const Icon(Icons.album, size: 120, color: SportifyColors.textSecondary),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: SportifyColors.surface,
        child: const Icon(Icons.album, size: 120, color: SportifyColors.textSecondary),
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircleAvatar(
          radius: 24,
          backgroundColor: SportifyColors.textPrimary,
          child: Icon(icon, color: SportifyColors.background),
        ),
        const SizedBox(height: SportifySpacing.xs),
        Text(
          label,
          style: const TextStyle(color: SportifyColors.textPrimary, fontSize: 12),
        ),
      ],
    );
  }
}
