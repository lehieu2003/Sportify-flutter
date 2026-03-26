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
  final _focusNode = FocusNode();

  static const _discoverCards = <({String title, String seed})>[
    (title: 'Nhạc dành cho bạn', seed: 'discover-for-you'),
    (title: '#vietnamese trap', seed: 'discover-vn-trap'),
    (title: '#royalcore', seed: 'discover-royalcore'),
  ];

  static const _browseCards = <({String title, Color color, String seed})>[
    (title: 'Nhạc', color: Color(0xFFD84093), seed: 'browse-music'),
    (title: 'Podcast', color: Color(0xFF00685F), seed: 'browse-podcast'),
    (title: 'Sự kiện trực tiếp', color: Color(0xFF5B189E), seed: 'browse-live'),
    (title: 'Dành cho bạn', color: Color(0xFF584270), seed: 'browse-for-you'),
  ];

  Future<void> _playFromSearch(
    CatalogTrack track,
    List<CatalogTrack> items,
  ) async {
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
    _focusNode.dispose();
    super.dispose();
  }

  bool _shouldShowDefaultState(SearchUiState state) {
    return _controller.text.trim().isEmpty &&
        state.query.trim().isEmpty &&
        state.items.isEmpty &&
        !state.isLoading;
  }

  Widget _buildDefaultState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SportifySpacing.md,
        SportifySpacing.sm,
        SportifySpacing.md,
        108,
      ),
      children: <Widget>[
        const Text(
          'Khám phá nội dung mới mẻ',
          style: TextStyle(
            color: SportifyColors.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: SportifySpacing.md),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _discoverCards.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: SportifySpacing.md),
            itemBuilder: (context, index) {
              final card = _discoverCards[index];
              return Container(
                width: 128,
                decoration: BoxDecoration(
                  color: SportifyColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                Colors.white.withValues(alpha: 0.06),
                                Colors.black.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        card.title,
                        style: const TextStyle(
                          color: SportifyColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: SportifySpacing.lg),
        const Text(
          'Duyệt tìm tất cả',
          style: TextStyle(
            color: SportifyColors.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: SportifySpacing.md),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _browseCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: SportifySpacing.md,
            mainAxisSpacing: SportifySpacing.md,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final card = _browseCards[index];
            return Container(
              decoration: BoxDecoration(
                color: card.color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(SportifySpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  card.title,
                  style: const TextStyle(
                    color: SportifyColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        return CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: SizedBox(height: SportifySpacing.lg),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SportifySpacing.md,
                  SportifySpacing.md,
                  SportifySpacing.md,
                  SportifySpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: SportifyColors.primary,
                      child: Text(
                        'H',
                        style: TextStyle(
                          color: SportifyColors.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: SportifySpacing.md),
                    const Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          color: SportifyColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SportifySpacing.md,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: vm.search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'What do you want to listen to?',
                    prefixIcon: const Icon(Icons.search),
                    fillColor: const Color(0xFFE7E7E7),
                    filled: true,
                    hintStyle: const TextStyle(
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (state.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.sm,
                    SportifySpacing.md,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: SportifyColors.error),
                    ),
                  ),
                ),
              ),
            if (_shouldShowDefaultState(state))
              SliverFillRemaining(child: _buildDefaultState())
            else
              SliverList.builder(
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
          ],
        );
      },
    );
  }
}
