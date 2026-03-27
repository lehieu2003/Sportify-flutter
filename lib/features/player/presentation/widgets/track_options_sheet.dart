import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/content_deeplink_navigator.dart';
import '../../../../core/share/share_content_service.dart';
import '../../../../core/theme/sportify_theme.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../library/data/repositories/library_repository.dart';
import '../../../library/presentation/viewmodels/library_view_model.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_picker_sheet.dart';
import '../viewmodels/player_view_model.dart';

class TrackOptionsData {
  const TrackOptionsData({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl = '',
    this.artistId,
  });

  final String trackId;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverUrl;
  final String? artistId;
}

Future<void> showTrackOptionsSheet(
  BuildContext context, {
  required TrackOptionsData track,
  ShareContentService? shareContentService,
}) async {
  final resolvedShareService =
      shareContentService ?? const ShareContentService();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      bool? isLiked;
      bool isLikeActionLoading = false;
      bool likedStatusRequested = false;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        minChildSize: 0.44,
        maxChildSize: 0.95,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) {
            if (!likedStatusRequested) {
              likedStatusRequested = true;
              _isTrackLiked(context, track.trackId).then((value) {
                if (!sheetContext.mounted) return;
                setSheetState(() {
                  isLiked = value;
                });
              });
            }
            final isTrackLikedNow = isLiked == true;
            final likedLabel = isTrackLikedNow
                ? 'Remove from your Liked Songs'
                : 'Save to your Liked Songs';

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SportifySpacing.md,
                  SportifySpacing.sm,
                  SportifySpacing.md,
                  SportifySpacing.md,
                ),
                child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SportifyColors.textDisabled,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: SportifySpacing.md),
                    _TrackHeader(track: track),
                    const Divider(color: SportifyColors.border),
                    _ActionTile(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _shareTrack(context, track, resolvedShareService);
                      },
                    ),
                    _ActionTile(
                      icon: Icons.playlist_add,
                      label: 'Add to playlist',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await showAddToPlaylistPickerSheet(
                          context,
                          trackId: track.trackId,
                        );
                      },
                    ),
                    _ActionTile(
                      icon: isTrackLikedNow
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: likedLabel,
                      enabled: !isLikeActionLoading,
                      onTap: () async {
                        if (isLikeActionLoading) return;
                        setSheetState(() {
                          isLikeActionLoading = true;
                        });
                        try {
                          final libraryVm = context.read<LibraryViewModel>();
                          final libraryRepository = context
                              .read<LibraryRepository>();
                          if (isTrackLikedNow) {
                            await libraryRepository.unsaveTrack(track.trackId);
                          } else {
                            await libraryRepository.saveTrack(track.trackId);
                          }
                          await libraryVm.loadSavedTracks();
                          if (!sheetContext.mounted) return;
                          setSheetState(() {
                            isLiked = !isTrackLikedNow;
                          });
                          _showInfo(
                            context,
                            isTrackLikedNow
                                ? 'Removed from your Liked Songs'
                                : 'Saved to your Liked Songs',
                          );
                        } catch (_) {
                          if (!sheetContext.mounted) return;
                          _showInfo(context, 'Failed to update Liked Songs.');
                        } finally {
                          if (sheetContext.mounted) {
                            setSheetState(() {
                              isLikeActionLoading = false;
                            });
                          }
                        }
                      },
                    ),
                    _ActionTile(
                      icon: Icons.queue_music,
                      label: 'Add to Queue',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _addToQueue(context, track);
                      },
                    ),
                    _ActionTile(
                      icon: Icons.person_search_outlined,
                      label: 'Go to artists',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _goToArtist(context, track);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Future<bool> _isTrackLiked(BuildContext context, String trackId) async {
  final repository = context.read<LibraryRepository>();
  final savedTracks = await repository.getSavedTracks(limit: 200);
  return savedTracks.any((item) => item.id == trackId);
}

Future<void> _goToArtist(BuildContext context, TrackOptionsData track) async {
  try {
    String artistId = (track.artistId ?? '').trim();
    if (artistId.isEmpty) {
      final catalogRepository = context.read<CatalogRepository>();
      final detail = await catalogRepository.getTrackById(track.trackId);
      artistId = detail.artistId.trim();
    }
    if (!context.mounted) return;
    if (artistId.isEmpty) {
      _showInfo(context, 'Artist is not available for this track.');
      return;
    }
    await ContentDeeplinkNavigator.open(
      context: context,
      type: 'artist',
      id: artistId,
      title: track.artist,
    );
  } catch (_) {
    if (!context.mounted) return;
    _showInfo(context, 'Failed to open artist.');
  }
}

Future<void> _addToQueue(BuildContext context, TrackOptionsData track) async {
  try {
    final playerVm = context.read<PlayerViewModel>();
    await playerVm.addToQueue(
      PlayerTrack(
        id: track.trackId,
        title: track.title,
        artist: track.artist,
        audioUrl: track.audioUrl,
        coverUrl: track.coverUrl,
      ),
    );
    if (!context.mounted) return;
    final error = playerVm.state.errorMessage;
    if (error != null && error.isNotEmpty) {
      _showInfo(context, error);
      return;
    }
    _showInfo(context, 'Added to queue');
  } catch (_) {
    if (!context.mounted) return;
    _showInfo(context, 'Failed to add track to queue.');
  }
}

Future<void> _shareTrack(
  BuildContext context,
  TrackOptionsData track,
  ShareContentService shareContentService,
) async {
  try {
    await shareContentService.shareTrack(
      trackId: track.trackId,
      title: track.title,
      artist: track.artist,
    );
  } catch (_) {
    if (!context.mounted) return;
    _showInfo(context, 'Failed to share track.');
  }
}

void _showInfo(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({required this.track});

  final TrackOptionsData track;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 52,
            height: 52,
            child: track.coverUrl.trim().isEmpty
                ? Container(
                    color: SportifyColors.card,
                    child: const Icon(
                      Icons.music_note,
                      color: SportifyColors.textSecondary,
                    ),
                  )
                : Image.network(
                    track.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: SportifyColors.card,
                      child: const Icon(
                        Icons.music_note,
                        color: SportifyColors.textSecondary,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: SportifySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SportifyColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: SportifyColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: SportifyColors.textPrimary),
      title: Text(
        label,
        style: const TextStyle(
          color: SportifyColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
