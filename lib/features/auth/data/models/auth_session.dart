import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.message,
    this.sessionId,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final String message;
  final String? sessionId;
  String get token => accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = (json['accessToken'] ?? '').toString();
    final refreshToken = (json['refreshToken'] ?? '').toString();
    final message = (json['message'] ?? '').toString();
    final sessionId = json['sessionId']?.toString();
    final rawUser = json['user'];
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(
        rawUser is Map<String, dynamic> ? rawUser : <String, dynamic>{},
      ),
      message: message,
      sessionId: sessionId,
    );
  }
}
