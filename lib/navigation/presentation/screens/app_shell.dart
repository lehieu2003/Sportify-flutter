import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/views/profile_screen.dart';
import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../features/catalog/presentation/views/search_screen.dart';
import '../../../features/home/presentation/views/home_screen.dart';
import '../../../features/library/presentation/views/library_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  static const _titles = <String>['Home', 'Search', 'Library', 'Profile'];

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
        4,
        (_) => GlobalKey<NavigatorState>(),
      );

  late final List<Widget> _tabs = <Widget>[
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

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
        appBar: AppBar(title: Text(_titles[_currentIndex])),
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
          onSelected: (index) {
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
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
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
