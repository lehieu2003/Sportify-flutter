import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';
import '../../../player/presentation/widgets/track_options_sheet.dart';

class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({
    required this.albumId,
    this.initialTitle,
    super.key,
  });

  final String albumId;
  final String? initialTitle;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  CatalogAlbum? _album;
  List<CatalogTrack> _tracks = const <CatalogTrack>[];

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
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getAlbumById(widget.albumId),
        repository.getAlbumTracks(widget.albumId),
      ]);
      if (!mounted) return;
      setState(() {
        _album = results[0] as CatalogAlbum;
        _tracks = results[1] as List<CatalogTrack>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load album.';
      });
    }
  }

  List<PlayerTrack> _buildQueue() {
    return _tracks
        .where((track) => track.audioUrl.trim().isNotEmpty)
        .map(
          (track) => PlayerTrack(
            id: track.id,
            title: track.title,
            artist: track.artist,
            audioUrl: track.audioUrl,
            coverUrl: track.coverUrl,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _playAt(int index) async {
    final queue = _buildQueue();
    final track = _tracks[index];
    final startIndex = queue.indexWhere((item) => item.id == track.id);
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

  Future<void> _playAll() async {
    final queue = _buildQueue();
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album has no playable tracks.')),
      );
      return;
    }
    final playerVm = context.read<PlayerViewModel>();
    await playerVm.playQueue(queue, startIndex: 0);
    if (!mounted) return;
    final error = playerVm.state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
  Widget build(BuildContext context) {
    final title = _album?.title ?? widget.initialTitle ?? 'Album';
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: SportifyColors.error),
                  ),
                  const SizedBox(height: SportifySpacing.sm),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _tracks.isEmpty
          ? const Center(child: Text('No tracks in this album yet.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  SportifySpacing.md,
                  SportifySpacing.md,
                  SportifySpacing.md,
                  88,
                ),
                itemCount: _tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final coverUrl = _album?.coverUrl ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: coverUrl.trim().isEmpty
                                ? Container(
                                    width: 280,
                                    height: 280,
                                    color: SportifyColors.card,
                                    child: const Icon(Icons.album, size: 120),
                                  )
                                : Image.network(
                                    coverUrl,
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 280,
                                      height: 280,
                                      color: SportifyColors.card,
                                      child: const Icon(Icons.album, size: 120),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: SportifySpacing.lg),
                        Text(
                          _album?.title ?? '',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            height: 1.02,
                            color: SportifyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SportifySpacing.sm),
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: SportifyColors.card,
                              child: Text(
                                (_album?.artist.isNotEmpty == true)
                                    ? _album!.artist
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'A',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: SportifySpacing.sm),
                            Text(
                              _album?.artist ?? 'Unknown artist',
                              style: const TextStyle(
                                color: SportifyColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SportifySpacing.sm),
                        Text(
                          _buildMetaLine(),
                          style: const TextStyle(
                            color: SportifyColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: SportifySpacing.md),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle,
                              color: SportifyColors.primary,
                              size: 30,
                            ),
                            const SizedBox(width: SportifySpacing.md),
                            const Icon(
                              Icons.download_for_offline_outlined,
                              size: 30,
                            ),
                            const SizedBox(width: SportifySpacing.md),
                            const Icon(Icons.more_horiz, size: 30),
                            const Spacer(),
                            Container(
                              width: 62,
                              height: 62,
                              decoration: const BoxDecoration(
                                color: SportifyColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _playAll,
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: SportifyColors.background,
                                  size: 34,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SportifySpacing.md),
                      ],
                    );
                  }

                  final track = _tracks[index - 1];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _playAt(index - 1),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: SportifyColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(track.artist),
                    trailing: IconButton(
                      onPressed: () => _openTrackOptions(track),
                      icon: const Icon(Icons.more_vert),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _buildMetaLine() {
    final releaseDate = _album?.releaseDate;
    if (releaseDate == null || releaseDate.isEmpty) {
      return '${_tracks.length} tracks';
    }
    final parsed = DateTime.tryParse(releaseDate);
    if (parsed == null) {
      return '${_tracks.length} tracks';
    }
    return 'Ep • ${parsed.day} thg ${parsed.month} ${parsed.year}';
  }
}
