import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../models/home_media_item.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/home_top_filters.dart';
import '../widgets/horizontal_music_section.dart';
import '../widgets/quick_access_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeViewModel>().loadHomeFeed();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<HomeViewModel>().loadHomeFeed();
  }

  Future<void> _playItem(
    BuildContext context,
    List<HomeMediaItem> items,
    int index,
  ) async {
    final item = items[index];
    if (item.audioUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track has no audio url.')),
      );
      return;
    }
    final queue = items
        .where((it) => it.audioUrl.trim().isNotEmpty)
        .map(
          (it) => PlayerTrack(
            id: it.id,
            title: it.title,
            artist: it.subtitle,
            audioUrl: it.audioUrl,
            coverUrl: it.imageUrl,
          ),
        )
        .toList(growable: false);
    final startTrack = PlayerTrack(
      id: item.id,
      title: item.title,
      artist: item.subtitle,
      audioUrl: item.audioUrl,
      coverUrl: item.imageUrl,
    );
    final startIndex = queue.indexWhere((it) => it.id == item.id);
    final vm = context.read<PlayerViewModel>();
    if (startIndex == -1) {
      await vm.playTrack(startTrack);
      if (!context.mounted) return;
      final error = vm.state.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    await vm.playQueue(queue, startIndex: startIndex);
    if (!context.mounted) return;
    final error = vm.state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthViewModel? authVm;
    try {
      authVm = context.read<AuthViewModel>();
    } catch (_) {
      authVm = null;
    }
    final userName = authVm?.state.user?.fullName;
    final userInitial = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim().substring(0, 1).toUpperCase()
        : 'H';

    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        if (state.isLoading && state.trending.isEmpty) {
          return const HomeSkeleton();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: HomeTopFilters(userInitial: userInitial)),
              SliverToBoxAdapter(
                child: QuickAccessGrid(
                  items: state.quickAccess,
                  onItemTap: (item) => _playItem(
                    context,
                    state.quickAccess,
                    state.quickAccess.indexOf(item),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Recently Played',
                  items: state.recentlyPlayed,
                  onItemTap: (item) => _playItem(
                    context,
                    state.recentlyPlayed,
                    state.recentlyPlayed.indexOf(item),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Made For You',
                  items: state.madeForYou,
                  onItemTap: (item) => _playItem(
                    context,
                    state.madeForYou,
                    state.madeForYou.indexOf(item),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Popular / Trending',
                  items: state.trending,
                  onItemTap: (item) => _playItem(
                    context,
                    state.trending,
                    state.trending.indexOf(item),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'New Releases',
                  items: state.newReleases,
                  onItemTap: (item) => _playItem(
                    context,
                    state.newReleases,
                    state.newReleases.indexOf(item),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Genres / Moods',
                  items: state.genres,
                ),
              ),
              if (state.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(SportifySpacing.md),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: SportifyColors.error),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: SportifySpacing.xl)),
            ],
          ),
        );
      },
    );
  }
}
