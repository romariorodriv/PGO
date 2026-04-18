class TournamentAlertsResponse {
  const TournamentAlertsResponse({
    required this.alerts,
  });

  final List<TournamentAlert> alerts;

  factory TournamentAlertsResponse.fromJson(Map<String, dynamic> json) {
    final rawAlerts = (json['alerts'] as List<dynamic>?) ?? const [];
    return TournamentAlertsResponse(
      alerts: rawAlerts
          .map(
            (item) => TournamentAlert.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class TournamentAlert {
  const TournamentAlert({
    required this.eventId,
    required this.type,
    required this.occurredAt,
    required this.tournament,
    required this.match,
    required this.nextMatch,
    required this.champions,
    required this.runnersUp,
    required this.userResult,
  });

  final String eventId;
  final String type;
  final DateTime occurredAt;
  final TournamentAlertTournament tournament;
  final TournamentAlertMatch match;
  final TournamentAlertMatch? nextMatch;
  final List<String> champions;
  final List<String> runnersUp;
  final String? userResult;

  factory TournamentAlert.fromJson(Map<String, dynamic> json) {
    return TournamentAlert(
      eventId: json['eventId'] as String? ?? '',
      type: json['type'] as String? ?? 'BRACKET_READY',
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      tournament: TournamentAlertTournament.fromJson(
        (json['tournament'] as Map<String, dynamic>?) ?? const {},
      ),
      match: TournamentAlertMatch.fromJson(
        (json['match'] as Map<String, dynamic>?) ?? const {},
      ),
      nextMatch: (json['nextMatch'] as Map<String, dynamic>?) != null
          ? TournamentAlertMatch.fromJson(
              json['nextMatch'] as Map<String, dynamic>,
            )
          : null,
      champions: ((json['champions'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      runnersUp: ((json['runnersUp'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      userResult: json['userResult'] as String?,
    );
  }
}

class TournamentAlertTournament {
  const TournamentAlertTournament({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.startsAt,
    required this.registrationsCount,
  });

  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime startsAt;
  final int registrationsCount;

  factory TournamentAlertTournament.fromJson(Map<String, dynamic> json) {
    return TournamentAlertTournament(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Torneo PGO',
      category: json['category'] as String? ?? '4TA',
      location: json['location'] as String? ?? '',
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ??
          DateTime.now(),
      registrationsCount: (json['registrationsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TournamentAlertMatch {
  const TournamentAlertMatch({
    required this.id,
    required this.courtLabel,
    required this.stageLabel,
    required this.teamOne,
    required this.teamTwo,
    required this.status,
    required this.score,
    required this.winnerLabel,
    required this.scheduledAt,
    required this.updatedAt,
  });

  final String id;
  final String courtLabel;
  final String stageLabel;
  final String teamOne;
  final String teamTwo;
  final String status;
  final String? score;
  final String? winnerLabel;
  final DateTime scheduledAt;
  final DateTime updatedAt;

  factory TournamentAlertMatch.fromJson(Map<String, dynamic> json) {
    return TournamentAlertMatch(
      id: json['id'] as String? ?? '',
      courtLabel: json['courtLabel'] as String? ?? 'CANCHA 1',
      stageLabel: json['stageLabel'] as String? ?? '',
      teamOne: json['teamOne'] as String? ?? '',
      teamTwo: json['teamTwo'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      score: json['score'] as String?,
      winnerLabel: json['winnerLabel'] as String?,
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
