import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/app_notification.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';

class ConfirmarActividadScreen extends StatelessWidget {
  const ConfirmarActividadScreen({
    super.key,
    required this.notification,
  });

  final PgoAppNotification notification;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final data = notification.data;
    final title = notification.title.trim().isEmpty
        ? 'Tomás registró un match contigo'
        : notification.title;
    final body = notification.body.trim().isEmpty
        ? 'Revisa el marcador antes de guardarlo en tu historial.'
        : notification.body;
    final matchDate = _prettyDate(
      (data['matchDate'] ?? data['playedAt'] ?? '').toString(),
    );
    final club =
        (data['club'] ?? data['clubName'] ?? 'One Padel Olguin').toString();
    final category = (data['category'] ?? '4ta').toString();
    final format = (data['format'] ?? 'Dobles').toString();
    final sets = (data['sets'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const ['6 - 2', '7 - 5', '5 - 7', '10 - 3'];
    final leftPlayers = [
      (data['team1Player1'] ?? 'Jugador').toString(),
      (data['team1Player2'] ?? 'Arom').toString(),
    ];
    final rightPlayers = [
      (data['team2Player1'] ?? 'Tomás').toString(),
      (data['team2Player2'] ?? 'Miguel').toString(),
    ];
    final confirmations = [
      (name: leftPlayers[0], status: 'Registró'),
      (name: leftPlayers[1], status: 'Pendiente'),
      (name: rightPlayers[0], status: 'Pendiente'),
      (name: rightPlayers[1], status: 'Pendiente'),
    ];

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        primaryTextTheme:
            GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Confirmar resultado',
          style: PgoTextStyles.screenTitle(
            color: Colors.white,
            weight: FontWeight.w900,
          ).copyWith(fontSize: 24),
        ),
        actions: const [PgoOptionsMenuButton()],
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              children: [
                _IntroCard(title: title, body: body),
                const SizedBox(height: 14),
                _MatchInfoCard(
                  category: category,
                  format: format,
                  matchDate: matchDate.isEmpty ? 'Lunes 11 de mayo' : matchDate,
                  club: club,
                  leftPlayers: leftPlayers,
                  rightPlayers: rightPlayers,
                ),
                const SizedBox(height: 14),
                _ScoreCard(sets: sets),
                const SizedBox(height: 14),
                _ConfirmationCard(confirmations: confirmations),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resultado confirmado')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      'Confirmar resultado',
                      style: PgoTextStyles.buttonLarge(
                        color: AppColors.SecondBlue,
                        weight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diferencia reportada')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.SecondBlue,
                      side: const BorderSide(
                        color: AppColors.SecondBlue,
                        width: 1.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Reportar diferencia',
                      style: PgoTextStyles.button(
                        color: AppColors.SecondBlue,
                        weight: FontWeight.w800,
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
}

String _prettyDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('EEEE d MMMM', 'es').format(parsed.toLocal());
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFE6F7B8),
            child: Icon(Icons.sports_tennis_rounded,
                color: AppColors.SecondBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PgoTextStyles.title(
                    color: AppColors.SecondBlue,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: PgoTextStyles.bodySecondary(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  const _MatchInfoCard({
    required this.category,
    required this.format,
    required this.matchDate,
    required this.club,
    required this.leftPlayers,
    required this.rightPlayers,
  });

  final String category;
  final String format;
  final String matchDate;
  final String club;
  final List<String> leftPlayers;
  final List<String> rightPlayers;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          Row(
            children: [
              _Pill(label: '$category · $format'),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        matchDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.cardDetail(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        club,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.cardDetail(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _AvatarName(name: leftPlayers[0]),
              const SizedBox(width: 16),
              _AvatarName(name: leftPlayers[1]),
              const SizedBox(width: 16),
              const _VsChip(),
              const SizedBox(width: 16),
              _AvatarName(name: rightPlayers[0]),
              const SizedBox(width: 16),
              _AvatarName(name: rightPlayers[1]),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.sets});

  final List<String> sets;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sets',
            style: PgoTextStyles.sectionTitle(color: AppColors.SecondBlue),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '3 - 1',
              style: PgoTextStyles.display(
                color: AppColors.SecondBlue,
                weight: FontWeight.w900,
              ).copyWith(fontSize: 52),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final set in sets) _SetChip(label: set),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.confirmations});

  final List<({String name, String status})> confirmations;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de confirmación',
            style: PgoTextStyles.sectionTitle(color: AppColors.SecondBlue),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < confirmations.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFE6F7B8),
                        child: Icon(Icons.person, color: AppColors.SecondBlue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        confirmations[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.cardMeta(
                          color: AppColors.SecondBlue,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: i == 0
                                ? const Color(0xFFA7C11A)
                                : const Color(0xFFB9C0CB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            confirmations[i].status,
                            style: PgoTextStyles.cardDetail(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.72),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i != confirmations.length - 1)
                  Container(
                    width: 1,
                    height: 82,
                    color: const Color(0xFFE0E3E9),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PgoTextStyles.chip(color: AppColors.SecondBlue),
      ),
    );
  }
}

class _AvatarName extends StatelessWidget {
  const _AvatarName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFE6F7B8),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFFF3F4F7),
              child: Icon(Icons.person, color: AppColors.SecondBlue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PgoTextStyles.cardMeta(
              color: AppColors.SecondBlue,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VsChip extends StatelessWidget {
  const _VsChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          'VS',
          style: PgoTextStyles.button(
            color: AppColors.SecondBlue,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.SecondBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PgoTextStyles.buttonSecondary(
          color: Colors.white,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}
