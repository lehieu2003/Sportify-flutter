import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../../player/presentation/widgets/track_options_sheet.dart';
import '../../data/models/catalog_models.dart';
import '../viewmodels/search_view_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _isQueryMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchViewModel>().loadLanding();
    });
  }

  Future<void> _playFromSearch(
    CatalogTrack track,
    List<CatalogTrack> items,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (track.audioUrl.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Track has no audio URL.')),
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

  Future<void> _openTrackOptions(CatalogTrack track) async {
    await showTrackOptionsSheet(
      context,
      track: TrackOptionsData(
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        artistId: track.artistId,
        audioUrl: track.audioUrl,
        coverUrl: track.coverUrl,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterQueryMode({String initialText = ''}) {
    if (!_isQueryMode) {
      setState(() {
        _isQueryMode = true;
      });
    }
    if (initialText.trim().isNotEmpty) {
      _controller.text = initialText.trim();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    _focusNode.requestFocus();
  }

  Future<void> _exitQueryMode() async {
    _debounce?.cancel();
    _focusNode.unfocus();
    _controller.clear();
    await context.read<SearchViewModel>().search('');
    if (!mounted) return;
    setState(() {
      _isQueryMode = false;
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<SearchViewModel>().search(value);
    });
  }

  Future<void> _openDeeplink({
    required String type,
    required String id,
    required String title,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    if (normalizedType == 'genre') {
      _enterQueryMode(initialText: title.isEmpty ? id : title);
      await context.read<SearchViewModel>().searchByGenre(id);
      return;
    }

    await ContentDeeplinkNavigator.open(
      context: context,
      type: normalizedType,
      id: id,
      title: title,
      onGenre: (genreSlug, _) async {
        _enterQueryMode(initialText: genreSlug);
        await context.read<SearchViewModel>().searchByGenre(genreSlug);
      },
    );
  }

  Future<void> _handleRecentTap(SearchRecentItem item) async {
    final type = item.type.trim().toLowerCase();
    if (type == 'track' && item.itemId.startsWith('query:')) {
      _enterQueryMode(initialText: item.title);
      await context.read<SearchViewModel>().search(item.title);
      return;
    }
    await _openDeeplink(type: item.type, id: item.itemId, title: item.title);
  }

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = hex.replaceAll('#', '');
    if (value.length != 6) return fallback;
    return Color(int.parse('FF$value', radix: 16));
  }

  IconData _recentIconForType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'artist':
        return Icons.person;
      case 'playlist':
        return Icons.queue_music;
      case 'track':
        return Icons.history;
      case 'album':
      default:
        return Icons.album;
    }
  }

  Widget _buildSearchField({
    required SearchViewModel vm,
    required bool autoFocus,
    Widget? leading,
  }) {
    return Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading,
          const SizedBox(width: SportifySpacing.sm),
        ],
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: autoFocus,
            onChanged: _onQueryChanged,
            onSubmitted: vm.submitQuery,
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
      ],
    );
  }

  Widget _buildLandingMode(SearchUiState state, SearchViewModel vm) {
    final discoverCards = state.discoverCards;
    final browseCards = state.browseCategories;
    final recents = state.recentSearches;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SportifySpacing.md,
        SportifySpacing.lg,
        SportifySpacing.md,
        108,
      ),
      children: <Widget>[
        Row(
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
        const SizedBox(height: SportifySpacing.md),
        Material(
          color: const Color(0xFFE7E7E7),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              _enterQueryMode();
            },
            child: const SizedBox(
              height: 48,
              child: Row(
                children: <Widget>[
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Color(0xFF555555)),
                  SizedBox(width: 8),
                  Text(
                    'What do you want to listen to?',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.errorMessage != null) ...<Widget>[
          const SizedBox(height: SportifySpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: SportifyColors.error),
            ),
          ),
        ],
        const SizedBox(height: SportifySpacing.lg),
        const Text(
          'Discover fresh content',
          style: TextStyle(
            color: SportifyColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: SportifySpacing.md),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: discoverCards.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: SportifySpacing.md),
            itemBuilder: (context, index) {
              final card = discoverCards[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDeeplink(
                    type: card.deeplinkType,
                    id: card.deeplinkId,
                    title: card.title,
                  ),
                  child: Container(
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
                            child: card.imageUrl.trim().isEmpty
                                ? const SizedBox.shrink()
                                : Image.network(
                                    card.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
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
                              fontSize: 18,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (recents.isNotEmpty) ...<Widget>[
          const SizedBox(height: SportifySpacing.lg),
          const Text(
            'Recent searches',
            style: TextStyle(
              color: SportifyColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: SportifySpacing.sm),
          ...recents.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _handleRecentTap(item),
              leading: CircleAvatar(
                backgroundColor: SportifyColors.card,
                backgroundImage: item.imageUrl.trim().isEmpty
                    ? null
                    : NetworkImage(item.imageUrl),
                child: item.imageUrl.trim().isEmpty
                    ? Icon(_recentIconForType(item.type))
                    : null,
              ),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: IconButton(
                onPressed: () => vm.removeRecent(item.id),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
        const SizedBox(height: SportifySpacing.lg),
        const Text(
          'Browse all',
          style: TextStyle(
            color: SportifyColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: SportifySpacing.md),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: browseCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: SportifySpacing.md,
            mainAxisSpacing: SportifySpacing.md,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final card = browseCards[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openDeeplink(
                  type: card.deeplinkType,
                  id: card.deeplinkId,
                  title: card.title,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _parseHexColor(
                      card.colorHex,
                      const Color(0xFF584270),
                    ),
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
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQueryMode(SearchUiState state, SearchViewModel vm) {
    final hasQuery = _controller.text.trim().isNotEmpty;
    final showRecents = !hasQuery && !state.isLoading;

    return Column(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SportifySpacing.md,
              SportifySpacing.md,
              SportifySpacing.md,
              SportifySpacing.sm,
            ),
            child: _buildSearchField(
              vm: vm,
              autoFocus: true,
              leading: IconButton(
                onPressed: _exitQueryMode,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SportifySpacing.md,
              0,
              SportifySpacing.md,
              SportifySpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: SportifyColors.error),
              ),
            ),
          ),
        Expanded(
          child: showRecents
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(
                    SportifySpacing.md,
                    SportifySpacing.sm,
                    SportifySpacing.md,
                    108,
                  ),
                  children: <Widget>[
                    const Text(
                      'Recent searches',
                      style: TextStyle(
                        color: SportifyColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: SportifySpacing.sm),
                    ...state.recentSearches.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _handleRecentTap(item),
                        leading: CircleAvatar(
                          backgroundColor: SportifyColors.card,
                          backgroundImage: item.imageUrl.trim().isEmpty
                              ? null
                              : NetworkImage(item.imageUrl),
                          child: item.imageUrl.trim().isEmpty
                              ? Icon(_recentIconForType(item.type))
                              : null,
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: IconButton(
                          onPressed: () => vm.removeRecent(item.id),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 108),
                  itemCount: state.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      if (state.nextCursor == null ||
                          state.nextCursor!.isEmpty) {
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
                        vm.addRecentFromTrack(track);
                        ContentDeeplinkNavigator.open(
                          context: context,
                          type: 'album',
                          id: albumId,
                          title: track.albumTitle ?? track.title,
                        );
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.music_note),
                      ),
                      title: Text(track.title),
                      subtitle: Text(
                        track.albumTitle?.trim().isNotEmpty == true
                            ? '${track.artist} • ${track.albumTitle}'
                            : track.artist,
                      ),
                      trailing: IconButton(
                        onPressed: () => _openTrackOptions(track),
                        icon: const Icon(Icons.more_vert),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        if (_isQueryMode) {
          return _buildQueryMode(state, vm);
        }
        return _buildLandingMode(state, vm);
      },
    );
  }
}
