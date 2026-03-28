import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../features/auth/presentation/views/profile_screen.dart';
import '../../../features/catalog/presentation/views/search_screen.dart';
import '../../../features/home/presentation/views/home_screen.dart';
import '../../../features/jam/presentation/viewmodels/jam_view_model.dart';
import '../../../features/jam/presentation/views/jam_session_screen.dart';
import '../../../features/jam/data/models/jam_models.dart';
import '../../../features/library/presentation/views/library_screen.dart';
import '../../../features/library/presentation/viewmodels/library_view_model.dart';
import '../../../features/library/data/repositories/library_repository.dart';
import '../../../features/player/presentation/views/now_playing_screen.dart';
import '../../../features/player/presentation/viewmodels/player_view_model.dart';
import '../../../features/playlists/presentation/views/playlist_detail_screen.dart';
import '../../../core/theme/sportify_theme.dart';
import '../widgets/create_menu_sheet.dart';
import '../widgets/create_playlist_name_sheet.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
        3,
        (_) => GlobalKey<NavigatorState>(),
      );

  late final List<Widget> _tabs = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  Future<void> _openJamSetup() async {
    final jamVm = context.read<JamViewModel>();
    await jamVm.loadActiveSession();
    if (!mounted) return;

    final active = jamVm.state.session;
    if (active != null && active.isActive) {
      if (active.isHost) {
        final confirmed = await _showStartNewJamDialog();
        if (!mounted || confirmed != true) return;
        await jamVm.endSession(active.id);
        if (!mounted) return;
      } else {
        await _openJamSessionSheet(active.id);
        return;
      }
    }

    final authUser =
        context.read<AuthViewModel>().state.user?.fullName ?? 'hieu';
    final hostName = authUser.trim().isEmpty
        ? 'hieu'
        : authUser.trim().split(' ').first.toLowerCase();
    final created = await jamVm.createSession(title: "$hostName's Jam");
    if (!mounted || created == null) return;

    await _syncLikedSongsToJam(created.id);
    if (!mounted) return;
    await _openJamSessionSheet(created.id);
  }

  Future<void> _syncLikedSongsToJam(String sessionId) async {
    final jamVm = context.read<JamViewModel>();
    List<String> trackIds = const <String>[];
    try {
      final libraryRepository = context.read<LibraryRepository>();
      final liked = await libraryRepository.getSavedTracks(limit: 200);
      if (!mounted) return;
      trackIds = liked
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      if (!mounted) return;
      trackIds = const <String>[];
    }

    if (trackIds.isEmpty) {
      final playerQueue = context.read<PlayerViewModel>().state.queue;
      trackIds = playerQueue
          .map((item) => item.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    }
    if (trackIds.isEmpty) return;

    await jamVm.syncQueueAsHost(
      sessionId: sessionId,
      trackIds: trackIds,
      queueIndex: 0,
      currentTrackId: trackIds.first,
    );
  }

  Future<void> _openJamSessionSheet(String sessionId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: JamSessionScreen(sessionId: sessionId),
          ),
        );
      },
    );
  }

  Future<bool?> _showStartNewJamDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'End your current Jam and start a new one?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: SportifySpacing.md),
                const Text(
                  'Starting a new Jam will end the session that you\'re currently hosting (for everyone).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: SportifySpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: SportifyColors.primary,
                      foregroundColor: SportifyColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Start new Jam',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JamViewModel>().loadActiveSession();
    });
  }

  Future<void> _openCreateSheet() async {
    final created = await showModalBottomSheet<CreatedPlaylistPayload>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreateMenuSheet(onOpenJam: _openJamSetup),
    );
    if (created == null || !mounted) return;

    final libraryVm = context.read<LibraryViewModel>();
    await libraryVm.loadSavedTracks();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(
          playlistId: created.id,
          initialTitle: created.title,
          isCollaborativeHint: created.isCollaborative,
          openMembersOnLaunch: created.isCollaborative,
        ),
      ),
    );
    if (!mounted) return;
    await libraryVm.loadSavedTracks();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.select<AuthViewModel, String?>(
      (vm) => vm.state.user?.fullName,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }
      },
      child: Scaffold(
        drawer: Drawer(
          backgroundColor: const Color(0xFF191919),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: SportifyColors.border),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: SportifyColors.primary,
                        child: Text(
                          (authUser != null && authUser.trim().isNotEmpty)
                              ? authUser.substring(0, 1).toUpperCase()
                              : 'H',
                          style: const TextStyle(
                            color: SportifyColors.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: SportifySpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              authUser ?? 'hieu',
                              style: const TextStyle(
                                color: SportifyColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.05,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: SportifyColors.textSecondary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: const Text('View profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: SportifySpacing.sm,
                    ),
                    children: <Widget>[
                      _DrawerMenuTile(
                        icon: Icons.add_circle_outline,
                        label: 'Add account',
                        onTap: () {},
                      ),
                      _DrawerMenuTile(
                        icon: Icons.bolt_outlined,
                        label: 'What\'s new',
                        onTap: () {},
                      ),
                      _DrawerMenuTile(
                        icon: Icons.access_time,
                        label: 'Recents',
                        onTap: () {},
                      ),
                      _DrawerMenuTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings and privacy',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _DrawerMenuTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onLogout();
                  },
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: List<Widget>.generate(
            _tabs.length,
            (index) => _TabBranch(
              navigatorKey: _navigatorKeys[index],
              child: _tabs[index],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigator(
          currentIndex: _currentIndex,
          onSelected: (index) async {
            if (index == 3) {
              await _openCreateSheet();
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: SportifyColors.textPrimary, size: 18),
      horizontalTitleGap: 8,
      title: Text(
        label,
        style: const TextStyle(
          color: SportifyColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class BottomNavigator extends StatelessWidget {
  const BottomNavigator({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final Future<void> Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, JamViewModel>(
      builder: (context, playerVm, jamVm, _) {
        final playerState = playerVm.state;
        final jamSession = jamVm.state.session;
        return Container(
          color: const Color(0xFF121212),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (jamSession != null && jamSession.isActive)
                _MiniJamBar(session: jamSession),
              if (playerState.currentTrack != null)
                _MiniPlayerBar(playerVm: playerVm),
              Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicatorColor: Colors.transparent,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        color: isSelected
                            ? SportifyColors.textPrimary
                            : SportifyColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 12,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: isSelected
                            ? SportifyColors.textPrimary
                            : SportifyColors.textSecondary,
                      );
                    }),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => onSelected(index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.home_filled),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.library_music_outlined),
                      label: 'Your Library',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.add),
                      label: 'Create',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniJamBar extends StatefulWidget {
  const _MiniJamBar({required this.session});

  final JamSession session;

  @override
  State<_MiniJamBar> createState() => _MiniJamBarState();
}

class _MiniJamBarState extends State<_MiniJamBar> {
  static const double _collapsedHeight = 36;
  static const double _expandedHeight = 74;
  bool _expanded = false;

  void _expand() {
    if (_expanded) return;
    setState(() {
      _expanded = true;
    });
  }

  void _collapse() {
    if (!_expanded) return;
    setState(() {
      _expanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final safeIndex = session.queue.items.isEmpty
        ? 0
        : session.queue.currentIndex
              .clamp(0, session.queue.items.length - 1)
              .toInt();
    final currentTrack = session.queue.items.isNotEmpty
        ? session.queue.items[safeIndex]
        : null;
    return Material(
      color: const Color(0xFF0E7CA5),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < -2) {
            _expand();
            return;
          }
          if (details.delta.dy > 2) {
            _collapse();
          }
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -100) {
            _expand();
            return;
          }
          if (velocity > 100) {
            _collapse();
          }
        },
        child: InkWell(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.62),
              builder: (_) {
                return FractionallySizedBox(
                  heightFactor: 0.86,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: JamSessionScreen(sessionId: session.id),
                  ),
                );
              },
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: _expanded ? _expandedHeight : _collapsedHeight,
            child: ClipRect(
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 28,
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xCCFFFFFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        session.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: SportifyColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        currentTrack?.title ??
                                            'No track synced',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: SportifyColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: SportifyColors.primary,
                                  child: Text(
                                    'H',
                                    style: TextStyle(
                                      color: SportifyColors.background,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${session.title} • ${currentTrack?.title ?? 'No track synced'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SportifyColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_up,
                            color: SportifyColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerBar extends StatelessWidget {
  const _MiniPlayerBar({required this.playerVm});

  final PlayerViewModel playerVm;

  @override
  Widget build(BuildContext context) {
    final state = playerVm.state;
    final track = state.currentTrack!;
    final durationMs = state.duration.inMilliseconds;
    final progress = durationMs <= 0
        ? 0.0
        : (state.position.inMilliseconds / durationMs).clamp(0.0, 1.0);

    return Material(
      color: const Color(0xFF0E5B3B),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NowPlayingScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 36,
                      height: 36,
                      color: SportifyColors.card,
                      child: const Icon(Icons.music_note, size: 18),
                    ),
                  ),
                  const SizedBox(width: SportifySpacing.sm),
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SportifyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.devices_outlined,
                      color: SportifyColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: SportifyColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: playerVm.togglePlayPause,
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: SportifyColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 2,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(color: SportifyColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBranch extends StatelessWidget {
  const _TabBranch({required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (_) => child,
          settings: const RouteSettings(name: 'root'),
        );
      },
    );
  }
}
