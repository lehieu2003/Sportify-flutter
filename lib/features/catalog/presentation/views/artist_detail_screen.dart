import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../library/data/models/library_models.dart';
import '../../../library/data/repositories/library_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import 'album_detail_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({
    required this.artistId,
    this.initialName,
    super.key,
  });

  final String artistId;
  final String? initialName;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  CatalogArtist? _artist;
  List<CatalogTrack> _topTracks = const <CatalogTrack>[];
  List<CatalogTrack> _albums = const <CatalogTrack>[];
  bool _isFollowing = false;
  bool _isTogglingFollow = false;
  bool _isLoadingMoreAlbums = false;
  String? _albumsNextCursor;

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
      final repository = context.read<CatalogRepository>();
      final libraryRepository = context.read<LibraryRepository>();
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getArtistById(widget.artistId),
        repository.getArtistTopTracks(widget.artistId, limit: 10),
        repository.getArtistAlbums(artistId: widget.artistId, limit: 20),
        libraryRepository.getFollowedArtists(limit: 100),
      ]);
      if (!mounted) return;
      final followed = (results[3] as CursorPage<LibraryArtist>).items
          .any((item) => item.id == widget.artistId);
      final albumPage = results[2] as CatalogTracksPage;
      setState(() {
        _artist = results[0] as CatalogArtist;
        _topTracks = results[1] as List<CatalogTrack>;
        _albums = albumPage.items;
        _albumsNextCursor = albumPage.nextCursor;
        _isFollowing = followed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load artist.';
      });
    }
  }

  Future<void> _playTopTrack(CatalogTrack track) async {
    final queue = _topTracks
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
    final startIndex = queue.indexWhere((it) => it.id == track.id);
    if (startIndex == -1) return;
    final vm = context.read<PlayerViewModel>();
    await vm.playQueue(queue, startIndex: startIndex);
    if (!mounted) return;
    final error = vm.state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;
    setState(() {
      _isTogglingFollow = true;
    });
    final repository = context.read<LibraryRepository>();
    try {
      if (_isFollowing) {
        await repository.unfollowArtist(widget.artistId);
      } else {
        await repository.followArtist(widget.artistId);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update follow state.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFollow = false;
        });
      }
    }
  }

  Future<void> _loadMoreAlbums() async {
    if (_isLoadingMoreAlbums || _albumsNextCursor == null || _albumsNextCursor!.isEmpty) {
      return;
    }
    setState(() {
      _isLoadingMoreAlbums = true;
    });
    try {
      final page = await context.read<CatalogRepository>().getArtistAlbums(
        artistId: widget.artistId,
        limit: 20,
        cursor: _albumsNextCursor,
      );
      if (!mounted) return;
      setState(() {
        _albums = <CatalogTrack>[..._albums, ...page.items];
        _albumsNextCursor = page.nextCursor;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load more albums.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreAlbums = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _artist?.name ?? widget.initialName ?? 'Artist';
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_errorMessage!, style: const TextStyle(color: SportifyColors.error)),
                  const SizedBox(height: SportifySpacing.sm),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: SportifyColors.background,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(title),
                    background: _artist?.imageUrl.trim().isNotEmpty == true
                        ? Image.network(
                            _artist!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(color: SportifyColors.surface),
                          )
                        : Container(color: SportifyColors.surface),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(SportifySpacing.md),
                    child: Row(
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _isTogglingFollow ? null : _toggleFollow,
                          icon: Icon(_isFollowing ? Icons.check : Icons.add),
                          label: Text(_isFollowing ? 'Following' : 'Follow'),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _topTracks.isEmpty
                              ? null
                              : () => _playTopTrack(_topTracks.first),
                          icon: const Icon(Icons.play_circle_fill, size: 56, color: SportifyColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      SportifySpacing.md,
                      SportifySpacing.sm,
                      SportifySpacing.md,
                      SportifySpacing.xs,
                    ),
                    child: Text(
                      'Popular',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: _topTracks.length,
                  itemBuilder: (context, index) {
                    final track = _topTracks[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 18,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: SportifyColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: track.coverUrl.trim().isEmpty
                                  ? Container(
                                      width: 28,
                                      height: 28,
                                      color: SportifyColors.card,
                                      child: const Icon(Icons.music_note, size: 14),
                                    )
                                  : Image.network(
                                      track.coverUrl,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 28,
                                        height: 28,
                                        color: SportifyColors.card,
                                        child: const Icon(Icons.music_note, size: 14),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _playTopTrack(track),
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      SportifySpacing.md,
                      SportifySpacing.md,
                      SportifySpacing.md,
                      SportifySpacing.xs,
                    ),
                    child: Text(
                      'Albums',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    final albumId = album.albumId ?? album.id;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.album_outlined)),
                      title: Text(album.albumTitle ?? album.title),
                      subtitle: Text(album.artist),
                      onTap: albumId.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AlbumDetailScreen(
                                    albumId: albumId,
                                    initialTitle: album.albumTitle ?? album.title,
                                  ),
                                ),
                              );
                            },
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
                    child: OutlinedButton(
                      onPressed: (_albumsNextCursor == null || _albumsNextCursor!.isEmpty || _isLoadingMoreAlbums)
                          ? null
                          : _loadMoreAlbums,
                      child: Text(_isLoadingMoreAlbums ? 'Loading...' : 'Load more albums'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }
}
