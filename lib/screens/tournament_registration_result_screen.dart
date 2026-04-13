import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../widgets/pgo_header_scaffold.dart';

class TournamentRegistrationResultScreen extends StatelessWidget {
  const TournamentRegistrationResultScreen({
    super.key,
    required this.tournament,
    required this.title,
    required this.message,
    required this.badge,
    required this.primaryLabel,
    this.secondaryLabel,
    this.statusTitle,
  });

  final TournamentRecord? tournament;
  final String title;
  final String message;
  final String badge;
  final String primaryLabel;
  final String? secondaryLabel;
  final String? statusTitle;

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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
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
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFD3DAE3),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ResultAvatar(
                    imageUrl: null,
                    highlight: true,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '...',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _ResultAvatar(
                    imageUrl: null,
                    highlight: false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (statusTitle != null) ...[
                Text(
                  statusTitle!,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _TournamentResultCard(
                tournament: tournament,
                badge: badge,
                primaryLabel: primaryLabel,
                secondaryLabel: secondaryLabel,
                onPrimary: () => Navigator.of(context).pop(),
                onSecondary: secondaryLabel == null
                    ? null
                    : () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
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

class _TournamentResultCard extends StatelessWidget {
  const _TournamentResultCard({
    required this.tournament,
    required this.badge,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final TournamentRecord? tournament;
  final String badge;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final registrationsCount = tournament?.registrationsCount ?? 0;
    final category = tournament?.category ?? '4TA';
    final formattedDate =
        tournament != null ? _formatDate(tournament!.startsAt) : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament?.title ?? 'Torneo PGO',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tournament?.location ?? 'One Padel Trigal',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.PrimaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE2E7EE),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.whatshot,
                size: 14,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 6),
              Text(
                '$registrationsCount amigos inscritos',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.PrimaryGreen,
                foregroundColor: AppColors.SecondBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                primaryLabel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.SecondBlue,
                  side: const BorderSide(color: Color(0xFFD3DAE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  secondaryLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultAvatar extends StatelessWidget {
  const _ResultAvatar({
    required this.imageUrl,
    required this.highlight,
  });

  final String? imageUrl;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD8DEE7),
        border: Border.all(
          color: highlight ? AppColors.PrimaryGreen : Colors.transparent,
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
                  size: 28,
                ),
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = <String>[
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
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  return '$day de $month';
}
