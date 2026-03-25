class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    this.code,
  });

  final String message;
  final int statusCode;
  final String? code;

  @override
  String toString() => message;
}
