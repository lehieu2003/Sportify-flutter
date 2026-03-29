import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/share/share_content_service.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../library/data/repositories/library_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../data/models/jam_models.dart';
import '../viewmodels/jam_view_model.dart';

class JamSessionScreen extends StatefulWidget {
  const JamSessionScreen({
    required this.sessionId,
    super.key,
    ShareContentService? shareContentService,
  }) : shareContentService = shareContentService ?? const ShareContentService();

  final String sessionId;
  final ShareContentService shareContentService;

  @override
  State<JamSessionScreen> createState() => _JamSessionScreenState();
}

class _JamSessionScreenState extends State<JamSessionScreen>
    with WidgetsBindingObserver {
  Future<void> _showSleepTimerSheet(PlayerViewModel playerVm) async {
    final rootContext = context;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: SportifyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget timerOption({
          required String label,
          required Duration duration,
        }) {
          return ListTile(
            title: Text(label),
            onTap: () {
              Navigator.of(sheetContext).pop();
              playerVm.startSleepTimer(duration);
              ScaffoldMessenger.of(
                rootContext,
              ).showSnackBar(SnackBar(content: Text('Timer set for $label.')));
            },
          );
        }

        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: SportifySpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SportifyColors.textSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: SportifySpacing.sm),
              const ListTile(
                title: Text(
                  'Sleep timer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              timerOption(
                label: '5 minutes',
                duration: const Duration(minutes: 5),
              ),
              timerOption(
                label: '15 minutes',
                duration: const Duration(minutes: 15),
              ),
              timerOption(
                label: '30 minutes',
                duration: const Duration(minutes: 30),
              ),
              timerOption(label: '1 hour', duration: const Duration(hours: 1)),
              if (playerVm.hasSleepTimer)
                ListTile(
                  title: const Text(
                    'Cancel timer',
                    style: TextStyle(color: SportifyColors.error),
                  ),
                  onTap: () {
                    playerVm.cancelSleepTimer();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: SportifySpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleMicrotask(() async {
      final vm = context.read<JamViewModel>();
      await vm.loadSession(widget.sessionId);
      if (!mounted) return;
      final session = vm.state.session;
      if (session != null &&
          session.isHost &&
          session.queue.items.isEmpty &&
          !vm.state.isSyncingQueue) {
        await _syncQueueFromLikedSongs(showFeedback: false);
      }
      if (!mounted) return;
      vm.startPolling(widget.sessionId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<JamViewModel>().stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = context.read<JamViewModel>();
    if (state == AppLifecycleState.paused) {
      vm.pausePolling();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      vm.resumePollingIfNeeded();
    }
  }

  Future<void> _showInviteSheet(JamSession session) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SportifyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                SportifySpacing.lg,
                SportifySpacing.lg,
                SportifySpacing.lg,
                SportifySpacing.lg + safeBottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SportifyColors.textSecondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: SportifySpacing.lg),
                  const Text(
                    'Invite friends to your Jam',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: SportifySpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _shareInviteCode(session),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share link'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SportifyColors.primary,
                        foregroundColor: SportifyColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: SportifySpacing.lg),
                  const Divider(),
                  const SizedBox(height: SportifySpacing.md),
                  const Text(
                    'Your Jam QR code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: SportifySpacing.xs),
                  const Text(
                    'Tap on the code to enlarge it.',
                    style: TextStyle(color: SportifyColors.textSecondary),
                  ),
                  const SizedBox(height: SportifySpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          session.inviteCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareInviteCode(JamSession session) async {
    try {
      await widget.shareContentService.sharePayload(
        SharePayload(
          subject: 'Sportify Jam Invite',
          text:
              'Join my Jam on Sportify. Code: ${session.inviteCode}\n'
              'sportify://jam/${session.inviteCode}',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to share invite.')));
    }
  }

  Future<void> _syncQueueFromLikedSongs({bool showFeedback = true}) async {
    final jamVm = context.read<JamViewModel>();
    final session = jamVm.state.session;
    if (session == null) return;
    List<String> trackIds = const <String>[];
    try {
      final libraryRepository = context.read<LibraryRepository>();
      final likedTracks = await libraryRepository.getSavedTracks(limit: 200);
      if (!mounted) return;
      trackIds = likedTracks
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      if (!mounted) return;
      trackIds = const <String>[];
    }
    if (!mounted) return;

    if (trackIds.isEmpty) {
      final playerQueue = context.read<PlayerViewModel>().state.queue;
      trackIds = playerQueue
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    }

    if (trackIds.isEmpty) {
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No songs to sync. Save songs to Liked Songs or play a queue first.',
            ),
          ),
        );
      }
      return;
    }

    await jamVm.syncQueueAsHost(
      sessionId: session.id,
      trackIds: trackIds,
      queueIndex: 0,
      currentTrackId: trackIds.first,
    );
    if (!mounted) return;
    final error = jamVm.state.errorMessage;
    if (error == null) {
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liked Songs synced to Jam.')),
        );
      }
      return;
    }
    if (showFeedback) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _leaveSession() async {
    await context.read<JamViewModel>().leaveSession(widget.sessionId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _endSession() async {
    await context.read<JamViewModel>().endSession(widget.sessionId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _playFromJamQueue(int requestedIndex) async {
    final session = context.read<JamViewModel>().state.session;
    if (session == null || session.queue.items.isEmpty) return;

    final playable = <({int originalIndex, PlayerTrack track})>[];
    for (var i = 0; i < session.queue.items.length; i += 1) {
      final item = session.queue.items[i];
      final id = item.trackId.trim();
      final audioUrl = item.audioUrl.trim();
      final previewUrl = item.previewUrl.trim();
      if (id.isEmpty || (audioUrl.isEmpty && previewUrl.isEmpty)) {
        continue;
      }
      playable.add((
        originalIndex: i,
        track: PlayerTrack(
          id: id,
          title: item.title,
          artist: item.artist,
          audioUrl: audioUrl,
          coverUrl: item.coverUrl,
          previewUrl: previewUrl,
          isPreviewOnly: audioUrl.isEmpty && previewUrl.isNotEmpty,
        ),
      ));
    }

    if (playable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playable tracks in this Jam queue.')),
      );
      return;
    }

    var bestIndex = 0;
    var bestDistance = 1 << 30;
    for (var i = 0; i < playable.length; i += 1) {
      final distance = (playable[i].originalIndex - requestedIndex).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    final queue = playable.map((entry) => entry.track).toList(growable: false);
    await context.read<PlayerViewModel>().playQueue(
      queue,
      startIndex: bestIndex,
    );
  }

  Widget _buildParticipantAvatar(JamParticipant participant) {
    final initial = participant.fullName.trim().isNotEmpty
        ? participant.fullName.trim().substring(0, 1).toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: participant.role == 'host'
          ? SportifyColors.primary
          : SportifyColors.surface,
      child: Text(
        initial,
        style: TextStyle(
          color: participant.role == 'host'
              ? SportifyColors.background
              : SportifyColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<JamViewModel, PlayerViewModel>(
      builder: (context, vm, playerVm, _) {
        final state = vm.state;
        final session = state.session;
        if (state.isLoading && session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (session == null) {
          return Scaffold(
            backgroundColor: SportifyColors.background,
            appBar: AppBar(title: const Text('Jam session')),
            body: Center(
              child: Text(
                state.errorMessage ?? 'Jam session is not available.',
                style: const TextStyle(color: SportifyColors.error),
              ),
            ),
          );
        }

        final activeParticipants = session.participants
            .where((item) => item.isActive)
            .toList(growable: false);

        final repeatMode = playerVm.state.repeatMode;
        final repeatIcon = switch (repeatMode) {
          'one' => Icons.repeat_one,
          _ => Icons.repeat,
        };
        final isHost = session.isHost;

        return Scaffold(
          backgroundColor: SportifyColors.background,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                const SizedBox(height: SportifySpacing.sm),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SportifyColors.textSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: SportifySpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SportifySpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: session.isHost
                            ? _syncQueueFromLikedSongs
                            : null,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                          'Add songs',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SportifySpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: () => _showInviteSheet(session),
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(width: SportifySpacing.xs),
                      ...activeParticipants
                          .take(4)
                          .map(_buildParticipantAvatar),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: session.isHost ? _endSession : _leaveSession,
                        child: Text(session.isHost ? 'End' : 'Leave'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => vm.loadSession(session.id),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SportifySpacing.md,
                      ),
                      children: <Widget>[
                        const SizedBox(height: SportifySpacing.sm),
                        const Text(
                          'Queue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Playing Liked Songs',
                          style: TextStyle(color: SportifyColors.textSecondary),
                        ),
                        const SizedBox(height: SportifySpacing.sm),
                        if (session.queue.items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(SportifySpacing.md),
                            margin: const EdgeInsets.only(
                              bottom: SportifySpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: SportifyColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'No songs in this Jam yet.',
                                  style: TextStyle(
                                    color: SportifyColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: SportifySpacing.xs),
                                const Text(
                                  'Tap Add songs to sync from Liked Songs.',
                                  style: TextStyle(
                                    color: SportifyColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: SportifySpacing.sm),
                                FilledButton.tonal(
                                  onPressed: session.isHost
                                      ? _syncQueueFromLikedSongs
                                      : null,
                                  child: const Text('Sync now'),
                                ),
                              ],
                            ),
                          ),
                        ...List<Widget>.generate(session.queue.items.length, (
                          index,
                        ) {
                          final item = session.queue.items[index];
                          final isCurrent =
                              item.trackId == session.queue.currentTrackId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _playFromJamQueue(index),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: item.coverUrl.trim().isEmpty
                                    ? Container(
                                        color: SportifyColors.card,
                                        child: const Icon(Icons.music_note),
                                      )
                                    : Image.network(
                                        item.coverUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: SportifyColors.card,
                                          child: const Icon(Icons.music_note),
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? SportifyColors.primary
                                    : SportifyColors.textPrimary,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              item.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              onPressed: () => _playFromJamQueue(index),
                              icon: Icon(
                                isCurrent
                                    ? Icons.play_circle_fill
                                    : Icons.play_circle_outline,
                                color: SportifyColors.textPrimary,
                              ),
                            ),
                          );
                        }),
                        if (state.pollingStatus == JamPollingStatus.error)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: SportifySpacing.sm,
                            ),
                            child: FilledButton.tonal(
                              onPressed: vm.retryPollingNow,
                              child: const Text('Retry now'),
                            ),
                          ),
                        if (state.errorMessage != null) ...<Widget>[
                          const SizedBox(height: SportifySpacing.sm),
                          Text(
                            state.errorMessage!,
                            style: const TextStyle(color: SportifyColors.error),
                          ),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    0,
                    SportifySpacing.md,
                    SportifySpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      _JamBottomAction(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        active: playerVm.state.shuffleEnabled,
                        onTap: isHost ? playerVm.toggleShuffle : null,
                      ),
                      const SizedBox(width: SportifySpacing.sm),
                      _JamBottomAction(
                        icon: repeatIcon,
                        label: 'Repeat',
                        active: repeatMode != 'off',
                        onTap: isHost ? playerVm.cycleRepeatMode : null,
                      ),
                      const SizedBox(width: SportifySpacing.sm),
                      _JamBottomAction(
                        icon: Icons.timer_outlined,
                        label: 'Timer',
                        active: playerVm.hasSleepTimer,
                        onTap: isHost
                            ? () => _showSleepTimerSheet(playerVm)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JamBottomAction extends StatelessWidget {
  const _JamBottomAction({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: SportifyColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: active
                    ? SportifyColors.primary
                    : SportifyColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? SportifyColors.primary
                      : SportifyColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
