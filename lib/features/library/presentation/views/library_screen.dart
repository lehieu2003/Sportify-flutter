import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../../playlists/presentation/views/join_playlist_by_code_screen.dart';
import '../viewmodels/library_view_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryViewModel>().bootstrap();
    });
  }

  Future<void> _onTabSelected(LibraryTab tab) async {
    await context.read<LibraryViewModel>().setTab(tab);
  }

  Widget _buildTabBody(LibraryUiState state, LibraryViewModel vm) {
    switch (state.activeTab) {
      case LibraryTab.playlists:
        return _buildPlaylistsTab(state, vm);
      case LibraryTab.albums:
        return _buildAlbumsTab(state, vm);
      case LibraryTab.artists:
        return _buildArtistsTab(state, vm);
      case LibraryTab.likedSongs:
        return _buildLikedSongsTab(state, vm);
    }
  }

  Widget _buildPlaylistsTab(LibraryUiState state, LibraryViewModel vm) {
    final tabState = state.playlists;
    if (tabState.isLoading && tabState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tabState.hasErrorOnly) {
      return _TabStatusSliver(
        message: tabState.errorMessage ?? 'Failed to load playlists.',
        actionLabel: 'Retry',
        onAction: () => vm.refreshTab(LibraryTab.playlists),
      );
    }
    if (tabState.isEmpty) {
      return _TabStatusSliver(
        message: 'No playlists yet.',
        actionLabel: 'Refresh',
        onAction: () => vm.refreshTab(LibraryTab.playlists),
      );
    }
    return SliverList.builder(
      itemCount: tabState.items.length + 1,
      itemBuilder: (context, index) {
        if (index == tabState.items.length) {
          if (!tabState.canLoadMore) return const SizedBox(height: 96);
          return Padding(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: OutlinedButton(
              onPressed: tabState.isLoadingMore ? null : vm.loadMoreCurrentTab,
              child: Text(tabState.isLoadingMore ? 'Loading...' : 'Load more'),
            ),
          );
        }
        final playlist = tabState.items[index];
        final owner = playlist.isOwner
            ? 'You'
            : (playlist.ownerName.isEmpty ? 'Unknown' : playlist.ownerName);
        return ListTile(
          onTap: () async {
            await ContentDeeplinkNavigator.open(
              context: context,
              type: 'playlist',
              id: playlist.id,
              title: playlist.title,
            );
            if (!context.mounted) return;
            await vm.refreshTab(LibraryTab.playlists);
          },
          leading: const CircleAvatar(child: Icon(Icons.queue_music_outlined)),
          title: Text(playlist.title),
          subtitle: Text('Playlist • $owner'),
          trailing: Text(
            '${playlist.trackCount}',
            style: const TextStyle(color: SportifyColors.textSecondary),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab(LibraryUiState state, LibraryViewModel vm) {
    final tabState = state.albums;
    if (tabState.isLoading && tabState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tabState.hasErrorOnly) {
      return _TabStatusSliver(
        message: tabState.errorMessage ?? 'Failed to load albums.',
        actionLabel: 'Retry',
        onAction: () => vm.refreshTab(LibraryTab.albums),
      );
    }
    if (tabState.isEmpty) {
      return _TabStatusSliver(
        message: 'No saved albums yet.',
        actionLabel: 'Refresh',
        onAction: () => vm.refreshTab(LibraryTab.albums),
      );
    }
    return SliverList.builder(
      itemCount: tabState.items.length + 1,
      itemBuilder: (context, index) {
        if (index == tabState.items.length) {
          if (!tabState.canLoadMore) return const SizedBox(height: 96);
          return Padding(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: OutlinedButton(
              onPressed: tabState.isLoadingMore ? null : vm.loadMoreCurrentTab,
              child: Text(tabState.isLoadingMore ? 'Loading...' : 'Load more'),
            ),
          );
        }
        final album = tabState.items[index];
        return ListTile(
          onTap: () {
            ContentDeeplinkNavigator.open(
              context: context,
              type: 'album',
              id: album.id,
              title: album.title,
            );
          },
          leading: const CircleAvatar(child: Icon(Icons.album_outlined)),
          title: Text(album.title),
          subtitle: Text('Album • ${album.artist}'),
        );
      },
    );
  }

  Widget _buildArtistsTab(LibraryUiState state, LibraryViewModel vm) {
    final tabState = state.artists;
    if (tabState.isLoading && tabState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tabState.hasErrorOnly) {
      return _TabStatusSliver(
        message: tabState.errorMessage ?? 'Failed to load artists.',
        actionLabel: 'Retry',
        onAction: () => vm.refreshTab(LibraryTab.artists),
      );
    }
    if (tabState.isEmpty) {
      return _TabStatusSliver(
        message: 'No followed artists yet.',
        actionLabel: 'Refresh',
        onAction: () => vm.refreshTab(LibraryTab.artists),
      );
    }
    return SliverList.builder(
      itemCount: tabState.items.length + 1,
      itemBuilder: (context, index) {
        if (index == tabState.items.length) {
          if (!tabState.canLoadMore) return const SizedBox(height: 96);
          return Padding(
            padding: const EdgeInsets.all(SportifySpacing.md),
            child: OutlinedButton(
              onPressed: tabState.isLoadingMore ? null : vm.loadMoreCurrentTab,
              child: Text(tabState.isLoadingMore ? 'Loading...' : 'Load more'),
            ),
          );
        }
        final artist = tabState.items[index];
        return ListTile(
          onTap: () {
            ContentDeeplinkNavigator.open(
              context: context,
              type: 'artist',
              id: artist.id,
              title: artist.name,
            );
          },
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(artist.name),
          subtitle: const Text('Artist'),
        );
      },
    );
  }

  Widget _buildLikedSongsTab(LibraryUiState state, LibraryViewModel vm) {
    final tabState = state.likedSongs;
    if (tabState.isLoading && tabState.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tabState.hasErrorOnly) {
      return _TabStatusSliver(
        message: tabState.errorMessage ?? 'Failed to load liked songs.',
        actionLabel: 'Retry',
        onAction: () => vm.refreshTab(LibraryTab.likedSongs),
      );
    }
    if (tabState.isEmpty) {
      return _TabStatusSliver(
        message: 'No liked songs yet.',
        actionLabel: 'Refresh',
        onAction: () => vm.refreshTab(LibraryTab.likedSongs),
      );
    }
    return SliverList.builder(
      itemCount: tabState.items.length + 1,
      itemBuilder: (context, index) {
        if (index == tabState.items.length) return const SizedBox(height: 96);
        final item = tabState.items[index];
        return ListTile(
          onTap: () async {
            if (item.audioUrl.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Track has no audio url.')),
              );
              return;
            }
            final queue = tabState.items
                .where((it) => it.audioUrl.trim().isNotEmpty)
                .map(
                  (it) => PlayerTrack(
                    id: it.id,
                    title: it.title,
                    artist: it.artist,
                    audioUrl: it.audioUrl,
                    coverUrl: it.coverUrl,
                  ),
                )
                .toList(growable: false);
            final startIndex = queue.indexWhere((it) => it.id == item.id);
            if (startIndex == -1) return;
            final playerVm = context.read<PlayerViewModel>();
            await playerVm.playQueue(queue, startIndex: startIndex);
            if (!context.mounted) return;
            final error = playerVm.state.errorMessage;
            if (error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            }
          },
          leading: const CircleAvatar(child: Icon(Icons.favorite_outline)),
          title: Text(item.title),
          subtitle: Text(item.artist),
          trailing: IconButton(
            onPressed: () => vm.unsaveTrack(item.id),
            icon: const Icon(Icons.favorite, color: SportifyColors.primary),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        return RefreshIndicator(
          onRefresh: vm.refreshCurrentTab,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: SportifySpacing.xl),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SportifySpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Your Library',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const JoinPlaylistByCodeScreen(),
                            ),
                          );
                          if (!context.mounted) return;
                          await vm.refreshTab(LibraryTab.playlists);
                        },
                        tooltip: 'Join by code',
                        icon: const Icon(Icons.confirmation_number_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.sm,
                    SportifySpacing.md,
                    SportifySpacing.sm,
                  ),
                  child: Wrap(
                    spacing: SportifySpacing.sm,
                    children: <Widget>[
                      _TabChip(
                        label: 'Playlists',
                        selected: state.activeTab == LibraryTab.playlists,
                        onTap: () => _onTabSelected(LibraryTab.playlists),
                      ),
                      _TabChip(
                        label: 'Albums',
                        selected: state.activeTab == LibraryTab.albums,
                        onTap: () => _onTabSelected(LibraryTab.albums),
                      ),
                      _TabChip(
                        label: 'Artists',
                        selected: state.activeTab == LibraryTab.artists,
                        onTap: () => _onTabSelected(LibraryTab.artists),
                      ),
                      _TabChip(
                        label: 'Liked Songs',
                        selected: state.activeTab == LibraryTab.likedSongs,
                        onTap: () => _onTabSelected(LibraryTab.likedSongs),
                      ),
                    ],
                  ),
                ),
              ),
              _buildTabBody(state, vm),
            ],
          ),
        );
      },
    );
  }
}

class _TabStatusSliver extends StatelessWidget {
  const _TabStatusSliver({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(SportifySpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SportifyColors.textSecondary),
              ),
              const SizedBox(height: SportifySpacing.sm),
              OutlinedButton(
                onPressed: () {
                  onAction();
                },
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: SportifyColors.primary.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: selected
            ? SportifyColors.textPrimary
            : SportifyColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      side: const BorderSide(color: SportifyColors.border),
      backgroundColor: SportifyColors.surface,
    );
  }
}
