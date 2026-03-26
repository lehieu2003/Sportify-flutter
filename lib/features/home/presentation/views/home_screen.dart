import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../models/home_media_item.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/home_top_filters.dart';
import '../widgets/horizontal_music_section.dart';
import '../widgets/quick_access_grid.dart';
import 'home_section_list_screen.dart';

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

  Future<void> _openAlbum(BuildContext context, HomeMediaItem item) async {
    final albumId = item.albumId?.trim();
    if (albumId == null || albumId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Album unavailable.')));
      return;
    }
    if (!context.mounted) return;
    await ContentDeeplinkNavigator.open(
      context: context,
      type: 'album',
      id: albumId,
      title: item.title,
    );
  }

  Future<void> _openSection(BuildContext context, String title, List<HomeMediaItem> items) async {
    if (items.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeSectionListScreen(
          title: title,
          items: items,
        ),
      ),
    );
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
        final hasAnyAlbums = state.quickAccess.isNotEmpty ||
            state.recentlyPlayed.isNotEmpty ||
            state.madeForYou.isNotEmpty ||
            state.trending.isNotEmpty ||
            state.newReleases.isNotEmpty;
        if (!hasAnyAlbums && !state.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(SportifySpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'No albums yet',
                    style: TextStyle(
                      color: SportifyColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: SportifySpacing.sm),
                  const Text(
                    'Pull to refresh or play something first.',
                    style: TextStyle(color: SportifyColors.textSecondary),
                  ),
                  const SizedBox(height: SportifySpacing.md),
                  OutlinedButton(
                    onPressed: _onRefresh,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: SportifySpacing.lg),
              ),
              SliverToBoxAdapter(
                child: HomeTopFilters(userInitial: userInitial),
              ),
              if (state.quickAccess.isNotEmpty)
                SliverToBoxAdapter(
                  child: QuickAccessGrid(
                    items: state.quickAccess,
                    onItemTap: (item) => _openAlbum(context, item),
                  ),
                ),
              if (state.recentlyPlayed.isNotEmpty)
                SliverToBoxAdapter(
                  child: HorizontalMusicSection(
                    title: 'Recently Played',
                    items: state.recentlyPlayed,
                    onItemTap: (item) => _openAlbum(context, item),
                    onSeeAll: () => _openSection(context, 'Recently Played', state.recentlyPlayed),
                  ),
                ),
              if (state.madeForYou.isNotEmpty)
                SliverToBoxAdapter(
                  child: HorizontalMusicSection(
                    title: 'Made For You',
                    items: state.madeForYou,
                    onItemTap: (item) => _openAlbum(context, item),
                    onSeeAll: () => _openSection(context, 'Made For You', state.madeForYou),
                  ),
                ),
              if (state.trending.isNotEmpty)
                SliverToBoxAdapter(
                  child: HorizontalMusicSection(
                    title: 'Popular / Trending',
                    items: state.trending,
                    onItemTap: (item) => _openAlbum(context, item),
                    onSeeAll: () => _openSection(context, 'Popular / Trending', state.trending),
                  ),
                ),
              if (state.newReleases.isNotEmpty)
                SliverToBoxAdapter(
                  child: HorizontalMusicSection(
                    title: 'New Releases',
                    items: state.newReleases,
                    onItemTap: (item) => _openAlbum(context, item),
                    onSeeAll: () => _openSection(context, 'New Releases', state.newReleases),
                  ),
                ),
              if (state.genres.isNotEmpty)
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
              const SliverToBoxAdapter(
                child: SizedBox(height: SportifySpacing.xl),
              ),
            ],
          ),
        );
      },
    );
  }
}
