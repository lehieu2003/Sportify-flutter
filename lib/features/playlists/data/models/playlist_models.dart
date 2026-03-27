import '../../../../core/config/api_config.dart';

class PlaylistDetail {
  const PlaylistDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.isPublic,
    required this.trackCount,
    this.ownerName = '',
    this.memberRole = '',
    this.isCollaborative = false,
  });

  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final bool isPublic;
  final int trackCount;
  final String ownerName;
  final String memberRole;
  final bool isCollaborative;

  factory PlaylistDetail.fromJson(Map<String, dynamic> json) {
    final rawTrackCount = json['trackCount'] ?? json['track_count'];
    final parsedTrackCount = switch (rawTrackCount) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    return PlaylistDetail(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl(
        (json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      isPublic: json['isPublic'] == true || json['is_public'] == true,
      trackCount: parsedTrackCount,
      ownerName: (json['ownerName'] ?? json['owner_name'] ?? '').toString(),
      memberRole: (json['memberRole'] ?? json['member_role'] ?? '').toString(),
      isCollaborative:
          json['isCollaborative'] == true || json['is_collaborative'] == true,
    );
  }
}

class PlaylistMember {
  const PlaylistMember({
    required this.userId,
    required this.fullName,
    required this.imageUrl,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String imageUrl;
  final String role;
  final String joinedAt;

  bool get isOwner => role == 'owner';

  factory PlaylistMember.fromJson(Map<String, dynamic> json) {
    return PlaylistMember(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      imageUrl: ApiConfig.resolveUrl(
        (json['imageUrl'] ?? json['image_url'])?.toString(),
      ),
      role: (json['role'] ?? 'viewer').toString(),
      joinedAt: (json['joinedAt'] ?? json['joined_at'] ?? '').toString(),
    );
  }
}

class PlaylistInvite {
  const PlaylistInvite({
    required this.inviteId,
    required this.playlistId,
    required this.inviteCode,
    required this.usedCount,
    this.expiresAt,
    this.maxUses,
  });

  final String inviteId;
  final String playlistId;
  final String inviteCode;
  final int usedCount;
  final String? expiresAt;
  final int? maxUses;

  factory PlaylistInvite.fromJson(Map<String, dynamic> json) {
    final maxUsesRaw = json['maxUses'] ?? json['max_uses'];
    final usedRaw = json['usedCount'] ?? json['used_count'];
    return PlaylistInvite(
      inviteId: (json['inviteId'] ?? json['invite_id'] ?? '').toString(),
      playlistId: (json['playlistId'] ?? json['playlist_id'] ?? '').toString(),
      inviteCode: (json['inviteCode'] ?? json['invite_code'] ?? '').toString(),
      usedCount: switch (usedRaw) {
        int value => value,
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      expiresAt: (json['expiresAt'] ?? json['expires_at'])?.toString(),
      maxUses: switch (maxUsesRaw) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      },
    );
  }
}

class JoinPlaylistResult {
  const JoinPlaylistResult({
    required this.playlistId,
    required this.joined,
    required this.role,
  });

  final String playlistId;
  final bool joined;
  final String role;

  factory JoinPlaylistResult.fromJson(Map<String, dynamic> json) {
    return JoinPlaylistResult(
      playlistId: (json['playlistId'] ?? json['playlist_id'] ?? '').toString(),
      joined: json['joined'] == true,
      role: (json['role'] ?? '').toString(),
    );
  }
}

class PlaylistTrack {
  const PlaylistTrack({
    required this.trackId,
    required this.position,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.durationMs,
  });

  final String trackId;
  final int position;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int durationMs;

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
    final rawPosition = json['position'];
    final position = switch (rawPosition) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    final rawDuration = json['durationMs'] ?? json['duration_ms'];
    final durationMs = switch (rawDuration) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    return PlaylistTrack(
      trackId: (json['trackId'] ?? json['track_id'] ?? '').toString(),
      position: position,
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? json['artist_name'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl(
        (json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      audioUrl: ApiConfig.resolveUrl(
        (json['audioUrl'] ?? json['audio_url'])?.toString(),
      ),
      durationMs: durationMs,
    );
  }
}
