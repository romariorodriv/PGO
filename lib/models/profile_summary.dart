class ProfileSummary {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int experiencePoints;
  final String? category;
  final String? preferredClub;
  final String? preferredSide;
  final String? racketModel;
  final String? experienceLevel;
  final int rankingPosition;
  final int matchesPlayed;
  final int wins;
  final double winRate;
  final int weeklyStreak;
  final int friendsCount;
  final int followersCount;
  final int followingCount;
  final int socialNotificationsCount;
  final bool? hasSeenHomeGuide;
  final bool? hasCompletedInitialOnboarding;
  final String? categorySuggested;
  final String? categoryPreliminary;
  final String? categoryMaxApplied;
  final int? categoryScore;
  final Map<String, dynamic>? categoryQuizAnswers;
  final bool? categoryIsProvisional;
  final String? categoryOrigin;
  final List<Map<String, dynamic>> matchHistory;

  const ProfileSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.experiencePoints,
    required this.category,
    required this.preferredClub,
    required this.preferredSide,
    required this.racketModel,
    required this.experienceLevel,
    required this.rankingPosition,
    required this.matchesPlayed,
    required this.wins,
    required this.winRate,
    required this.weeklyStreak,
    required this.friendsCount,
    required this.followersCount,
    required this.followingCount,
    required this.socialNotificationsCount,
    this.hasSeenHomeGuide,
    this.hasCompletedInitialOnboarding,
    this.categorySuggested,
    this.categoryPreliminary,
    this.categoryMaxApplied,
    this.categoryScore,
    this.categoryQuizAnswers,
    this.categoryIsProvisional,
    this.categoryOrigin,
    required this.matchHistory,
  });

  ProfileSummary copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    int? experiencePoints,
    String? category,
    String? preferredClub,
    String? preferredSide,
    String? racketModel,
    String? experienceLevel,
    int? rankingPosition,
    int? matchesPlayed,
    int? wins,
    double? winRate,
    int? weeklyStreak,
    int? friendsCount,
    int? followersCount,
    int? followingCount,
    int? socialNotificationsCount,
    bool? hasSeenHomeGuide,
    bool? hasCompletedInitialOnboarding,
    String? categorySuggested,
    String? categoryPreliminary,
    String? categoryMaxApplied,
    int? categoryScore,
    Map<String, dynamic>? categoryQuizAnswers,
    bool? categoryIsProvisional,
    String? categoryOrigin,
    List<Map<String, dynamic>>? matchHistory,
  }) {
    return ProfileSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      category: category ?? this.category,
      preferredClub: preferredClub ?? this.preferredClub,
      preferredSide: preferredSide ?? this.preferredSide,
      racketModel: racketModel ?? this.racketModel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      winRate: winRate ?? this.winRate,
      weeklyStreak: weeklyStreak ?? this.weeklyStreak,
      friendsCount: friendsCount ?? this.friendsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      socialNotificationsCount:
          socialNotificationsCount ?? this.socialNotificationsCount,
      hasSeenHomeGuide: hasSeenHomeGuide ?? this.hasSeenHomeGuide,
      hasCompletedInitialOnboarding:
          hasCompletedInitialOnboarding ?? this.hasCompletedInitialOnboarding,
      categorySuggested: categorySuggested ?? this.categorySuggested,
      categoryPreliminary: categoryPreliminary ?? this.categoryPreliminary,
      categoryMaxApplied: categoryMaxApplied ?? this.categoryMaxApplied,
      categoryScore: categoryScore ?? this.categoryScore,
      categoryQuizAnswers: categoryQuizAnswers ?? this.categoryQuizAnswers,
      categoryIsProvisional:
          categoryIsProvisional ?? this.categoryIsProvisional,
      categoryOrigin: categoryOrigin ?? this.categoryOrigin,
      matchHistory: matchHistory ?? this.matchHistory,
    );
  }

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      experiencePoints: (json['experiencePoints'] as num?)?.toInt() ?? 0,
      category: json['category'] as String?,
      preferredClub: json['preferredClub'] as String?,
      preferredSide: json['preferredSide'] as String?,
      racketModel: json['racketModel'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      rankingPosition: (json['rankingPosition'] as num?)?.toInt() ?? 0,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      weeklyStreak: (json['weeklyStreak'] as num?)?.toInt() ?? 0,
      friendsCount: (json['friendsCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      socialNotificationsCount:
          (json['socialNotificationsCount'] as num?)?.toInt() ?? 0,
      hasSeenHomeGuide: json['hasSeenHomeGuide'] as bool?,
      hasCompletedInitialOnboarding:
          json['hasCompletedInitialOnboarding'] as bool?,
      categorySuggested: json['categorySuggested'] as String?,
      categoryPreliminary: json['categoryPreliminary'] as String?,
      categoryMaxApplied: json['categoryMaxApplied'] as String?,
      categoryScore: (json['categoryScore'] as num?)?.toInt(),
      categoryQuizAnswers: json['categoryQuizAnswers'] is Map
          ? Map<String, dynamic>.from(json['categoryQuizAnswers'] as Map)
          : null,
      categoryIsProvisional: json['categoryIsProvisional'] as bool?,
      categoryOrigin: json['categoryOrigin'] as String?,
      matchHistory: ((json['matchHistory'] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }
}
