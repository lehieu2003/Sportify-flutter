import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/repositories/playlist_repository.dart';

class _PlaylistOption {
  const _PlaylistOption({
    required this.id,
    required this.title,
    required this.ownerUserId,
  });

  final String id;
  final String title;
  final String ownerUserId;
}

Future<void> showAddToPlaylistPickerSheet(
  BuildContext context, {
  required String trackId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddToPlaylistPickerBody(trackId: trackId),
  );
}

class _AddToPlaylistPickerBody extends StatefulWidget {
  const _AddToPlaylistPickerBody({required this.trackId});

  final String trackId;

  @override
  State<_AddToPlaylistPickerBody> createState() =>
      _AddToPlaylistPickerBodyState();
}

class _AddToPlaylistPickerBodyState extends State<_AddToPlaylistPickerBody> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  List<_PlaylistOption> _allPlaylists = const <_PlaylistOption>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await context.read<PlaylistRepository>().listPlaylists(
        limit: 150,
      );
      if (!mounted) return;
      final mapped = raw
          .map((item) {
            final id = (item['id'] ?? '').toString().trim();
            if (id.isEmpty) return null;
            return _PlaylistOption(
              id: id,
              title: (item['title'] ?? 'Untitled playlist').toString(),
              ownerUserId: (item['ownerUserId'] ?? '').toString(),
            );
          })
          .whereType<_PlaylistOption>()
          .toList(growable: false);
      setState(() {
        _allPlaylists = mapped;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load playlists.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToPlaylist(_PlaylistOption playlist) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await context.read<PlaylistRepository>().addTrackToPlaylist(
        playlistId: playlist.id,
        trackId: widget.trackId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added to "${playlist.title}"')));
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Failed to add track to playlist.' : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = '';
    try {
      currentUserId = context.read<AuthViewModel>().state.user?.id ?? '';
    } catch (_) {
      currentUserId = '';
    }
    final query = _searchController.text.trim().toLowerCase();
    final visiblePlaylists = query.isEmpty
        ? _allPlaylists
        : _allPlaylists
              .where((item) => item.title.toLowerCase().contains(query))
              .toList(growable: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: SportifySpacing.md,
          right: SportifySpacing.md,
          top: SportifySpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + SportifySpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Add to playlist',
                style: TextStyle(
                  color: SportifyColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: SportifySpacing.sm),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Find playlist',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: SportifySpacing.sm),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: SportifyColors.error),
                    ),
                  ),
                )
              else if (visiblePlaylists.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No playlists found.',
                      style: TextStyle(color: SportifyColors.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: visiblePlaylists.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: SportifyColors.border, height: 1),
                    itemBuilder: (_, index) {
                      final playlist = visiblePlaylists[index];
                      final byCurrentUser =
                          playlist.ownerUserId == currentUserId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: SportifyColors.card,
                          child: Icon(Icons.queue_music_outlined),
                        ),
                        title: Text(playlist.title),
                        subtitle: Text(
                          byCurrentUser ? 'Your playlist' : 'Playlist',
                          style: const TextStyle(
                            color: SportifyColors.textSecondary,
                          ),
                        ),
                        enabled: !_isSubmitting,
                        onTap: () => _addToPlaylist(playlist),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
