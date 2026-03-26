import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../viewmodels/library_view_model.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryViewModel>().loadSavedTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        if (state.isLoading && state.items.isEmpty && state.playlists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: vm.loadSavedTracks,
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
                  child: Text(
                    'Your Library',
                    style: Theme.of(context).textTheme.headlineMedium,
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
                        selected: _tabIndex == 0,
                        onTap: () => setState(() => _tabIndex = 0),
                      ),
                      _TabChip(
                        label: 'Albums',
                        selected: _tabIndex == 1,
                        onTap: () => setState(() => _tabIndex = 1),
                      ),
                      _TabChip(
                        label: 'Artists',
                        selected: _tabIndex == 2,
                        onTap: () => setState(() => _tabIndex = 2),
                      ),
                      _TabChip(
                        label: 'Liked Songs',
                        selected: _tabIndex == 3,
                        onTap: () => setState(() => _tabIndex = 3),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SportifySpacing.md,
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: SportifyColors.error),
                    ),
                  ),
                ),
              if (_tabIndex == 0)
                SliverList.builder(
                  itemCount: state.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];
                    return ListTile(
                      onTap: () async {
                        await ContentDeeplinkNavigator.open(
                          context: context,
                          type: 'playlist',
                          id: playlist.id,
                          title: playlist.title,
                        );
                        if (!context.mounted) return;
                        await vm.loadSavedTracks();
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.queue_music_outlined),
                      ),
                      title: Text(playlist.title),
                      subtitle: Text('${playlist.trackCount} tracks'),
                      trailing: Icon(
                        playlist.isPublic ? Icons.public : Icons.lock_outline,
                        size: 18,
                      ),
                    );
                  },
                ),
              if (_tabIndex == 1)
                SliverList.builder(
                  itemCount: state.albums.length,
                  itemBuilder: (context, index) {
                    final album = state.albums[index];
                    return ListTile(
                      onTap: () {
                        ContentDeeplinkNavigator.open(
                          context: context,
                          type: 'album',
                          id: album.id,
                          title: album.title,
                        );
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.album_outlined),
                      ),
                      title: Text(album.title),
                      subtitle: Text(
                        '${album.artist} • ${album.trackCount} tracks',
                      ),
                    );
                  },
                ),
              if (_tabIndex == 2)
                SliverList.builder(
                  itemCount: state.artists.length,
                  itemBuilder: (context, index) {
                    final artist = state.artists[index];
                    return ListTile(
                      onTap: () {
                        ContentDeeplinkNavigator.open(
                          context: context,
                          type: 'artist',
                          id: artist.id,
                          title: artist.name,
                        );
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(artist.name),
                      subtitle: Text('${artist.albumCount} albums'),
                    );
                  },
                ),
              if (_tabIndex == 3)
                SliverList.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      onTap: () async {
                        if (item.audioUrl.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Track has no audio url.'),
                            ),
                          );
                          return;
                        }
                        final queue = state.items
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
                        final startIndex = queue.indexWhere(
                          (it) => it.id == item.id,
                        );
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
                      leading: const CircleAvatar(
                        child: Icon(Icons.favorite_outline),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.artist),
                      trailing: IconButton(
                        onPressed: () => vm.unsaveTrack(item.id),
                        icon: const Icon(
                          Icons.favorite,
                          color: SportifyColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
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
