import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../models/tournament_admin_matches.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../screens/tournament_live_screen.dart';
import '../utils/tournament_share_link.dart';

enum TournamentViewerRole { admin, participant, external }

class TournamentRoleTableView extends StatefulWidget {
  const TournamentRoleTableView({
    super.key,
    required this.tournament,
    required this.profile,
  });

  final TournamentRecord? tournament;
  final ProfileSummary? profile;

  @override
  State<TournamentRoleTableView> createState() =>
      _TournamentRoleTableViewState();
}

class _TournamentRoleTableViewState extends State<TournamentRoleTableView> {
  TournamentAdminMatchesData? _data;
  bool _loading = true;
  String? _error;

  TournamentRecord? get _tournament => widget.tournament;
  ProfileSummary? get _profile => widget.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  TournamentViewerRole get _role {
    final tournament = _tournament;
    final profile = _profile;
    if (tournament == null || profile == null) {
      return TournamentViewerRole.external;
    }
    if ((tournament.createdById ?? '') == profile.id) {
      return TournamentViewerRole.admin;
    }
    final isParticipant = tournament.registrationEntries.any(
      (entry) =>
          entry.user.id == profile.id || entry.partnerUser?.id == profile.id,
    );
    return isParticipant
        ? TournamentViewerRole.participant
        : TournamentViewerRole.external;
  }

