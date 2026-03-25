class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.imageUrl,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final String imageUrl;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final fullName = (json['full_name'] ?? json['fullName'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final imageUrl = (json['image_url'] ?? json['imageUrl'] ?? '').toString();
    final role = (json['role'] ?? 'user').toString();
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: fullName,
      email: email,
      imageUrl: imageUrl,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'email': email,
      'image_url': imageUrl,
      'role': role,
    };
  }
}
