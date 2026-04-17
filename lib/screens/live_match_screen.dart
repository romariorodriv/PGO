import 'dart:async';

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
  final bool _useGoldenPoint = false;
  bool _isSidesSwapped = false;
  bool _isSaving = false;
  int? _tieBreakFirstServingTeam;
  final List<Map<String, int>> _completedSets = [];
  final List<_LiveScoreSnapshot> _history = [];
  final Stopwatch _matchTimer = Stopwatch();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _servingTeam = widget.initialServingTeam;
    _matchTimer.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _matchTimer.stop();
    super.dispose();
  }

  String get _team1PointsLabel => _buildPointLabel(1);
  String get _team2PointsLabel => _buildPointLabel(2);

  int? get _matchWinnerTeam {
    if (_team1Sets >= 2) return 1;
    if (_team2Sets >= 2) return 2;
    return null;
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
        tieBreakFirstServingTeam: _tieBreakFirstServingTeam,
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
          content:
              Text('El partido ya tiene un ganador. Ya puedes finalizarlo.'),
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
        _applyTieBreakFlowRules();
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

  void _applyTieBreakFlowRules() {
    final totalPoints = _team1TieBreakPoints + _team2TieBreakPoints;
    if (totalPoints <= 0 || _tieBreakFirstServingTeam == null) {
      return;
    }

    _servingTeam =
        _resolveTieBreakServingTeam(totalPoints, _tieBreakFirstServingTeam!);
  }

  int _resolveTieBreakServingTeam(int totalPointsPlayed, int firstServingTeam) {
    if (totalPointsPlayed <= 0) {
      return firstServingTeam;
    }

    final secondServingTeam = firstServingTeam == 1 ? 2 : 1;
    final block = (totalPointsPlayed - 1) ~/ 2;
    return block.isEven ? secondServingTeam : firstServingTeam;
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
      _tieBreakFirstServingTeam = _servingTeam;
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
    _tieBreakFirstServingTeam = null;
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
      _tieBreakFirstServingTeam = previous.tieBreakFirstServingTeam;
      _completedSets
        ..clear()
        ..addAll(
          previous.completedSets.map(
              (item) => {'team1': item['team1']!, 'team2': item['team2']!}),
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

  List<SelectedPlayer> get _team1Players => widget.players.take(2).toList();
  List<SelectedPlayer> get _team2Players =>
      widget.players.skip(2).take(2).toList();
  List<SelectedPlayer> get _leftTeamPlayers =>
      _leftTeam == 1 ? _team1Players : _team2Players;
  List<SelectedPlayer> get _rightTeamPlayers =>
      _rightTeam == 1 ? _team1Players : _team2Players;

  int get _leftTeamSets => _leftTeam == 1 ? _team1Sets : _team2Sets;
  int get _rightTeamSets => _rightTeam == 1 ? _team1Sets : _team2Sets;
  int get _leftTeamGames => _leftTeam == 1 ? _team1Games : _team2Games;
  int get _rightTeamGames => _rightTeam == 1 ? _team1Games : _team2Games;

  String get _setsLabel => '$_leftTeamSets - $_rightTeamSets';
  String get _gamesLabel => '$_leftTeamGames - $_rightTeamGames';
  String get _serviceLabel {
    if (_servingTeam == _leftTeam) return 'Equipo 1';
    return 'Equipo 2';
  }

  List<String> get _completedSetLabels => _completedSets.map((set) {
        final leftGames =
            _leftTeam == 1 ? set['team1'] ?? 0 : set['team2'] ?? 0;
        final rightGames =
            _rightTeam == 1 ? set['team1'] ?? 0 : set['team2'] ?? 0;
        return '$leftGames - $rightGames';
      }).toList();

  String get _smallCenterTopText {
    final elapsed = _matchTimer.elapsed;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds.toString().padLeft(2, '0')}s';
  }

  String get _smallCenterBottomText => '$_leftTeamSets-$_rightTeamSets';

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Cancha 2',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81414),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                        _TopScoreSection(
                          leftScore: _leftTeam == 1
                              ? _team1PointsLabel
                              : _team2PointsLabel,
                          rightScore: _rightTeam == 1
                              ? _team1PointsLabel
                              : _team2PointsLabel,
                          gamesLabel: _gamesLabel,
                          setRows: _completedSetLabels,
                          topText: _smallCenterTopText,
                          bottomText: _smallCenterBottomText,
                          leftPlayers: _leftTeamPlayers,
                          rightPlayers: _rightTeamPlayers,
                          onLeftScoreTap: () => _addPointToTeam(_leftTeam),
                          onRightScoreTap: () => _addPointToTeam(_rightTeam),
                        ),
                        const SizedBox(height: 18),
                        _CompactInfoCard(
                          sets: _setsLabel,
                          games: _gamesLabel,
                          servingTeam: _serviceLabel,
                        ),
                        const SizedBox(height: 18),
                        _ActionPill(
                          label:
                              '+ Punto ${_leftTeamPlayers[0].name} / ${_leftTeamPlayers[1].name}',
                          filled: true,
                          onTap: () => _addPointToTeam(_leftTeam),
                        ),
                        const SizedBox(height: 12),
                        _ActionPill(
                          label:
                              '+ Punto ${_rightTeamPlayers[0].name} / ${_rightTeamPlayers[1].name}',
                          onTap: () => _addPointToTeam(_rightTeam),
                        ),
                        const SizedBox(height: 18),
                        _SmallPill(
                          label: 'Deshacer',
                          onTap: _history.isEmpty ? null : _undo,
                          width: 128,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SmallPill(
                              label: 'Cambiar servicio',
                              onTap: _toggleService,
                              width: 142,
                            ),
                            _SmallPill(
                              label: 'Cambiar lado',
                              onTap: _toggleSides,
                              width: 142,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 126,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _isSaving || !_canFinish
                                ? null
                                : _finishLiveMatch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD7FF59),
                              foregroundColor: AppColors.SecondBlue,
                              disabledBackgroundColor: const Color(0xFFD7FF59)
                                  .withValues(alpha: 0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CenterScoreCard extends StatelessWidget {
  const _CenterScoreCard({
    required this.gamesLabel,
    required this.setRows,
    required this.topText,
    required this.bottomText,
  });

  final String gamesLabel;
  final List<String> setRows;
  final String topText;
  final String bottomText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.SecondBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            topText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 98,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                gamesLabel,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFD8DEE8),
              ),
              const SizedBox(height: 3),
              if (setRows.isEmpty)
                Text(
                  'Set en curso',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...setRows.take(3).map(
                      (set) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          set,
                          style: TextStyle(
                            color: AppColors.SecondBlue.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 6),
              Container(
                width: 52,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.SecondBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  bottomText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactInfoCard extends StatelessWidget {
  const _CompactInfoCard({
    required this.sets,
    required this.games,
    required this.servingTeam,
  });

  final String sets;
  final String games;
  final String servingTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          _CompactInfoRow(label: 'Sets', value: sets),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFD8DEE8),
          ),
          const SizedBox(height: 8),
          _CompactInfoRow(label: 'Games', value: games),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFD8DEE8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Servicio',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.sports_tennis,
                color: Color(0xFFB7D56A),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                servingTeam,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 15,
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

class _TopScoreSection extends StatelessWidget {
  const _TopScoreSection({
    required this.leftScore,
    required this.rightScore,
    required this.gamesLabel,
    required this.setRows,
    required this.topText,
    required this.bottomText,
    required this.leftPlayers,
    required this.rightPlayers,
    required this.onLeftScoreTap,
    required this.onRightScoreTap,
  });

  final String leftScore;
  final String rightScore;
  final String gamesLabel;
  final List<String> setRows;
  final String topText;
  final String bottomText;
  final List<SelectedPlayer> leftPlayers;
  final List<SelectedPlayer> rightPlayers;
  final VoidCallback onLeftScoreTap;
  final VoidCallback onRightScoreTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onLeftScoreTap,
                      child: Text(
                        leftScore,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 76,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 108),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRightScoreTap,
                      child: Text(
                        rightScore,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 76,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CenterScoreCard(
              gamesLabel: gamesLabel,
              setRows: setRows,
              topText: topText,
              bottomText: bottomText,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: Divider(
                color: Color(0xFFD4DBE6),
                thickness: 1,
                height: 1,
              ),
            ),
            SizedBox(width: 42),
            Expanded(
              child: Divider(
                color: Color(0xFFD4DBE6),
                thickness: 1,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TeamPreviewRow(
                players: leftPlayers,
                alignStart: true,
              ),
            ),
            Container(
              width: 1,
              height: 42,
              color: const Color(0xFFD4DBE6),
            ),
            Expanded(
              child: _TeamPreviewRow(
                players: rightPlayers,
                alignStart: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeamPreviewRow extends StatelessWidget {
  const _TeamPreviewRow({
    required this.players,
    required this.alignStart,
  });

  final List<SelectedPlayer> players;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignStart ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: players
          .map(
            (player) => Padding(
              padding: EdgeInsets.only(
                left: alignStart ? 0 : 8,
                right: alignStart ? 8 : 0,
              ),
              child: _ScorePlayer(
                label: player.name,
                imageUrl: player.photoUrl,
                selected: players.first == player,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  const _CompactInfoRow({
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
      width: 52,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
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
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFFD7FF59) : Colors.white,
          foregroundColor: AppColors.SecondBlue,
          elevation: filled ? 0 : 3,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
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
    required this.tieBreakFirstServingTeam,
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
  final int? tieBreakFirstServingTeam;
  final List<Map<String, int>> completedSets;
}
