import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../widgets/pgo_header_scaffold.dart';

class TournamentRegisterSoloScreen extends StatefulWidget {
  const TournamentRegisterSoloScreen({
    super.key,
    this.tournament,
  });

  final TournamentRecord? tournament;

  @override
  State<TournamentRegisterSoloScreen> createState() =>
      _TournamentRegisterSoloScreenState();
}

class _TournamentRegisterSoloScreenState
    extends State<TournamentRegisterSoloScreen> {
  final TournamentService _tournamentService = TournamentService();
  String _preferredSide = 'Drive';
  String _availability = 'Flexible';
  bool _acceptedPending = false;
  bool _isSubmitting = false;

  TournamentRecord? get _tournament => widget.tournament;
  String get _title => _tournament?.title ?? 'Torneo PGO';
  String get _location => _tournament?.location ?? 'One Padel Trigal';

  String get _formattedDate {
    final startsAt = _tournament?.startsAt;
    if (startsAt == null) return 'Lunes 19 de Diciembre';
    const weekDays = [
      'Lunes',
      'Martes',
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
      'Domingo',
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
    final local = startsAt.toLocal();
    return '${weekDays[local.weekday - 1]} ${local.day} de ${months[local.month - 1]}';
  }

  Future<void> _submit() async {
    final tournament = _tournament;
    if (tournament == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _tournamentService.registerSolo(
        tournamentId: tournament.id,
        preferredSide: _preferredSide,
        availability: _availability,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripcion pendiente registrada.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
        'Torneo',
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB6C0D0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Center(
                child: Text(
                  'Inscripcion torneo',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFD3DAE3),
              ),
              const SizedBox(height: 20),
              _buildCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF1),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF426EA6),
                  AppColors.SecondBlue,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Participaras sin pareja',
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Te ayudamos a encontrar una dupla para este torneo.',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFD3DAE3),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tu lado preferido',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSegmented(
                  options: const ['Drive', 'Reves', 'Indistinto'],
                  selected: _preferredSide,
                  onSelected: (value) {
                    setState(() {
                      _preferredSide = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Disponibilidad',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSegmented(
                  options: const ['Flexible', 'Tarde', 'Noche'],
                  selected: _availability,
                  onSelected: (value) {
                    setState(() {
                      _availability = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EFBF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: 'Tu participacion sera '),
                        TextSpan(
                          text: 'confirmada',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: ' cuando completemos tu dupla.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedPending,
                      onChanged: (value) {
                        setState(() {
                          _acceptedPending = value ?? false;
                        });
                      },
                      activeColor: AppColors.SecondBlue,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: AppColors.SecondBlue.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Entiendo que mi inscripcion queda ',
                              ),
                              TextSpan(
                                text: 'pendiente',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              TextSpan(
                                text:
                                    ' de confirmacion hasta encontrar pareja',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _acceptedPending && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      disabledBackgroundColor:
                          const Color(0xFFD7FF59).withValues(alpha: 0.45),
                      foregroundColor: AppColors.SecondBlue,
                      disabledForegroundColor:
                          AppColors.SecondBlue.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'CONFIRMAR',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmented({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: options
            .map(
              (option) => Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected == option
                          ? AppColors.SecondBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: selected == option
                            ? Colors.white
                            : AppColors.SecondBlue,
                        fontSize: 12,
                        fontWeight: selected == option
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
