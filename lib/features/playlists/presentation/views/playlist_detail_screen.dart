import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
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
  String? _errorMessage;
  PlaylistDetail? _playlist;
  List<PlaylistTrack> _tracks = const <PlaylistTrack>[];

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
      setState(() {
        _playlist = results[0] as PlaylistDetail;
        _tracks = results[1] as List<PlaylistTrack>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load playlist.';
      });
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

  @override
  Widget build(BuildContext context) {
    final title = _playlist?.title ?? widget.initialTitle ?? 'Playlist';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
              child: ListView.builder(
                itemCount: _tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final subtitle = _playlist == null
                        ? ''
                        : '${_playlist!.trackCount} tracks';
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.md,
                        SportifySpacing.sm,
                      ),
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: SportifyColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  final track = _tracks[index - 1];
                  return ListTile(
                    onTap: () => _playTrack(index - 1),
                    leading: CircleAvatar(
                      backgroundColor: SportifyColors.card,
                      child: Text('${track.position}'),
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
            ),
    );
  }
}
