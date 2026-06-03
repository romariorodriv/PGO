class CommunityUser {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? category;
  final int rankingPosition;
  final String? preferredClub;
  final String? friendshipId;
  final String? friendshipStatus;
  final bool? isActive;
  final bool? allowsMatchInvites;
  final bool? hasScheduleConflict;

  const CommunityUser({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.category,
    required this.rankingPosition,
    required this.preferredClub,
    required this.friendshipId,
    required this.friendshipStatus,
    this.isActive,
    this.allowsMatchInvites,
    this.hasScheduleConflict,
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
      friendshipId: json['friendshipId'] as String?,
      friendshipStatus: json['friendshipStatus'] as String?,
      isActive: json['isActive'] as bool?,
      allowsMatchInvites:
          json['allowsMatchInvites'] as bool? ?? json['allowInvites'] as bool?,
      hasScheduleConflict: json['hasScheduleConflict'] as bool?,
    );
  }
}
