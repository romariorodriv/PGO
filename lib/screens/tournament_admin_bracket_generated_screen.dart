import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_admin_bracket_screen.dart';
import 'tournament_admin_matches_screen.dart';
import 'tournament_admin_screen.dart';

class TournamentAdminBracketGeneratedScreen extends StatelessWidget {
  const TournamentAdminBracketGeneratedScreen({
    super.key,
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Cruces generados',
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
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: AppColors.PrimaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cruces generados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El cuadro del torneo ya fue generado y todo esta listo para iniciar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.72),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              _SummaryCard(tournament: tournament),
              const SizedBox(height: 18),
              _ActionButton(
                label: 'Ver partidos',
                filled: true,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => TournamentAdminMatchesScreen(
                        tournament: tournament,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Ver bracket',
                filled: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TournamentAdminBracketScreen(
                        tournament: tournament,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Ir al panel',
                filled: false,
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => TournamentAdminScreen(
                        tournament: tournament,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(tournament.photoUrl);
    final duplas = (tournament.registrationsCount / 2).floor();

    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (tournament.photoUrl != null && tournament.photoUrl!.isNotEmpty)
                tournament.photoUrl!.startsWith('http')
                    ? Image.network(
                        tournament.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/InkaPadel.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : (bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/InkaPadel.png',
                            fit: BoxFit.cover,
                          ))
              else
                Image.asset(
                  'assets/images/InkaPadel.png',
                  fit: BoxFit.cover,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.whatshot,
                        size: 12,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cruces generados',
                        style: TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(tournament.startsAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      tournament.location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$duplas parejas listas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Formato: ${_capitalize(tournament.format)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'Estado: Listo para iniciar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} · $hour:$minute';
  }

  String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Dobles';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? AppColors.PrimaryGreen : const Color(0xFFE7EBF0),
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
