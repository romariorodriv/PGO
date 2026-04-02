class MatchRecord {
  final String id;
  final String createdById;
  final String clubName;
  final DateTime playedAt;
  final String matchType;
  final String status;
  final String? description;
  final int? winnerTeam;
  final List<Map<String, dynamic>> games;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final List<MatchParticipantRecord> participants;

  const MatchRecord({
    required this.id,
    required this.createdById,
    required this.clubName,
    required this.playedAt,
    required this.matchType,
    required this.status,
    required this.description,
    required this.winnerTeam,
    required this.games,
    required this.createdAt,
    required this.updatedAt,
    required this.photoUrl,
    required this.participants,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      id: json['id'] as String,
      createdById: json['createdById'] as String,
      clubName: json['clubName'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      matchType: json['matchType'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      winnerTeam: (json['winnerTeam'] as num?)?.toInt(),
      games: ((json['games'] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      photoUrl: json['photoUrl'] as String?,
      participants: ((json['participants'] as List?) ?? const [])
          .map(
            (item) => MatchParticipantRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class MatchParticipantRecord {
  final String id;
  final String userId;
  final int slot;
  final int team;
  final MatchParticipantUserRecord? user;

  const MatchParticipantRecord({
    required this.id,
    required this.userId,
    required this.slot,
    required this.team,
    required this.user,
  });

  factory MatchParticipantRecord.fromJson(Map<String, dynamic> json) {
    return MatchParticipantRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      slot: (json['slot'] as num).toInt(),
      team: (json['team'] as num).toInt(),
      user: json['user'] is Map<String, dynamic>
          ? MatchParticipantUserRecord.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class MatchParticipantUserRecord {
  final String id;
  final String name;
  final String? photoUrl;
  final String? category;

  const MatchParticipantUserRecord({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.category,
  });

  factory MatchParticipantUserRecord.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return MatchParticipantUserRecord(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      photoUrl: profile?['photoUrl'] as String?,
      category: profile?['category'] as String?,
    );
  }
}
