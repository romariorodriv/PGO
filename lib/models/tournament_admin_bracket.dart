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

  List<String> get stageKeys => stages.keys.toList()
    ..sort((left, right) => _stageRank(left).compareTo(_stageRank(right)));

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
        for (final key in stageJson.keys) key: parseStage(key),
      },
    );
  }

  static int _stageRank(String stage) {
    if (stage == 'final') return 999;
    if (stage.startsWith('juego-')) {
      final number = int.tryParse(stage.replaceFirst('juego-', ''));
      return number ?? 900;
    }
    const legacy = {
      'octavos': 1,
      'cuartos': 2,
      'semis': 3,
    };
    return legacy[stage] ?? 500;
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
    required this.startedAt,
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
  final DateTime? startedAt;
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
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      status: json['status'] as String? ?? 'PENDING',
      score: json['score'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
    );
  }
}
