import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';
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

  static const _titles = <String>['Home', 'Search', 'Your Library'];

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
        appBar: _currentIndex == 0 ? null : AppBar(title: Text(_titles[_currentIndex])),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: <Widget>[
                DrawerHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      const Text(
                        'Sportify',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authUser ?? 'Signed in user',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
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
