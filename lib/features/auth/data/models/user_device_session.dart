class UserDeviceSession {
  const UserDeviceSession({
    required this.id,
    required this.userAgent,
    required this.ip,
    required this.createdAt,
    required this.expiresAt,
    required this.isCurrent,
  });

  final String id;
  final String userAgent;
  final String ip;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isCurrent;

  factory UserDeviceSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = raw?.toString();
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return UserDeviceSession(
      id: (json['id'] ?? '').toString(),
      userAgent: (json['userAgent'] ?? '').toString(),
      ip: (json['ip'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      expiresAt: parseDate(json['expiresAt']),
      isCurrent: json['isCurrent'] == true,
    );
  }
}
