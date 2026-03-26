import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../../player/presentation/widgets/track_options_sheet.dart';
import '../../data/models/playlist_models.dart';
import '../../data/repositories/playlist_repository.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen({
    required this.playlistId,
    this.initialTitle,
    super.key,
  });

  final String playlistId;
  final String? initialTitle;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  bool _isLoading = true;
  bool _isLoadingRecommended = false;
  String? _errorMessage;
  String? _recommendedCursor;
  PlaylistDetail? _playlist;
  List<PlaylistTrack> _tracks = const <PlaylistTrack>[];
  List<CatalogTrack> _recommended = const <CatalogTrack>[];
  final Set<String> _addingTrackIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = context.read<PlaylistRepository>();
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getPlaylistById(widget.playlistId),
        repository.getPlaylistTracks(widget.playlistId),
      ]);
      if (!mounted) return;
      _playlist = results[0] as PlaylistDetail;
      _tracks = results[1] as List<PlaylistTrack>;
      _isLoading = false;
      setState(() {});
      await _loadRecommended(reset: true, query: _playlist?.title);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load playlist.';
      });
    }
  }

  Future<void> _reloadTracks() async {
    try {
      final repository = context.read<PlaylistRepository>();
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getPlaylistById(widget.playlistId),
        repository.getPlaylistTracks(widget.playlistId),
      ]);
      if (!mounted) return;
      setState(() {
        _playlist = results[0] as PlaylistDetail;
        _tracks = results[1] as List<PlaylistTrack>;
      });
    } catch (_) {}
  }

  Future<void> _loadRecommended({required bool reset, String? query}) async {
    if (_isLoadingRecommended) return;
    setState(() {
      _isLoadingRecommended = true;
    });
    try {
      final repository = context.read<CatalogRepository>();
      final page = await repository.searchTracks(
        query: query,
        limit: 20,
        cursor: reset ? null : _recommendedCursor,
      );
      if (!mounted) return;
      var items = page.items;
      if (reset && items.isEmpty && query != null && query.trim().isNotEmpty) {
        final fallback = await repository.searchTracks(limit: 20);
        if (!mounted) return;
        items = fallback.items;
        _recommendedCursor = fallback.nextCursor;
      } else {
        _recommendedCursor = page.nextCursor;
      }

      final existingTrackIds = _tracks.map((track) => track.trackId).toSet();
      final filtered = items
          .where((item) => !existingTrackIds.contains(item.id))
          .toList(growable: false);
      setState(() {
        if (reset) {
          _recommended = filtered;
        } else {
          final known = _recommended.map((item) => item.id).toSet();
          _recommended = <CatalogTrack>[
            ..._recommended,
            ...filtered.where((item) => !known.contains(item.id)),
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;
      if (reset) {
        setState(() {
          _recommended = const <CatalogTrack>[];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
        });
      }
    }
  }

  Future<void> _playTrack(int index) async {
    final track = _tracks[index];
    if (track.audioUrl.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Track has no audio url.')));
      return;
    }
    final queue = _tracks
        .where((item) => item.audioUrl.trim().isNotEmpty)
        .map(
          (item) => PlayerTrack(
            id: item.trackId,
            title: item.title,
            artist: item.artist,
            audioUrl: item.audioUrl,
            coverUrl: item.coverUrl,
          ),
        )
        .toList(growable: false);
    final startIndex = queue.indexWhere((item) => item.id == track.trackId);
    if (startIndex == -1) return;
    final playerVm = context.read<PlayerViewModel>();
    await playerVm.playQueue(queue, startIndex: startIndex);
    if (!mounted) return;
    final error = playerVm.state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openTrackOptions(PlaylistTrack track) async {
    await showTrackOptionsSheet(
      context,
      track: TrackOptionsData(
        trackId: track.trackId,
        title: track.title,
        artist: track.artist,
        audioUrl: track.audioUrl,
        coverUrl: track.coverUrl,
      ),
    );
  }

  Future<void> _addRecommendedTrack(CatalogTrack track) async {
    if (_addingTrackIds.contains(track.id)) return;
    setState(() {
      _addingTrackIds.add(track.id);
    });
    try {
      await context.read<PlaylistRepository>().addTrackToPlaylist(
        playlistId: widget.playlistId,
        trackId: track.id,
      );
      await _reloadTracks();
      if (!mounted) return;
      setState(() {
        _recommended = _recommended
            .where((item) => item.id != track.id)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to playlist.')));
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Failed to add track.' : message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingTrackIds.remove(track.id);
        });
      }
    }
  }

  Future<void> _openAddToPlaylistPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SportifyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TrackSearchPickerSheet(
        playlistId: widget.playlistId,
        onTrackAdded: _reloadTracks,
      ),
    );
    if (!mounted) return;
    await _loadRecommended(reset: true, query: _playlist?.title);
  }

  @override
  Widget build(BuildContext context) {
    final title = _playlist?.title ?? widget.initialTitle ?? 'Playlist';
    var ownerName = 'You';
    try {
      final vm = context.read<AuthViewModel>();
      final fullName = vm.state.user?.fullName;
      if (fullName != null && fullName.trim().isNotEmpty) {
        ownerName = fullName.trim();
      }
    } catch (_) {}
    final canLoadMoreRecommended =
        _recommendedCursor != null && _recommendedCursor!.isNotEmpty;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: SportifyColors.error),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 330,
                    backgroundColor: SportifyColors.background,
                    leading: const BackButton(),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _PlaylistHeader(
                        title: title,
                        ownerName: ownerName,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.sm,
                      ),
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: _openAddToPlaylistPicker,
                          style: FilledButton.styleFrom(
                            foregroundColor: SportifyColors.background,
                            backgroundColor: SportifyColors.textPrimary,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add to this playlist'),
                        ),
                      ),
                    ),
                  ),
                  if (_tracks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SportifySpacing.md,
                          SportifySpacing.md,
                          SportifySpacing.md,
                          SportifySpacing.xs,
                        ),
                        child: Text(
                          'In this playlist',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (_tracks.isNotEmpty)
                    SliverList.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return ListTile(
                          onTap: () => _playTrack(index),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: track.coverUrl.trim().isEmpty
                                  ? Container(
                                      color: SportifyColors.card,
                                      child: const Icon(Icons.music_note),
                                    )
                                  : Image.network(
                                      track.coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: SportifyColors.card,
                                        child: const Icon(Icons.music_note),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(track.title),
                          subtitle: Text(track.artist),
                          trailing: IconButton(
                            onPressed: () => _openTrackOptions(track),
                            icon: const Icon(Icons.more_vert),
                          ),
                        );
                      },
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SportifySpacing.md,
                        SportifySpacing.lg,
                        SportifySpacing.md,
                        SportifySpacing.sm,
                      ),
                      child: Text(
                        'Recommended Songs',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_isLoadingRecommended && _recommended.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(SportifySpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  if (!_isLoadingRecommended && _recommended.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SportifySpacing.md,
                        ),
                        child: Text(
                          'No recommendations available right now.',
                          style: TextStyle(color: SportifyColors.textSecondary),
                        ),
                      ),
                    ),
                  if (_recommended.isNotEmpty)
                    SliverList.builder(
                      itemCount: _recommended.length,
                      itemBuilder: (context, index) {
                        final track = _recommended[index];
                        final isAdding = _addingTrackIds.contains(track.id);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: track.coverUrl.trim().isEmpty
                                  ? Container(
                                      color: SportifyColors.card,
                                      child: const Icon(Icons.music_note),
                                    )
                                  : Image.network(
                                      track.coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: SportifyColors.card,
                                        child: const Icon(Icons.music_note),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(track.title),
                          subtitle: Text(track.artist),
                          trailing: IconButton(
                            onPressed: isAdding
                                ? null
                                : () => _addRecommendedTrack(track),
                            icon: isAdding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_circle_outline),
                          ),
                        );
                      },
                    ),
                  if (canLoadMoreRecommended)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SportifySpacing.md,
                          SportifySpacing.md,
                          SportifySpacing.md,
                          SportifySpacing.md,
                        ),
                        child: OutlinedButton(
                          onPressed: _isLoadingRecommended
                              ? null
                              : () => _loadRecommended(
                                  reset: false,
                                  query: _playlist?.title,
                                ),
                          child: const Text('Load more recommendations'),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({required this.title, required this.ownerName});

  final String title;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final ownerLabel = ownerName.trim().isEmpty ? 'You' : ownerName.trim();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF4E4E4E),
            Color(0xFF1E1E1E),
            Color(0xFF121212),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SportifySpacing.md,
          kToolbarHeight + 28,
          SportifySpacing.md,
          SportifySpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 72,
                    color: SportifyColors.textSecondary,
                  ),
                ),
                const SizedBox(width: SportifySpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: SportifyColors.textPrimary,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            height: 1.02,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: SportifySpacing.sm),
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: SportifyColors.primary,
                              child: Text(
                                ownerLabel.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: SportifyColors.background,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: SportifySpacing.sm),
                            Expanded(
                              child: Text(
                                ownerLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SportifyColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton.tonal(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
            const SizedBox(height: SportifySpacing.md),
            const Row(
              children: <Widget>[
                Icon(Icons.public, color: SportifyColors.textSecondary),
                SizedBox(width: SportifySpacing.md),
                Icon(
                  Icons.person_add_alt_1,
                  color: SportifyColors.textSecondary,
                ),
                SizedBox(width: SportifySpacing.md),
                Icon(Icons.more_vert, color: SportifyColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackSearchPickerSheet extends StatefulWidget {
  const _TrackSearchPickerSheet({
    required this.playlistId,
    required this.onTrackAdded,
  });

  final String playlistId;
  final Future<void> Function() onTrackAdded;

  @override
  State<_TrackSearchPickerSheet> createState() =>
      _TrackSearchPickerSheetState();
}

class _TrackSearchPickerSheetState extends State<_TrackSearchPickerSheet> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  String? _nextCursor;
  String? _errorMessage;
  List<CatalogTrack> _items = const <CatalogTrack>[];
  final Set<String> _addingTrackIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _errorMessage = null;
      }
    });
    try {
      final query = _queryController.text.trim();
      final page = await context.read<CatalogRepository>().searchTracks(
        query: query.isEmpty ? null : query,
        limit: 20,
        cursor: reset ? null : _nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _nextCursor = page.nextCursor;
        if (reset) {
          _items = page.items;
        } else {
          final existing = _items.map((item) => item.id).toSet();
          _items = <CatalogTrack>[
            ..._items,
            ...page.items.where((item) => !existing.contains(item.id)),
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load tracks.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTrack(CatalogTrack track) async {
    if (_addingTrackIds.contains(track.id)) return;
    setState(() {
      _addingTrackIds.add(track.id);
    });
    try {
      await context.read<PlaylistRepository>().addTrackToPlaylist(
        playlistId: widget.playlistId,
        trackId: track.id,
      );
      await widget.onTrackAdded();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to playlist.')));
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Failed to add track.' : message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingTrackIds.remove(track.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLoadMore = _nextCursor != null && _nextCursor!.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: SportifySpacing.md,
          right: SportifySpacing.md,
          top: SportifySpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + SportifySpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Add to this playlist',
              style: TextStyle(
                color: SportifyColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: SportifySpacing.sm),
            TextField(
              controller: _queryController,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                hintText: 'Search songs',
                suffixIcon: IconButton(
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: SportifySpacing.sm),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: SportifySpacing.sm),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: SportifyColors.error),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _items.length + 1,
                itemBuilder: (context, index) {
                  if (index == _items.length) {
                    if (_isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(SportifySpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!canLoadMore) return const SizedBox(height: 8);
                    return Padding(
                      padding: const EdgeInsets.only(top: SportifySpacing.sm),
                      child: OutlinedButton(
                        onPressed: () => _load(reset: false),
                        child: const Text('Load more'),
                      ),
                    );
                  }
                  final track = _items[index];
                  final isAdding = _addingTrackIds.contains(track.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    trailing: IconButton(
                      onPressed: isAdding ? null : () => _addTrack(track),
                      icon: isAdding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_circle_outline),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
