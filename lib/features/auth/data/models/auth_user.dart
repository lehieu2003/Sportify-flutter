class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.imageUrl,
  });

  final int id;
  final String fullName;
  final String email;
  final String imageUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullName: (json['full_name'] ?? json['fullName']) as String,
      email: json['email'] as String,
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'email': email,
      'image_url': imageUrl,
    };
  }
}
