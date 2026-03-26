import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../data/models/catalog_models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../../player/presentation/viewmodels/player_view_model.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _album?.title ?? widget.initialTitle ?? 'Album';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
          : _tracks.isEmpty
          ? const Center(child: Text('No tracks in this album yet.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.sm,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${_tracks.length} tracks • ${_album?.artist ?? ''}',
                              style: const TextStyle(color: SportifyColors.textSecondary),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _playAll,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play all'),
                          ),
                        ],
                      ),
                    );
                  }
                  final track = _tracks[index - 1];
                  return ListTile(
                    onTap: () => _playAt(index - 1),
                    leading: CircleAvatar(
                      backgroundColor: SportifyColors.card,
                      child: Text('$index'),
                    ),
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    trailing: const Icon(Icons.play_arrow),
                  );
                },
              ),
            ),
    );
  }
}
