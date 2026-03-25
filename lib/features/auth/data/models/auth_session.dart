import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.message,
  });

  final String token;
  final AuthUser user;
  final String message;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      message: (json['message'] as String?) ?? '',
    );
  }
}
