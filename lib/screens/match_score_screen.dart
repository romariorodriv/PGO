import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/selected_player.dart';
import '../services/match_service.dart';
import '../utils/padel_rules.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'finish_match_screen.dart';

class MatchScoreScreen extends StatefulWidget {
  const MatchScoreScreen({
    super.key,
    required this.match,
    required this.players,
  });

  final MatchRecord match;
  final List<SelectedPlayer> players;

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  late DateTime _selectedDate;
  bool _isSaving = false;
  final List<List<int>> _games = [
    [0, 0],
  ];
  int? _finalTeam1Sets;
  int? _finalTeam2Sets;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.match.playedAt;
  }

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

    final dayName = weekDays[_selectedDate.weekday % 7];
    final monthName = months[_selectedDate.month - 1];
    return '$dayName ${_selectedDate.day} de $monthName';
  }

  PadelMatchValidationResult get _matchValidation {
    final base = PadelRules.validateBestOfThreeMatch(_games);
    if (!base.isValid) {
      return base;
    }

    if (_games.length < 2 || _games.length > PadelRules.maxSets) {
      return PadelMatchValidationResult(
        isValid: false,
        error: 'Debes registrar 2 o 3 sets del partido.',
        team1SetsWon: base.team1SetsWon,
        team2SetsWon: base.team2SetsWon,
      );
    }

    if (!_isFinalSetsValid) {
      return PadelMatchValidationResult(
        isValid: false,
        error: 'Debes registrar el resultado final 2-1, 1-2, 2-0 o 0-2 en sets.',
        team1SetsWon: base.team1SetsWon,
        team2SetsWon: base.team2SetsWon,
      );
    }

    if (base.team1SetsWon != _finalTeam1Sets ||
        base.team2SetsWon != _finalTeam2Sets) {
      return PadelMatchValidationResult(
        isValid: false,
        error:
            'El resultado final en sets no coincide con los sets registrados.',
        team1SetsWon: base.team1SetsWon,
        team2SetsWon: base.team2SetsWon,
      );
    }

    return base;
  }

  int get _team1SetsWon => _matchValidation.team1SetsWon;
  int get _team2SetsWon => _matchValidation.team2SetsWon;
  int? get _selectedTeam =>
      _finalWinnerTeam ?? (_matchValidation.isValid ? _matchValidation.winnerTeam : null);

  bool get _canContinue => _matchValidation.isValid && _selectedTeam != null;
  bool get _isFinalSetsValid =>
      (_finalTeam1Sets == 2 && _finalTeam2Sets == 1) ||
      (_finalTeam1Sets == 1 && _finalTeam2Sets == 2) ||
      (_finalTeam1Sets == 2 && _finalTeam2Sets == 0) ||
      (_finalTeam1Sets == 0 && _finalTeam2Sets == 2);
  int? get _finalWinnerTeam {
    if (!_isFinalSetsValid) return null;
    return _finalTeam1Sets! > _finalTeam2Sets! ? 1 : 2;
  }

  Future<void> _changeDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  Future<void> _editGame(int index) async {
    final controller1 = TextEditingController(text: '${_games[index][0]}');
    final controller2 = TextEditingController(text: '${_games[index][1]}');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar set ${index + 1}'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller1,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipo 1'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipo 2'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final team1 = int.tryParse(controller1.text) ?? 0;
                final team2 = int.tryParse(controller2.text) ?? 0;
                final validation =
                    PadelRules.validateCompletedSetScore(team1, team2);
                if (!validation.isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Set invalido. Ingresa el marcador final del set: 6-0 a 6-4, 7-5 o 7-6.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  _games[index] = [team1, team2];
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFinalSets() async {
    final controller1 =
        TextEditingController(text: _finalTeam1Sets?.toString() ?? '');
    final controller2 =
        TextEditingController(text: _finalTeam2Sets?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar resultado final'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller1,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipo 1'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Equipo 2'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final team1 = int.tryParse(controller1.text);
                final team2 = int.tryParse(controller2.text);
                if (!((team1 == 2 && team2 == 1) ||
                    (team1 == 1 && team2 == 2) ||
                    (team1 == 2 && team2 == 0) ||
                    (team1 == 0 && team2 == 2))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Resultado invalido. Usa 2-1, 1-2, 2-0 o 0-2.'),
                    ),
                  );
                  return;
                }
                setState(() {
                  _finalTeam1Sets = team1;
                  _finalTeam2Sets = team2;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGame() async {
    if (_games.length >= PadelRules.maxSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un partido al mejor de 3 no puede tener mas de 3 sets'),
        ),
      );
      return;
    }

    setState(() {
      _games.add([0, 0]);
    });
    await _editGame(_games.length - 1);
  }

  Future<void> _handleContinue() async {
    if (!_matchValidation.isValid || _selectedTeam == null) {
      final message = _matchValidation.error ??
          'El partido debe tener una pareja ganadora valida.';
      await _showValidationError(message);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await MatchService().updateMatchResult(
        matchId: widget.match.id,
        playedAt: _selectedDate,
        winnerTeam: _selectedTeam!,
        games: _games
            .map(
              (game) => {
                'team1': game[0],
                'team2': game[1],
              },
            )
            .toList(),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FinishMatchScreen(
            match: widget.match,
            players: widget.players,
            winnerTeam: _selectedTeam!,
            matchDate: _formattedDate,
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

  Future<void> _showValidationError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('No puedes continuar'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Actividad',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [PgoOptionsMenuButton()],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRow(),
              const SizedBox(height: 32),
              _buildScoreCard(),
              const SizedBox(height: 18),
              const Text(
                'Pareja ganadora',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildTeamTabs(),
              const SizedBox(height: 12),
              _buildTeamPlayers(),
              const SizedBox(height: 160),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinue
                        ? const Color(0xFFD7FF59)
                        : const Color(0xFFD9DEE7),
                    foregroundColor: _canContinue
                        ? AppColors.SecondBlue
                        : AppColors.SecondBlue.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'SIGUIENTE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formattedDate,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _changeDate,
            child: const Text(
              'Cambiar',
              style: TextStyle(
                color: AppColors.PrimaryGreen,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Resultado en sets',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _editFinalSets,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.SecondBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              _finalTeam1Sets != null && _finalTeam2Sets != null
                  ? '$_finalTeam1Sets - $_finalTeam2Sets'
                  : '--',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFD7DDE5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sets registrados',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(
                _games.length,
                (index) => _GamePill(
                  score: '${_games[index][0]} - ${_games[index][1]}',
                  onTap: () => _editGame(index),
                ),
              ),
              _AddGamePill(onTap: _addGame),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTabs() {
    return Row(
      children: [
        Expanded(
          child: _TeamTab(
            label: 'Equipo 1',
            selected: _selectedTeam == 1,
            onTap: () {
              _showValidationError(
                'El ganador se define por el resultado en sets. Usa el lapiz para editarlo.',
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamTab(
            label: 'Equipo 2',
            selected: _selectedTeam == 2,
            onTap: () {
              _showValidationError(
                'El ganador se define por el resultado en sets. Usa el lapiz para editarlo.',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPlayers() {
    final team1 = widget.players.take(2).toList();
    final team2 = widget.players.skip(2).take(2).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...team1.map((player) => _ScorePlayerCircle(player: player)),
        ...team2.map((player) => _ScorePlayerCircle(player: player)),
      ],
    );
  }
}

class _GamePill extends StatelessWidget {
  final String score;
  final VoidCallback onTap;

  const _GamePill({
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.SecondBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AddGamePill extends StatelessWidget {
  final VoidCallback onTap;

  const _AddGamePill({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EBF3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          '+ set',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TeamTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.SecondBlue,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ScorePlayerCircle extends StatelessWidget {
  final SelectedPlayer player;

  const _ScorePlayerCircle({
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.PrimaryGreen,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                  ? Image.network(
                      player.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFABB8CC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }
}
