import '../../../../core/config/api_config.dart';

class JamParticipant {
  const JamParticipant({
    required this.userId,
    required this.fullName,
    required this.imageUrl,
    required this.role,
    required this.isActive,
    required this.joinedAt,
    this.leftAt,
  });

  final String userId;
  final String fullName;
  final String imageUrl;
  final String role;
  final bool isActive;
  final String joinedAt;
  final String? leftAt;

  factory JamParticipant.fromJson(Map<String, dynamic> json) {
    return JamParticipant(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      imageUrl: ApiConfig.resolveUrl(
        (json['imageUrl'] ?? json['image_url'])?.toString(),
      ),
      role: (json['role'] ?? 'listener').toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      joinedAt: (json['joinedAt'] ?? json['joined_at'] ?? '').toString(),
      leftAt: (json['leftAt'] ?? json['left_at'])?.toString(),
    );
  }
}

class JamQueueItem {
  const JamQueueItem({
    required this.position,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
  });

  final int position;
  final String trackId;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;

  factory JamQueueItem.fromJson(Map<String, dynamic> json) {
    final rawPosition = json['position'];
    final position = switch (rawPosition) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    return JamQueueItem(
      position: position,
      trackId: (json['trackId'] ?? json['track_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      coverUrl: ApiConfig.resolveUrl(
        (json['coverUrl'] ?? json['cover_url'])?.toString(),
      ),
      audioUrl: ApiConfig.resolveUrl(
        (json['audioUrl'] ?? json['audio_url'])?.toString(),
      ),
    );
  }
}

class JamQueueSnapshot {
  const JamQueueSnapshot({
    required this.currentIndex,
    required this.currentTrackId,
    required this.items,
  });

  final int currentIndex;
  final String? currentTrackId;
  final List<JamQueueItem> items;

  factory JamQueueSnapshot.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['currentIndex'] ?? json['current_index'];
    final currentIndex = switch (rawIndex) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
    final rawItems = (json['items'] as List<dynamic>? ?? const <dynamic>[]);
    return JamQueueSnapshot(
      currentIndex: currentIndex,
      currentTrackId: (json['currentTrackId'] ?? json['current_track_id'])
          ?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(JamQueueItem.fromJson)
          .toList(growable: false),
    );
  }
}

class JamSession {
  const JamSession({
    required this.id,
    required this.hostUserId,
    required this.title,
    required this.inviteCode,
    required this.status,
    required this.isHost,
    required this.queue,
    required this.participants,
    required this.updatedAt,
  });

  final String id;
  final String hostUserId;
  final String title;
  final String inviteCode;
  final String status;
  final bool isHost;
  final JamQueueSnapshot queue;
  final List<JamParticipant> participants;
  final String updatedAt;

  bool get isActive => status == 'active';

  factory JamSession.fromJson(Map<String, dynamic> json) {
    final participants =
        (json['participants'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(JamParticipant.fromJson)
            .toList(growable: false);
    final queue = JamQueueSnapshot.fromJson(
      (json['queue'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );

    return JamSession(
      id: (json['id'] ?? '').toString(),
      hostUserId: (json['hostUserId'] ?? json['host_user_id'] ?? '').toString(),
      title: (json['title'] ?? 'Jam Session').toString(),
      inviteCode: (json['inviteCode'] ?? json['invite_code'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      isHost: json['isHost'] == true || json['is_host'] == true,
      queue: queue,
      participants: participants,
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
    );
  }
}
