import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_record.dart';
import '../utils/tournament_rules.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_register_partner_screen.dart';
import 'tournament_register_solo_screen.dart';

class TournamentRegisterScreen extends StatelessWidget {
  const TournamentRegisterScreen({
    super.key,
    this.tournament,
    this.isModal = false,
    this.scrollController,
  });

  final TournamentRecord? tournament;
  final bool isModal;
  final ScrollController? scrollController;

  String get _title => tournament?.title ?? 'Torneo PGO';
  String get _location => tournament?.location ?? 'One Padel Trigal';
  int get _entryFee => tournament?.entryFee ?? 60;

  String get _formattedDate {
    final startsAt = tournament?.startsAt;
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

  @override
  Widget build(BuildContext context) {
    if (isModal) {
      return Material(
        color: Colors.transparent,
        child: _buildContent(context),
      );
    }

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Torneo',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [
        PgoOptionsMenuButton(),
      ],
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    const fee = 3;
    final totalSolo = _entryFee + fee;
    final canJoin =
        tournament == null ? false : TournamentRules.canJoin(tournament!);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F3F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
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
            Center(
              child: Text(
                'Inscripción torneo',
                style: GoogleFonts.inter(
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
            Container(
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
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _location,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    child: Column(
                      children: [
                        Text(
                          '¿Cómo quieres inscribirte?',
                          style: GoogleFonts.inter(
                            color: AppColors.SecondBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RegisterOptionTile(
                          icon: Icons.groups,
                          title: 'Con pareja',
                          subtitle:
                              'Inscríbete con tu dupla y confirma tu cupo al instante.',
                          onTap: () async {
                            if (!canJoin) {
                              _showBlockedRegistration(context);
                              return;
                            }
                            final result = await _showRegistrationSheet(
                              context,
                              builder: (context, scrollController) =>
                                  TournamentRegisterPartnerScreen(
                                tournament: tournament,
                                isModal: true,
                                scrollController: scrollController,
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _RegisterOptionTile(
                          icon: Icons.person,
                          title: 'Sin pareja',
                          subtitle:
                              'Te ayudamos a encontrar una dupla para este torneo.',
                          onTap: () async {
                            if (!canJoin) {
                              _showBlockedRegistration(context);
                              return;
                            }
                            final result = await _showRegistrationSheet(
                              context,
                              builder: (context, scrollController) =>
                                  TournamentRegisterSoloScreen(
                                tournament: tournament,
                                isModal: true,
                                scrollController: scrollController,
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFD3DAE3),
            ),
            const SizedBox(height: 18),
            Text(
              'Costo de inscripción:',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _PriceCard(
              tournament: 'S/$_entryFee',
              fee: 'S/$fee',
              total: 'S/$totalSolo',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3E7ED),
                  disabledBackgroundColor: const Color(0xFFE3E7ED),
                  foregroundColor: AppColors.SecondBlue,
                  disabledForegroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Pagar S/$totalSolo',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Cambiar método de pago >',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showRegistrationSheet(
    BuildContext context, {
    required Widget Function(BuildContext, ScrollController) builder,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.42,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: builder(context, scrollController),
          );
        },
      ),
    );
  }

  void _showBlockedRegistration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TournamentRules.joinLabel(tournament))),
    );
  }
}

class _RegisterOptionTile extends StatelessWidget {
  const _RegisterOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.SecondBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.tournament,
    required this.fee,
    required this.total,
  });

  final String tournament;
  final String fee;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          _PriceRow(label: 'Torneo', value: tournament),
          const SizedBox(height: 10),
          _PriceRow(label: 'Comisión PGO', value: fee),
          const SizedBox(height: 10),
          _PriceRow(label: 'Total', value: total, bold: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final fontWeight = bold ? FontWeight.w900 : FontWeight.w700;
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }
}