  Future<void> _load() async {
    final tournamentId = _tournament?.id;
    if (tournamentId == null || tournamentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se encontró el torneo.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await TournamentService().getTournamentMatches(tournamentId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _tournament;
    if (tournament == null) {
      return _emptyState(
        'La clasificación aparecerá cuando se registren resultados.',
      );
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _messageCard(
        icon: Icons.warning_amber_rounded,
        title: 'No pudimos cargar la tabla',
        subtitle: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }

    final standings = _buildStandings(
      tournament.registrationEntries,
      _data?.matches ?? const <TournamentAdminMatch>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerCard(standings),
        const SizedBox(height: 12),
        if (standings.isEmpty)
          _emptyState(
            'La clasificación aparecerá cuando se registren resultados.',
          )
        else
          _tableCard(standings),
        const SizedBox(height: 12),
        _role == TournamentViewerRole.participant
            ? _participantActions()
            : _publicActions(),
      ],
    );
  }

  Widget _headerCard(List<_TournamentStanding> standings) {
    final role = _role;
    final userStanding = _participantStanding(standings);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clasificación general',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role == TournamentViewerRole.participant
                ? 'Tu dupla aparece resaltada en la tabla general.'
                : 'Ordenado por partidos ganados, diferencia de games y games a favor.',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (role == TournamentViewerRole.participant) ...[
            const SizedBox(height: 14),
            if (userStanding != null)
              _participantSummaryCard(userStanding, standings)
            else
              _messageCard(
                icon: Icons.group_off_rounded,
                title: 'Buscando dupla',
                subtitle:
                    'Tu inscripción está registrada, pero aún no tienes dupla confirmada.',
              ),
          ] else if (role == TournamentViewerRole.external) ...[
            const SizedBox(height: 14),
            _publicTop3Card(standings),
          ],
        ],
      ),
    );
  }

  Widget _participantSummaryCard(
    _TournamentStanding standing,
    List<_TournamentStanding> all,
  ) {
    final position = all.indexWhere((item) => item.label == standing.label) + 1;
    final target = position > 1 ? all[position - 2] : null;
    final message = target == null
        ? 'Vas liderando la tabla.'
        : (standing.pg + 1 >= target.pg
            ? 'Estás a una victoria del ${position - 1}° puesto.'
            : 'Tu dupla sigue en carrera por el podio.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryCard(
          title: 'Tu dupla',
          subtitle: 'Posición actual: #$position',
          body: message,
          standing: standing,
          position: position,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String subtitle,
    required String body,
    required _TournamentStanding standing,
    required int position,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded,
                  size: 22, color: Color(0xFF96B21B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _duoAvatar(standing.label),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      standing.label,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.68),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _rankPill(position),
            ],
          ),
          const SizedBox(height: 12),
          _insightBanner(body),
          const SizedBox(height: 12),
          Row(
            children: [
              _statPill(label: 'PJ', value: standing.pj.toString()),
              const SizedBox(width: 8),
              _statPill(label: 'PG', value: standing.pg.toString()),
              const SizedBox(width: 8),
              _statPill(label: 'PP', value: standing.pp.toString()),
              const SizedBox(width: 8),
              _statPill(label: 'GF', value: standing.gf.toString()),
              const SizedBox(width: 8),
              _statPill(label: 'GC', value: standing.gc.toString()),
              const SizedBox(width: 8),
              _statPill(
                label: 'DG',
                value: standing.dg >= 0
                    ? '+${standing.dg}'
                    : standing.dg.toString(),
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _publicTop3Card(List<_TournamentStanding> standings) {
    final top3 = standings.take(3).toList();
    if (top3.isEmpty) {
      return _messageCard(
        icon: Icons.emoji_events_outlined,
        title: 'Top 3 del torneo',
        subtitle: 'Aún no hay resultados suficientes para mostrar el podio.',
      );
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 del torneo',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...top3.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _RankBadge(rank: entry.key + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value.label,
                          style: GoogleFonts.inter(
                            color: AppColors.SecondBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _tableCard(List<_TournamentStanding> standings) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('#',
                  style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              SizedBox(width: 10),
              Expanded(
                  flex: 4,
                  child: Text('Dupla',
                      style: TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w900))),
              _HeaderCell('PJ'),
              _HeaderCell('PG'),
              _HeaderCell('PP'),
              _HeaderCell('GF'),
              _HeaderCell('GC'),
              _HeaderCell('DG'),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...standings.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final standing = entry.value;
            final highlighted = _isCurrentUserTeam(standing.label);
            return Column(
              children: [
                Container(
                  color: highlighted
                      ? const Color(0xFFEFF8C5)
                      : Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  child: Row(
                    children: [
                      _RankBadge(rank: index),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Text(
                          standing.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _TableValue(standing.pj.toString(),
                          highlighted: highlighted),
                      _TableValue(standing.pg.toString(),
                          highlighted: highlighted),
                      _TableValue(standing.pp.toString(),
                          highlighted: highlighted),
                      _TableValue(standing.gf.toString(),
                          highlighted: highlighted),
                      _TableValue(standing.gc.toString(),
                          highlighted: highlighted),
                      _TableValue(
                        standing.dg >= 0
                            ? '+${standing.dg}'
                            : standing.dg.toString(),
                        color: standing.dg >= 0
                            ? const Color(0xFF9BBB1D)
                            : const Color(0xFFE05858),
                        highlighted: highlighted,
                      ),
                    ],
                  ),
                ),
                if (index != standings.length) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _participantActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Criterios de desempate',
            filled: false,
            onTap: () => _showTiebreakers(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Ver partidos',
            filled: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TournamentLiveScreen(tournament: _tournament),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _publicActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Ver todos los partidos',
            filled: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TournamentLiveScreen(tournament: _tournament),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            label: 'Compartir torneo',
            filled: false,
            onTap: () {
              final tournament = _tournament;
              if (tournament == null) return;
              Share.share(buildTournamentShareLink(tournament),
                  subject: tournament.title);
            },
          ),
        ),
      ],
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.SecondBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.SecondBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(String message) => _messageCard(
        icon: Icons.query_stats_rounded,
        title: 'Tabla sin datos',
        subtitle: message,
      );

  Widget _actionButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.SecondBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.SecondBlue,
                side: const BorderSide(color: Color(0xFFD4DBE6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
    );
  }

  Widget _panel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: child,
      );

  Widget _duoAvatar(String label) {
    final parts = label.split('/');
    final initials = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E3A0), width: 2),
        color: const Color(0xFFF5F8EA),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _rankPill(int position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '#$position',
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statPill({
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Expanded(
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color:
              highlighted ? const Color(0xFFF5F8EA) : const Color(0xFFF6F7FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                highlighted ? const Color(0xFFD8E3A0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: Color(0xFF96B21B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TournamentStanding? _participantStanding(
      List<_TournamentStanding> standings) {
    final tournament = _tournament;
    final profile = _profile;
    if (tournament == null || profile == null) return null;
    final entry = tournament.registrationEntries.firstWhere(
      (item) =>
          item.user.id == profile.id || item.partnerUser?.id == profile.id,
      orElse: () => const TournamentRegistrationEntry(
        id: '',
        mode: 'SOLO',
        status: 'PENDING',
        createdAt: null,
        preferredSide: null,
        availability: null,
        user: TournamentPlayer(
          id: '',
          name: '',
          email: '',
          photoUrl: null,
          category: null,
          rankingPosition: 0,
          preferredClub: null,
        ),
        partnerUser: null,
      ),
    );
    if (entry.id.isEmpty || !entry.hasPartner) return null;
    final label = _teamLabel(entry);
    return standings
        .where((standing) => standing.label == label)
        .cast<_TournamentStanding?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );
  }

  bool _isCurrentUserTeam(String label) {
    final standing = _participantStanding(
      _buildStandings(
        _tournament?.registrationEntries ?? const [],
        _data?.matches ?? const <TournamentAdminMatch>[],
      ),
    );
    return standing?.label == label;
  }

  String _teamLabel(TournamentRegistrationEntry entry) =>
      '${entry.user.name} / ${entry.partnerUser?.name ?? ''}'.trim();

  void _showTiebreakers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6C0D0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Criterios de desempate',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const _TiebreakRule(number: '1.', label: 'Partidos ganados'),
            const _TiebreakRule(number: '2.', label: 'Diferencia de games'),
            const _TiebreakRule(number: '3.', label: 'Games a favor'),
            const _TiebreakRule(number: '4.', label: 'Games en contra'),
            const _TiebreakRule(number: '5.', label: 'Resultado directo'),
          ],
        ),
      ),
    );
  }
}

class _TournamentStanding {
  const _TournamentStanding({
    required this.label,
    required this.pj,
    required this.pg,
    required this.pp,
    required this.gf,
    required this.gc,
  });

  final String label;
  final int pj;
  final int pg;
  final int pp;
  final int gf;
  final int gc;

  int get dg => gf - gc;
}

List<_TournamentStanding> _buildStandings(
  List<TournamentRegistrationEntry> registrations,
  List<TournamentAdminMatch> matches,
) {
  final standings = <String, _StandingBuilder>{};

  void ensureTeam(String label) {
    final normalized = label.trim();
    if (normalized.isEmpty || normalized == 'TBD') return;
    standings.putIfAbsent(
        normalized, () => _StandingBuilder(label: normalized));
  }

  for (final registration in registrations) {
    if (!registration.hasPartner) continue;
    ensureTeam(
        '${registration.user.name} / ${registration.partnerUser?.name ?? ''}');
  }

  for (final match in matches) {
    ensureTeam(match.teamOne);
    ensureTeam(match.teamTwo);
    if (match.status != 'FINISHED') continue;

    final builderOne = standings[match.teamOne.trim()];
    final builderTwo = standings[match.teamTwo.trim()];
    if (builderOne == null || builderTwo == null) continue;

    builderOne.pj += 1;
    builderTwo.pj += 1;

    final winner = match.winnerLabel?.trim();
    if (winner == match.teamOne.trim()) {
      builderOne.pg += 1;
      builderTwo.pp += 1;
    } else if (winner == match.teamTwo.trim()) {
      builderTwo.pg += 1;
      builderOne.pp += 1;
    }

    final parsed = _parseScore(match.score);
    if (parsed != null && winner != null && winner.isNotEmpty) {
      final first = parsed[0];
      final second = parsed[1];
      final winnerIsTeamOne = winner == match.teamOne.trim();
      final high = math.max(first, second);
      final low = math.min(first, second);
      if (winnerIsTeamOne) {
        builderOne.gf += high;
        builderOne.gc += low;
        builderTwo.gf += low;
        builderTwo.gc += high;
      } else {
        builderTwo.gf += high;
        builderTwo.gc += low;
        builderOne.gf += low;
        builderOne.gc += high;
      }
    }
  }

  final items = standings.values
      .map(
        (builder) => _TournamentStanding(
          label: builder.label,
          pj: builder.pj,
          pg: builder.pg,
          pp: builder.pp,
          gf: builder.gf,
          gc: builder.gc,
        ),
      )
      .toList();

  items.sort((left, right) {
    final wins = right.pg.compareTo(left.pg);
    if (wins != 0) return wins;
    final diff = right.dg.compareTo(left.dg);
    if (diff != 0) return diff;
    final gf = right.gf.compareTo(left.gf);
    if (gf != 0) return gf;
    return left.label.compareTo(right.label);
  });
  return items;
}

List<int>? _parseScore(String? score) {
  final value = score?.trim();
  if (value == null || value.isEmpty) return null;
  final match = RegExp(r'(\d+)\s*[-:]\s*(\d+)').firstMatch(value);
  if (match == null) return null;
  return [int.parse(match.group(1)!), int.parse(match.group(2)!)];
}

class _StandingBuilder {
  _StandingBuilder({required this.label});

  final String label;
  int pj = 0;
  int pg = 0;
  int pp = 0;
  int gf = 0;
  int gc = 0;
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE7EBF0),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TableValue extends StatelessWidget {
  const _TableValue(this.value, {this.color, this.highlighted = false});

  final String value;
  final Color? color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TiebreakRule extends StatelessWidget {
  const _TiebreakRule({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            number,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
