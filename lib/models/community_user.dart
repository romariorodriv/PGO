class CommunityUser {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? category;
  final int rankingPosition;
  final String? preferredClub;

  const CommunityUser({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.category,
    required this.rankingPosition,
    required this.preferredClub,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return CommunityUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      photoUrl: profile?['photoUrl'] as String?,
      category: profile?['category'] as String?,
      rankingPosition: (profile?['rankingPosition'] as num?)?.toInt() ?? 0,
      preferredClub: profile?['preferredClub'] as String?,
    );
  }
}
