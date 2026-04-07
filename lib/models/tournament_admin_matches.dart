class TournamentAdminMatchesData {
  const TournamentAdminMatchesData({
    required this.totalMatches,
    required this.completedMatches,
    required this.liveMatches,
    required this.matches,
  });

  final int totalMatches;
  final int completedMatches;
  final int liveMatches;
  final List<TournamentAdminMatch> matches;

  factory TournamentAdminMatchesData.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? const {};
    final rawMatches = (json['matches'] as List<dynamic>?) ?? const [];

    return TournamentAdminMatchesData(
      totalMatches: (summary['totalMatches'] as num?)?.toInt() ?? 0,
      completedMatches: (summary['completedMatches'] as num?)?.toInt() ?? 0,
      liveMatches: (summary['liveMatches'] as num?)?.toInt() ?? 0,
      matches: rawMatches
          .map(
            (item) => TournamentAdminMatch.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class TournamentAdminMatch {
  const TournamentAdminMatch({
    required this.id,
    required this.courtLabel,
    required this.stageLabel,
    required this.teamOne,
    required this.teamTwo,
    required this.scheduledAt,
    required this.status,
    required this.score,
    required this.winnerLabel,
  });

  final String id;
  final String courtLabel;
  final String stageLabel;
  final String teamOne;
  final String teamTwo;
  final DateTime scheduledAt;
  final String status;
  final String? score;
  final String? winnerLabel;

  factory TournamentAdminMatch.fromJson(Map<String, dynamic> json) {
    return TournamentAdminMatch(
      id: json['id'] as String? ?? '',
      courtLabel: json['courtLabel'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      teamOne: json['teamOne'] as String? ?? '',
      teamTwo: json['teamTwo'] as String? ?? '',
      scheduledAt: DateTime.parse(
        json['scheduledAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] as String? ?? 'PENDING',
      score: json['score'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
    );
  }
}
