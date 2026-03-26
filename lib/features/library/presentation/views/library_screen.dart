import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
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
      context.read<LibraryViewModel>().loadSavedTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        if (state.isLoading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: vm.loadSavedTracks,
          child: ListView.builder(
            itemCount: 2 + state.playlists.length + state.items.length,
            itemBuilder: (context, index) {
              if (index == 0 && state.errorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(SportifySpacing.md),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                  ),
                );
              }
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.xs,
                  ),
                  child: Text(
                    'Your Playlists',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }
              if (index <= state.playlists.length) {
                final playlist = state.playlists[index - 1];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.queue_music_outlined)),
                  title: Text(playlist.title),
                  subtitle: Text('${playlist.trackCount} tracks'),
                  trailing: Icon(
                    playlist.isPublic ? Icons.public : Icons.lock_outline,
                    size: 18,
                  ),
                );
              }

              if (index == state.playlists.length + 1) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.md,
                    SportifySpacing.xs,
                  ),
                  child: Text(
                    'Saved Tracks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final trackIndex = index - state.playlists.length - 2;
              if (trackIndex >= state.items.length) {
                return const SizedBox(height: 64);
              }
              final item = state.items[trackIndex];
              return ListTile(
                onTap: () async {
                  if (item.audioUrl.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Track has no audio url.')),
                    );
                    return;
                  }
                  await context.read<PlayerViewModel>().playTrack(
                    PlayerTrack(
                      id: item.id,
                      title: item.title,
                      artist: item.artist,
                      audioUrl: item.audioUrl,
                      coverUrl: item.coverUrl,
                    ),
                  );
                },
                leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                title: Text(item.title),
                subtitle: Text(item.artist),
                trailing: IconButton(
                  onPressed: () => vm.unsaveTrack(item.id),
                  icon: const Icon(Icons.favorite, color: SportifyColors.primary),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
