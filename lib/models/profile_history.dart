class ProfileHistory {
  const ProfileHistory({
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.history,
  });

  final int matchesPlayed;
  final int wins;
  final int losses;
  final double winRate;
  final List<ProfileHistoryMatch> history;

  factory ProfileHistory.fromJson(Map<String, dynamic> json) {
    return ProfileHistory(
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      history: ((json['history'] as List?) ?? const [])
          .map(
            (item) => ProfileHistoryMatch.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class ProfileHistoryMatch {
  const ProfileHistoryMatch({
    required this.id,
    required this.clubName,
    required this.playedAt,
    required this.matchType,
    required this.status,
    required this.result,
    required this.title,
    required this.subtitle,
    required this.xpDelta,
  });

  final String id;
  final String clubName;
  final DateTime playedAt;
  final String matchType;
  final String status;
  final String result;
  final String title;
  final String subtitle;
  final int xpDelta;

  factory ProfileHistoryMatch.fromJson(Map<String, dynamic> json) {
    return ProfileHistoryMatch(
      id: json['id'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      playedAt: DateTime.tryParse(json['playedAt'] as String? ?? '') ??
          DateTime.now(),
      matchType: json['matchType'] as String? ?? '',
      status: json['status'] as String? ?? '',
      result: (json['result'] as String? ?? 'PENDING').toUpperCase(),
      title: json['title'] as String? ?? 'Partido',
      subtitle: json['subtitle'] as String? ?? '',
      xpDelta: (json['xpDelta'] as num?)?.toInt() ?? 0,
    );
  }
}
