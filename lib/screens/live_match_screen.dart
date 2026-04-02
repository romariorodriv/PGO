import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/selected_player.dart';
import '../services/match_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import 'finish_match_screen.dart';
import 'main_shell.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({
    super.key,
    required this.match,
    required this.players,
    required this.initialServingTeam,
  });

  final MatchRecord match;
  final List<SelectedPlayer> players;
  final int initialServingTeam;

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  late int _servingTeam;
  int _team1Points = 0;
  int _team2Points = 0;
  int _team1Games = 0;
  int _team2Games = 0;
  int _team1Sets = 0;
  int _team2Sets = 0;
  int _team1TieBreakPoints = 0;
  int _team2TieBreakPoints = 0;
  bool _isTieBreak = false;
  bool _useGoldenPoint = true;
  bool _isSidesSwapped = false;
  bool _isSaving = false;
  final List<Map<String, int>> _completedSets = [];
  final List<_LiveScoreSnapshot> _history = [];

  @override
  void initState() {
    super.initState();
    _servingTeam = widget.initialServingTeam;
  }

  String get _team1PointsLabel => _buildPointLabel(1);
  String get _team2PointsLabel => _buildPointLabel(2);
  int? get _matchWinnerTeam {
    if (_team1Sets == _team2Sets) return null;
    if (_completedSets.isEmpty) return null;
    return _team1Sets > _team2Sets ? 1 : 2;
  }

  bool get _canFinish => _matchWinnerTeam != null && !_isTieBreak;

  int get _leftTeam => _isSidesSwapped ? 2 : 1;
  int get _rightTeam => _isSidesSwapped ? 1 : 2;

  String get _formattedDate {
    const weekDays = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
    ];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final now = DateTime.now();
    final dayName = weekDays[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName ${now.day} de $monthName';
  }

  String _buildPointLabel(int team) {
    if (_isTieBreak) {
      return '${team == 1 ? _team1TieBreakPoints : _team2TieBreakPoints}';
    }

    final own = team == 1 ? _team1Points : _team2Points;
    final rival = team == 1 ? _team2Points : _team1Points;

    if (own >= 3 && rival >= 3) {
      if (!_useGoldenPoint) {
        if (own == rival) {
          return '40';
        }
        return own > rival ? 'AD' : '40';
      }
      return '40';
    }

    const labels = ['0', '15', '30', '40'];
    return labels[own.clamp(0, 3)];
  }

  void _pushHistory() {
    _history.add(
      _LiveScoreSnapshot(
        team1Points: _team1Points,
        team2Points: _team2Points,
        team1Games: _team1Games,
        team2Games: _team2Games,
        team1Sets: _team1Sets,
        team2Sets: _team2Sets,
        team1TieBreakPoints: _team1TieBreakPoints,
        team2TieBreakPoints: _team2TieBreakPoints,
        servingTeam: _servingTeam,
        isTieBreak: _isTieBreak,
        isSidesSwapped: _isSidesSwapped,
        completedSets: _completedSets
            .map((item) => {'team1': item['team1']!, 'team2': item['team2']!})
            .toList(),
      ),
    );
  }

  void _addPointToTeam(int team) {
    if (_matchWinnerTeam != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El partido ya tiene un ganador. Ya puedes finalizarlo.'),
        ),
      );
      return;
    }

    setState(() {
      _pushHistory();

      if (_isTieBreak) {
        if (team == 1) {
          _team1TieBreakPoints += 1;
        } else {
          _team2TieBreakPoints += 1;
        }
        _tryCompleteTieBreakSet();
        return;
      }

      final own = team == 1 ? _team1Points : _team2Points;
      final rival = team == 1 ? _team2Points : _team1Points;

      if (own >= 3 && rival >= 3) {
        if (_useGoldenPoint) {
          _winGame(team);
          return;
        }

        if (own == rival) {
          if (team == 1) {
            _team1Points = 4;
          } else {
            _team2Points = 4;
          }
          return;
        }

        if (own > rival) {
          _winGame(team);
          return;
        }

        if (team == 1) {
          _team2Points = 3;
        } else {
          _team1Points = 3;
        }
        return;
      }

      if (own >= 3) {
        _winGame(team);
        return;
      }

      if (team == 1) {
        _team1Points += 1;
      } else {
        _team2Points += 1;
      }
    });
  }

  void _tryCompleteTieBreakSet() {
    final diff = (_team1TieBreakPoints - _team2TieBreakPoints).abs();
    if ((_team1TieBreakPoints >= 7 || _team2TieBreakPoints >= 7) && diff >= 2) {
      final team1Wins = _team1TieBreakPoints > _team2TieBreakPoints;
      _completeSet(
        team1Games: team1Wins ? 7 : 6,
        team2Games: team1Wins ? 6 : 7,
      );
    }
  }

  void _winGame(int team) {
    if (team == 1) {
      _team1Games += 1;
    } else {
      _team2Games += 1;
    }

    _team1Points = 0;
    _team2Points = 0;
    _servingTeam = _servingTeam == 1 ? 2 : 1;

    if (_team1Games == 6 && _team2Games == 6) {
      _isTieBreak = true;
      _team1TieBreakPoints = 0;
      _team2TieBreakPoints = 0;
      return;
    }

    final diff = (_team1Games - _team2Games).abs();
    if ((_team1Games >= 6 || _team2Games >= 6) && diff >= 2) {
      _completeSet(team1Games: _team1Games, team2Games: _team2Games);
    }
  }

  void _completeSet({
    required int team1Games,
    required int team2Games,
  }) {
    _completedSets.add({
      'team1': team1Games,
      'team2': team2Games,
    });

    if (team1Games > team2Games) {
      _team1Sets += 1;
    } else {
      _team2Sets += 1;
    }

    _team1Games = 0;
    _team2Games = 0;
    _team1Points = 0;
    _team2Points = 0;
    _team1TieBreakPoints = 0;
    _team2TieBreakPoints = 0;
    _isTieBreak = false;
  }

  void _undo() {
    if (_history.isEmpty) return;

    setState(() {
      final previous = _history.removeLast();
      _team1Points = previous.team1Points;
      _team2Points = previous.team2Points;
      _team1Games = previous.team1Games;
      _team2Games = previous.team2Games;
      _team1Sets = previous.team1Sets;
      _team2Sets = previous.team2Sets;
      _team1TieBreakPoints = previous.team1TieBreakPoints;
      _team2TieBreakPoints = previous.team2TieBreakPoints;
      _servingTeam = previous.servingTeam;
      _isTieBreak = previous.isTieBreak;
      _isSidesSwapped = previous.isSidesSwapped;
      _completedSets
        ..clear()
        ..addAll(
          previous.completedSets
              .map((item) => {'team1': item['team1']!, 'team2': item['team2']!}),
        );
    });
  }

  void _toggleService() {
    setState(() {
      _pushHistory();
      _servingTeam = _servingTeam == 1 ? 2 : 1;
    });
  }

  void _toggleSides() {
    setState(() {
      _pushHistory();
      _isSidesSwapped = !_isSidesSwapped;
    });
  }

  void _toggleGoldenPoint() {
    if (_team1Points > 0 ||
        _team2Points > 0 ||
        _team1Games > 0 ||
        _team2Games > 0 ||
        _completedSets.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo puedes cambiar la regla de deuce antes de iniciar el partido.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _useGoldenPoint = !_useGoldenPoint;
    });
  }

  Future<void> _finishLiveMatch() async {
    final winnerTeam = _matchWinnerTeam;
    if (winnerTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa al menos un set valido antes de finalizar'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final games = _completedSets.isNotEmpty
        ? _completedSets
        : [
            {
              'team1': _team1Games,
              'team2': _team2Games,
            },
          ];

    try {
      final updatedMatch = await MatchService().updateMatchResult(
        matchId: widget.match.id,
        playedAt: DateTime.now(),
        winnerTeam: winnerTeam,
        games: games,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FinishMatchScreen(
            matchDate: _formattedDate,
            match: updatedMatch,
            players: widget.players,
            winnerTeam: winnerTeam,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.match.clubName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBar: PgoBottomNav(
        currentTab: PgoNavTab.tournaments,
        onHomeTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.home);
        },
        onTournamentsTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.tournaments);
        },
        onProfileTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
        },
      ),
      body: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F5F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 12, 26, 28),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD01111),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _leftTeam == 1
                                    ? _team1PointsLabel
                                    : _team2PointsLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.SecondBlue,
                                  fontSize: 78,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 94),
                            Expanded(
                              child: Text(
                                _rightTeam == 1
                                    ? _team1PointsLabel
                                    : _team2PointsLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.SecondBlue,
                                  fontSize: 78,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildCenterScoreCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _displayedPlayers
                      .map(
                        (player) => _ScorePlayer(
                          label: player.name,
                          imageUrl: player.photoUrl,
                          selected: player.id == _leftTeamPlayers.first.id,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                _buildInfoCard(),
                const SizedBox(height: 28),
                _ActionPill(
                  label:
                      '+ Punto ${_leftTeamPlayers[0].name} / ${_leftTeamPlayers[1].name}',
                  filled: true,
                  onTap: () => _addPointToTeam(_leftTeam),
                ),
                const SizedBox(height: 14),
                _ActionPill(
                  label:
                      '+ Punto ${_rightTeamPlayers[0].name} / ${_rightTeamPlayers[1].name}',
                  onTap: () => _addPointToTeam(_rightTeam),
                ),
                const SizedBox(height: 22),
                _SmallPill(
                  label: 'Deshacer',
                  onTap: _history.isEmpty ? null : _undo,
                  width: 130,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SmallPill(
                      label: 'Cambiar servicio',
                      onTap: _toggleService,
                      width: 130,
                    ),
                    _SmallPill(
                      label: 'Cambiar lado',
                      onTap: _toggleSides,
                      width: 130,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 138,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _isSaving || !_canFinish ? null : _finishLiveMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      disabledBackgroundColor:
                          const Color(0xFFD7FF59).withValues(alpha: 0.45),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Finalizar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<SelectedPlayer> get _team1Players => widget.players.take(2).toList();
  List<SelectedPlayer> get _team2Players => widget.players.skip(2).take(2).toList();
  List<SelectedPlayer> get _leftTeamPlayers =>
      _leftTeam == 1 ? _team1Players : _team2Players;
  List<SelectedPlayer> get _rightTeamPlayers =>
      _rightTeam == 1 ? _team1Players : _team2Players;
  List<SelectedPlayer> get _displayedPlayers => [
        ..._leftTeamPlayers,
        ..._rightTeamPlayers,
      ];

  Widget _buildCenterScoreCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.SecondBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _isTieBreak ? 'TIE-BREAK' : 'LIVE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 104,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$_team1Games / $_team2Games',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Games',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.68),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    final deuceText = _useGoldenPoint ? 'Punto de oro' : 'Ventaja';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Sets', value: '$_team1Sets - $_team2Sets'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Games', value: '$_team1Games - $_team2Games'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Modo', value: _isTieBreak ? 'Tie-break' : deuceText),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Deuce',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              _SmallPill(
                label: _useGoldenPoint ? 'Punto de oro' : 'Ventaja',
                onTap: _isTieBreak ? null : _toggleGoldenPoint,
                width: 132,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Servicio',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.sports_tennis,
                color: Color(0xFFB7D56A),
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                'Equipo $_servingTeam',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePlayer extends StatelessWidget {
  const _ScorePlayer({
    required this.label,
    this.imageUrl,
    this.selected = false,
  });

  final String label;
  final String? imageUrl;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD4DEED),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.PrimaryGreen : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFFD7FF59) : Colors.white,
          foregroundColor: AppColors.SecondBlue,
          elevation: filled ? 0 : 3,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.width,
    this.onTap,
  });

  final String label;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE6E9EE),
          foregroundColor: AppColors.SecondBlue,
          disabledForegroundColor: AppColors.SecondBlue.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LiveScoreSnapshot {
  const _LiveScoreSnapshot({
    required this.team1Points,
    required this.team2Points,
    required this.team1Games,
    required this.team2Games,
    required this.team1Sets,
    required this.team2Sets,
    required this.team1TieBreakPoints,
    required this.team2TieBreakPoints,
    required this.servingTeam,
    required this.isTieBreak,
    required this.isSidesSwapped,
    required this.completedSets,
  });

  final int team1Points;
  final int team2Points;
  final int team1Games;
  final int team2Games;
  final int team1Sets;
  final int team2Sets;
  final int team1TieBreakPoints;
  final int team2TieBreakPoints;
  final int servingTeam;
  final bool isTieBreak;
  final bool isSidesSwapped;
  final List<Map<String, int>> completedSets;
}
