import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/tournament_admin_matches.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_description_screen.dart';
import 'tournament_profile_screen.dart';

class TournamentLiveScreen extends StatefulWidget {
  const TournamentLiveScreen({
    super.key,
    this.tournament,
  });

  final TournamentRecord? tournament;

  @override
  State<TournamentLiveScreen> createState() => _TournamentLiveScreenState();
}

class _TournamentLiveScreenState extends State<TournamentLiveScreen> {
  TournamentAdminMatchesData? _data;
  bool _loading = true;
  String? _error;

  String get _title => widget.tournament?.title ?? 'Torneo PGO';
  String get _category => widget.tournament?.category ?? '4TA';
  String get _photoUrl => widget.tournament?.photoUrl ?? '';

  List<TournamentAdminMatch> get _matches {
    final matches = _data?.matches ?? const <TournamentAdminMatch>[];
    final sorted = [...matches];
    sorted.sort((left, right) {
      int rank(String status) {
        return switch (status) {
          'LIVE' => 0,
          'PENDING' => 1,
          'FINISHED' => 2,
          _ => 3,
        };
      }

      return rank(left.status) - rank(right.status);
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final tournamentId = widget.tournament?.id;
    if (tournamentId == null || tournamentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se encontro el torneo.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await TournamentService().getMyTournamentMatches(tournamentId);
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

  String get _statusChipText {
    switch (widget.tournament?.status) {
      case 'DRAFT':
        return 'borrador';
      case 'PUBLISHED':
        return 'inscripciones abiertas';
      case 'COMPLETED':
        return 'torneo finalizado';
      case 'CANCELED':
        return 'torneo cancelado';
      default:
        return 'torneo activo';
    }
  }

  String _capitalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Sin definir';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}';
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
      actions: const [
        PgoOptionsMenuButton(),
      ],
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 14, 30, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTabs(context),
                    const SizedBox(height: 18),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: CircularProgressIndicator(
                            color: AppColors.SecondBlue,
                          ),
                        ),
                      )
                    else if (_error != null)
                      _buildLiveStateCard(
                        title: 'No se pudieron cargar los partidos',
                        message: _error!,
                      )
                    else if (_matches.isEmpty)
                      _buildLiveStateCard(
                        title: 'Aún no hay partidos generados',
                        message:
                            'Cuando el administrador genere los cruces, los partidos aparecerán aquí.',
                      )
                    else ...[
                      _buildSummaryStrip(),
                      const SizedBox(height: 14),
                      ..._matches.map(
                        (match) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PublicMatchCard(
                            match: match,
                            onStart: match.canManage
                                ? () => _startMyMatch(match)
                                : null,
                            onFinish: match.canManage
                                ? (winnerLabel, score) => _finishMyMatch(
                                      match,
                                      winnerLabel,
                                      score,
                                    )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startMyMatch(TournamentAdminMatch match) async {
    final tournamentId = widget.tournament?.id;
    if (tournamentId == null || tournamentId.isEmpty) return;

    try {
      await TournamentService().startTournamentMatch(
        tournamentId: tournamentId,
        matchId: match.id,
      );
      await _loadMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido iniciado')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _finishMyMatch(
    TournamentAdminMatch match,
    String winnerLabel,
    String score,
  ) async {
    final tournamentId = widget.tournament?.id;
    if (tournamentId == null || tournamentId.isEmpty) return;

    try {
      await TournamentService().finishTournamentMatch(
        tournamentId: tournamentId,
        matchId: match.id,
        winnerLabel: winnerLabel,
        score: score,
      );
      await _loadMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado registrado')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _buildHero() {
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: _photoUrl.isNotEmpty
                ? _photoUrl.startsWith('http')
                    ? Image.network(
                        _photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppAssets.defaultTournamentImage,
                          fit: BoxFit.cover,
                        ),
                      )
                    : (tryDecodeDataUrl(_photoUrl) != null
                        ? Image.memory(
                            tryDecodeDataUrl(_photoUrl)!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            AppAssets.defaultTournamentImage,
                            fit: BoxFit.cover,
                          ))
                : Image.asset(
                    AppAssets.defaultTournamentImage,
                    fit: BoxFit.cover,
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(34)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_category.toUpperCase()} categoría',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeroChip(text: _statusChipText),
                    const SizedBox(width: 10),
                    _HeroChip(
                      text: _capitalize(widget.tournament?.format ?? 'dobles'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TournamentDescriptionScreen(
                        tournament: widget.tournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Descripción',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        TournamentBracketScreen(tournament: widget.tournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Bracket',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'En vivo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        TournamentProfileScreen(tournament: widget.tournament),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Jugadores',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              value: '${data.totalMatches}',
              label: 'Partidos',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              value: '${data.liveMatches}',
              label: 'En vivo',
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              value: '${data.completedMatches}',
              label: 'Finalizados',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStateCard({
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sensors_outlined,
                size: 24,
                color: AppColors.SecondBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return PgoBottomNav(
      currentTab: PgoNavTab.tournaments,
      onHomeTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      },
      onTournamentsTap: () {},
      onProfileTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.66),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PublicMatchCard extends StatelessWidget {
  const _PublicMatchCard({
    required this.match,
    required this.onStart,
    required this.onFinish,
  });

  final TournamentAdminMatch match;
  final VoidCallback? onStart;
  final void Function(String winnerLabel, String score)? onFinish;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (match.status) {
      'LIVE' => 'En curso',
      'FINISHED' => 'Finalizado',
      _ => 'Pendiente',
    };
    final statusColor = switch (match.status) {
      'LIVE' => const Color(0xFFD7FF59),
      'FINISHED' => const Color(0xFFE7EBF0),
      _ => const Color(0xFFF4E58C),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF142743),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Text(
                    match.courtLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '- ${match.stageLabel}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _MatchTeamLine(label: match.teamOne),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFD9E0EB)),
                  const SizedBox(height: 10),
                  _MatchTeamLine(label: match.teamTwo),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.status == 'FINISHED'
                              ? 'Ganador: ${match.winnerLabel ?? 'Por definir'}${(match.score ?? '').trim().isNotEmpty ? ' ? ${match.score!.trim()}' : ''}'
                              : _formatDate(match.scheduledAt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (match.status == 'LIVE')
                        _PublicLiveBadge(
                          start: match.startedAt ?? match.scheduledAt,
                          score: match.score,
                        ),
                    ],
                  ),
                  if (match.canManage && match.status != 'FINISHED') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: match.status == 'PENDING'
                            ? onStart
                            : () => _openFinishSheet(context),
                        icon: Icon(
                          match.status == 'PENDING'
                              ? Icons.play_arrow_rounded
                              : Icons.flag_rounded,
                          size: 18,
                        ),
                        label: Text(
                          match.status == 'PENDING'
                              ? 'Iniciar mi partido'
                              : 'Registrar resultado',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7FF59),
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} - $hour:$minute';
  }

  Future<void> _openFinishSheet(BuildContext context) async {
    final result = await showModalBottomSheet<({String winner, String score})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FinishTournamentMatchSheet(match: match),
    );

    if (result == null) return;
    onFinish?.call(result.winner, result.score);
  }
}

class _FinishTournamentMatchSheet extends StatefulWidget {
  const _FinishTournamentMatchSheet({required this.match});

  final TournamentAdminMatch match;

  @override
  State<_FinishTournamentMatchSheet> createState() =>
      _FinishTournamentMatchSheetState();
}

class _FinishTournamentMatchSheetState
    extends State<_FinishTournamentMatchSheet> {
  late String _winnerLabel;
  final _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _winnerLabel = widget.match.teamOne;
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 86,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFB9C2D0),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Registrar resultado',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige ganador y puntaje final de tu partido.',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.66),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _WinnerOption(
              label: widget.match.teamOne,
              selected: _winnerLabel == widget.match.teamOne,
              onTap: () => setState(() => _winnerLabel = widget.match.teamOne),
            ),
            const SizedBox(height: 10),
            _WinnerOption(
              label: widget.match.teamTwo,
              selected: _winnerLabel == widget.match.teamTwo,
              onTap: () => setState(() => _winnerLabel = widget.match.teamTwo),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Puntaje, ej. 6-4, 3-6, 10-8',
                hintStyle: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Guardar resultado'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final score = _scoreController.text.trim();
    if (score.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el puntaje del partido')),
      );
      return;
    }

    Navigator.of(context).pop((winner: _winnerLabel, score: score));
  }
}

class _WinnerOption extends StatelessWidget {
  const _WinnerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? const Color(0xFFD7FF59) : const Color(0xFFE4E8EE),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFD7FF59)
                    : const Color(0xFFB7C0CE),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicLiveBadge extends StatefulWidget {
  const _PublicLiveBadge({
    required this.start,
    required this.score,
  });

  final DateTime start;
  final String? score;

  @override
  State<_PublicLiveBadge> createState() => _PublicLiveBadgeState();
}

class _PublicLiveBadgeState extends State<_PublicLiveBadge> {
  late final ValueNotifier<DateTime> _now;

  @override
  void initState() {
    super.initState();
    _now = ValueNotifier<DateTime>(DateTime.now());
    _loop();
  }

  void _loop() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _now.value = DateTime.now();
    }
  }

  @override
  void dispose() {
    _now.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _now,
      builder: (context, now, _) {
        final elapsed = now.difference(widget.start.toLocal());
        final safeElapsed = elapsed.isNegative ? Duration.zero : elapsed;
        final minutes = safeElapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (safeElapsed.inSeconds % 60).toString().padLeft(2, '0');
        final score = widget.score?.trim();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3D4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'LIVE $minutes:$seconds${score != null && score.isNotEmpty ? ' - $score' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}

class _MatchTeamLine extends StatelessWidget {
  const _MatchTeamLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.whatshot,
            size: 14,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
