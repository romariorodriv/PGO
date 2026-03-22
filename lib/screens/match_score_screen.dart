import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'finish_match_screen.dart';

class MatchScoreScreen extends StatefulWidget {
  const MatchScoreScreen({Key? key}) : super(key: key);

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedTeam = 1;
  final List<List<int>> _sets = [
    [6, 2],
    [7, 5],
    [5, 7],
    [10, 3],
  ];

  bool get _isMatchFinished {
    final team1Wins = _sets.where((s) => s[0] > s[1]).length;
    final team2Wins = _sets.where((s) => s[1] > s[0]).length;
    return team1Wins >= 2 || team2Wins >= 2;
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

  void _changeDate() async {
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

  void _showEditScoreDialog(int setIndex) {
    final controller1 = TextEditingController(text: '${_sets[setIndex][0]}');
    final controller2 = TextEditingController(text: '${_sets[setIndex][1]}');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar puntaje'),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller1,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Equipo 1',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Equipo 2',
                  ),
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
                final a = int.tryParse(controller1.text) ?? 0;
                final b = int.tryParse(controller2.text) ?? 0;
                setState(() {
                  _sets[setIndex][0] = a.clamp(0, 99);
                  _sets[setIndex][1] = b.clamp(0, 99);
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

  @override
  Widget build(BuildContext context) {
    final team1Wins = _sets.where((s) => s[0] > s[1]).length;
    final team2Wins = _sets.where((s) => s[1] > s[0]).length;

    return Scaffold(
      backgroundColor: AppColors.SecondBlue,
      appBar: AppBar(
        backgroundColor: AppColors.SecondBlue,
        elevation: 0,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Container(
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
                _buildScoreCard(team1Wins, team2Wins),
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
                    onPressed: _isMatchFinished
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FinishMatchScreen(
                                  matchDate: _formattedDate,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      disabledBackgroundColor: const Color(0xFFD7FF59)
                          .withOpacity(0.45),
                      foregroundColor: AppColors.SecondBlue,
                      disabledForegroundColor:
                          AppColors.SecondBlue.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
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
            color: Colors.black.withOpacity(0.08),
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
            child: Text(
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

  Widget _buildScoreCard(int team1Wins, int team2Wins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
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
                onTap: () => _showEditScoreDialog(0),
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
              '$team1Wins - $team2Wins',
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
            children: List.generate(
              _sets.length,
              (index) => _GamePill(
                score: '${_sets[index][0]} - ${_sets[index][1]}',
                onTap: () => _showEditScoreDialog(index),
              ),
            ),
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PlayerCircle(
          label: 'Romario',
          imageAsset: 'assets/images/Logo_Icono.png',
          selected: true,
        ),
        _PlayerCircle(
          label: 'Jugador 2',
          imageAsset: 'assets/images/Logo_Icono.png',
          usePlaceholder: true,
        ),
        _PlayerCircle(
          label: 'Jugador 3',
          imageAsset: 'assets/images/Logo_Icono.png',
          usePlaceholder: true,
        ),
        _PlayerCircle(
          label: 'Jugador 4',
          imageAsset: 'assets/images/Logo_Icono.png',
          usePlaceholder: true,
        ),
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
                    color: Colors.black.withOpacity(0.05),
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

class _PlayerCircle extends StatelessWidget {
  final String label;
  final String imageAsset;
  final bool selected;
  final bool usePlaceholder;

  const _PlayerCircle({
    required this.label,
    required this.imageAsset,
    this.selected = false,
    this.usePlaceholder = false,
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
                color: selected ? AppColors.PrimaryGreen : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: usePlaceholder
                  ? Container(color: const Color(0xFFAAB5CB))
                  : Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
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
}
