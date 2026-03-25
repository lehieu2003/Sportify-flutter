import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../data/home_fake_data.dart';
import '../widgets/home_header.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/horizontal_music_section.dart';
import '../widgets/quick_access_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateInitialLoad();
  }

  Future<void> _simulateInitialLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _simulateInitialLoad();
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AuthViewModel?, String?>(
      (vm) => vm?.state.user?.fullName,
    );

    if (_isLoading) {
      return const HomeSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: HomeHeader(userName: userName)),
          const SliverToBoxAdapter(
            child: QuickAccessGrid(items: HomeFakeData.quickAccess),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'Recently Played',
              items: HomeFakeData.recentlyPlayed,
            ),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'Made For You',
              items: HomeFakeData.madeForYou,
            ),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'Popular / Trending',
              items: HomeFakeData.trending,
            ),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'Based on your listening',
              items: HomeFakeData.basedOnListening,
            ),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'New Releases',
              items: HomeFakeData.newReleases,
            ),
          ),
          const SliverToBoxAdapter(
            child: HorizontalMusicSection(
              title: 'Genres / Moods',
              items: HomeFakeData.genres,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: SportifySpacing.xl)),
        ],
      ),
    );
  }
}
