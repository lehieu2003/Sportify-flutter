import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../data/models/catalog_models.dart';
import 'album_detail_screen.dart';
import '../viewmodels/search_view_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  Future<void> _playFromSearch(CatalogTrack track, List<CatalogTrack> items) async {
    final messenger = ScaffoldMessenger.of(context);
    if (track.audioUrl.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Track has no audio url.')),
      );
      return;
    }
    final queue = items
        .where((item) => item.audioUrl.trim().isNotEmpty)
        .map(
          (item) => PlayerTrack(
            id: item.id,
            title: item.title,
            artist: item.artist,
            audioUrl: item.audioUrl,
            coverUrl: item.coverUrl,
          ),
        )
        .toList(growable: false);
    final startIndex = queue.indexWhere((item) => item.id == track.id);
    if (startIndex == -1) return;
    final playerVm = context.read<PlayerViewModel>();
    await playerVm.playQueue(queue, startIndex: startIndex);
    if (!context.mounted) return;
    final error = playerVm.state.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(SportifySpacing.md),
              child: TextField(
                controller: _controller,
                onSubmitted: vm.search,
                decoration: InputDecoration(
                  hintText: 'Search tracks or artists',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => vm.search(_controller.text.trim()),
                  ),
                ),
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: state.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    if (state.nextCursor == null || state.nextCursor!.isEmpty) {
                      return const SizedBox(height: 48);
                    }
                    return Padding(
                      padding: const EdgeInsets.all(SportifySpacing.md),
                      child: OutlinedButton(
                        onPressed: state.isLoading ? null : vm.loadMore,
                        child: const Text('Load more'),
                      ),
                    );
                  }

                  final track = state.items[index];
                  return ListTile(
                    onTap: () {
                      final albumId = track.albumId;
                      if (albumId == null || albumId.isEmpty) {
                        _playFromSearch(track, state.items);
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AlbumDetailScreen(
                            albumId: albumId,
                            initialTitle: track.albumTitle,
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(child: Icon(Icons.music_note)),
                    title: Text(track.title),
                    subtitle: Text(
                      track.albumTitle?.trim().isNotEmpty == true
                          ? '${track.artist} • ${track.albumTitle}'
                          : track.artist,
                    ),
                    trailing: IconButton(
                      onPressed: () => _playFromSearch(track, state.items),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
