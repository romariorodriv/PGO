class TournamentAdminBracketData {
  const TournamentAdminBracketData({
    required this.totalMatches,
    required this.completedMatches,
    required this.liveMatches,
    required this.stages,
  });

  final int totalMatches;
  final int completedMatches;
  final int liveMatches;
  final Map<String, List<TournamentAdminBracketMatch>> stages;

  factory TournamentAdminBracketData.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? const {};
    final stageJson = (json['stages'] as Map<String, dynamic>?) ?? const {};

    List<TournamentAdminBracketMatch> parseStage(String key) {
      final raw = (stageJson[key] as List<dynamic>?) ?? const [];
      return raw
          .map(
            (item) => TournamentAdminBracketMatch.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    return TournamentAdminBracketData(
      totalMatches: (summary['totalMatches'] as num?)?.toInt() ?? 0,
      completedMatches: (summary['completedMatches'] as num?)?.toInt() ?? 0,
      liveMatches: (summary['liveMatches'] as num?)?.toInt() ?? 0,
      stages: {
        'octavos': parseStage('octavos'),
        'cuartos': parseStage('cuartos'),
        'semis': parseStage('semis'),
        'final': parseStage('final'),
      },
    );
  }
}

class TournamentAdminBracketMatch {
  const TournamentAdminBracketMatch({
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

  factory TournamentAdminBracketMatch.fromJson(Map<String, dynamic> json) {
    return TournamentAdminBracketMatch(
      id: json['id'] as String? ?? '',
      courtLabel: json['courtLabel'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      teamOne: json['teamOne'] as String? ?? 'TBD',
      teamTwo: json['teamTwo'] as String? ?? 'TBD',
      scheduledAt: DateTime.parse(
        json['scheduledAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      status: json['status'] as String? ?? 'PENDING',
      score: json['score'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
    );
  }
}
