import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../features/auth/presentation/views/profile_screen.dart';
import '../../../features/catalog/presentation/views/search_screen.dart';
import '../../../features/home/presentation/views/home_screen.dart';
import '../../../features/library/presentation/views/library_screen.dart';
import '../../../features/player/presentation/views/now_playing_screen.dart';
import '../../../features/player/presentation/viewmodels/player_view_model.dart';
import '../../../core/theme/sportify_theme.dart';
import '../widgets/create_menu_sheet.dart';

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

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CreateMenuSheet(),
    );
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
                    padding: const EdgeInsets.symmetric(vertical: SportifySpacing.sm),
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
    return Consumer<PlayerViewModel>(
      builder: (context, playerVm, _) {
        final playerState = playerVm.state;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (playerState.currentTrack != null)
              _MiniPlayerBar(playerVm: playerVm),
            NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                onSelected(index);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
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
          ],
        );
      },
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
            MaterialPageRoute<void>(
              builder: (_) => const NowPlayingScreen(),
            ),
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
                          style: const TextStyle(color: SportifyColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.devices_outlined, color: SportifyColors.textPrimary),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline, color: SportifyColors.textPrimary),
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
