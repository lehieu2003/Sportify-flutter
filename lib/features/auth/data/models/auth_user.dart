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
    final rawId = json['id'];
    final parsedId = switch (rawId) {
      int value => value,
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    return AuthUser(
      id: parsedId,
      fullName: (json['full_name'] ?? json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
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
