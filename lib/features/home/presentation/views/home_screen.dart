import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../catalog/presentation/views/album_detail_screen.dart';
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

  Future<void> _openAlbum(BuildContext context, HomeMediaItem item) async {
    String? albumId = item.albumId?.trim();
    if (albumId == null || albumId.isEmpty) {
      try {
        final track = await context.read<CatalogRepository>().getTrackById(item.id);
        albumId = track.albumId?.trim();
      } catch (_) {
        albumId = null;
      }
    }
    if (albumId == null || albumId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Album chưa có dữ liệu.')));
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AlbumDetailScreen(albumId: albumId!, initialTitle: item.title),
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
              SliverToBoxAdapter(
                child: QuickAccessGrid(
                  items: state.quickAccess,
                  onItemTap: (item) => _openAlbum(context, item),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Recently Played',
                  items: state.recentlyPlayed,
                  onItemTap: (item) => _openAlbum(context, item),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Made For You',
                  items: state.madeForYou,
                  onItemTap: (item) => _openAlbum(context, item),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'Popular / Trending',
                  items: state.trending,
                  onItemTap: (item) => _openAlbum(context, item),
                ),
              ),
              SliverToBoxAdapter(
                child: HorizontalMusicSection(
                  title: 'New Releases',
                  items: state.newReleases,
                  onItemTap: (item) => _openAlbum(context, item),
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
