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
  final List<List<int>> _sets = List.generate(4, (_) => [0, 0]);

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
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildDateRow(),
              const SizedBox(height: 16),
              _buildScoreCard(team1Wins, team2Wins),
              const SizedBox(height: 24),
              const Text(
                'Ganadores',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTeamTabs(),
              const SizedBox(height: 12),
              _buildTeamPlayers(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
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
                    backgroundColor: AppColors.PrimaryGreen,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    foregroundColor: AppColors.SecondBlue,
                    disabledForegroundColor:
                        AppColors.SecondBlue.withOpacity(0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Siguiente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isMatchFinished
                    ? 'El match ya puede finalizarse.'
                    : 'Completa el resultado para continuar.',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formattedDate,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _changeDate,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.PrimaryGreen,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int team1Wins, int team2Wins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$team1Wins',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '-',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$team2Wins',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _sets.length,
              (index) {
                final set = _sets[index];
                return Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${set[0]} - ${set[1]}',
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEditScoreDialog(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.PrimaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.PrimaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (index < _sets.length - 1) const SizedBox(height: 8),
                  ],
                );
              },
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
        const SizedBox(width: 12),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const _PlayerCircle(
          label: 'Romario',
          imageAsset: 'assets/images/Logo_Icono.png',
          selected: true,
        ),
        const SizedBox(width: 12),
        const _PlayerCircle(
          label: 'Jugador 2',
          imageAsset: 'assets/images/Logo_Icono.png',
        ),
        const SizedBox(width: 12),
        const _PlayerCircle(
          label: 'Jugador 3',
          imageAsset: 'assets/images/Logo_Icono.png',
        ),
        const SizedBox(width: 12),
        const _PlayerCircle(
          label: 'Jugador 4',
          imageAsset: 'assets/images/Logo_Icono.png',
        ),
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TeamTab({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.SecondBlue : AppColors.primary,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.SecondBlue,
            fontWeight: FontWeight.bold,
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

  const _PlayerCircle({
    Key? key,
    required this.label,
    required this.imageAsset,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.PrimaryGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.9),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
