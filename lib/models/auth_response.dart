class AuthResponse {
  final String accessToken;
  final Map<String, dynamic> user;

  const AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }
}
