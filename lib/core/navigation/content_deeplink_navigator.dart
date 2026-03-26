import 'package:flutter/material.dart';

import '../../features/catalog/presentation/views/album_detail_screen.dart';
import '../../features/catalog/presentation/views/artist_detail_screen.dart';
import '../../features/playlists/presentation/views/playlist_detail_screen.dart';

typedef GenreDeeplinkHandler = Future<void> Function(String genreSlug, String title);

class ContentDeeplinkNavigator {
  static Future<void> open({
    required BuildContext context,
    required String type,
    required String id,
    String? title,
    GenreDeeplinkHandler? onGenre,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    final normalizedId = id.trim();
    final normalizedTitle = (title ?? '').trim();
    if (normalizedId.isEmpty) return;

    if (normalizedType == 'album') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AlbumDetailScreen(
            albumId: normalizedId,
            initialTitle: normalizedTitle.isEmpty ? null : normalizedTitle,
          ),
        ),
      );
      return;
    }

    if (normalizedType == 'artist') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArtistDetailScreen(
            artistId: normalizedId,
            initialName: normalizedTitle.isEmpty ? null : normalizedTitle,
          ),
        ),
      );
      return;
    }

    if (normalizedType == 'playlist') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistDetailScreen(
            playlistId: normalizedId,
            initialTitle: normalizedTitle.isEmpty ? null : normalizedTitle,
          ),
        ),
      );
      return;
    }

    if (normalizedType == 'genre' && onGenre != null) {
      await onGenre(normalizedId, normalizedTitle);
    }
  }
}
