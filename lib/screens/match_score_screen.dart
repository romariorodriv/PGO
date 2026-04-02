import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/selected_player.dart';
import '../services/match_service.dart';
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
  int? _selectedTeam;
  bool _isSaving = false;
  final List<List<int>> _games = [
    [6, 2],
  ];

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

  int get _team1Games => _games.fold<int>(0, (total, game) => total + game[0]);

  int get _team2Games => _games.fold<int>(0, (total, game) => total + game[1]);

  bool get _canContinue => _selectedTeam != null;

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
          title: Text('Editar game ${index + 1}'),
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

  Future<void> _addGame() async {
    setState(() {
      _games.add([0, 0]);
    });
    await _editGame(_games.length - 1);
  }

  Future<void> _handleContinue() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar el equipo ganador')),
      );
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
                'Ganadores',
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
                  onPressed:
                      _isSaving || !_canContinue ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    disabledBackgroundColor:
                        const Color(0xFFD7FF59).withValues(alpha: 0.45),
                    foregroundColor: AppColors.SecondBlue,
                    disabledForegroundColor:
                        AppColors.SecondBlue.withValues(alpha: 0.55),
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
                  'Sets',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _addGame,
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
              '$_team1Games - $_team2Games',
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
            'Games',
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
              setState(() {
                _selectedTeam = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamTab(
            label: 'Equipo 2',
            selected: _selectedTeam == 2,
            onTap: () {
              setState(() {
                _selectedTeam = 2;
              });
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
          '+ game',
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
