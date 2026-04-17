import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/tournament_admin_matches.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_admin_bracket_screen.dart';
import 'tournament_admin_registrations_screen.dart';
import 'tournament_admin_screen.dart';

class TournamentAdminMatchesScreen extends StatefulWidget {
  const TournamentAdminMatchesScreen({
    super.key,
    required this.tournament,
    this.initialFilter = 'all',
  });

  final TournamentRecord tournament;
  final String initialFilter;

  @override
  State<TournamentAdminMatchesScreen> createState() =>
      _TournamentAdminMatchesScreenState();
}

class _TournamentAdminMatchesScreenState
    extends State<TournamentAdminMatchesScreen> {
  _AdminMatchFilter _filter = _AdminMatchFilter.all;
  TournamentAdminMatchesData? _data;
  bool _isLoading = false;
  String? _error;

  TournamentRecord get _tournament => widget.tournament;

  List<TournamentAdminMatch> get _matches {
    final all = _data?.matches ?? const <TournamentAdminMatch>[];
    switch (_filter) {
      case _AdminMatchFilter.all:
        return all;
      case _AdminMatchFilter.pending:
        return all.where((match) => match.status == 'PENDING').toList();
      case _AdminMatchFilter.live:
        return all.where((match) => match.status == 'LIVE').toList();
      case _AdminMatchFilter.finished:
        return all.where((match) => match.status == 'FINISHED').toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _filter = _parseInitialFilter(widget.initialFilter);
    _loadMatches();
  }

  _AdminMatchFilter _parseInitialFilter(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return _AdminMatchFilter.pending;
      case 'live':
        return _AdminMatchFilter.live;
      case 'finished':
        return _AdminMatchFilter.finished;
      default:
        return _AdminMatchFilter.all;
    }
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await TournamentService().getAdminMatches(_tournament.id);
      if (!mounted) return;
      setState(() {
        _data = data;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startMatch(TournamentAdminMatch match) async {
    try {
      await TournamentService().startAdminMatch(
        tournamentId: _tournament.id,
        matchId: match.id,
      );
      if (!mounted) return;
      await _loadMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${match.courtLabel} paso a En curso.')),
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

  Future<void> _finishMatch(
    TournamentAdminMatch match,
    String winnerLabel,
  ) async {
    try {
      await TournamentService().finishAdminMatch(
        tournamentId: _tournament.id,
        matchId: match.id,
        winnerLabel: winnerLabel,
      );
      if (!mounted) return;
      await _loadMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ganador registrado: $winnerLabel')),
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

  Future<void> _correctMatchResult(
    TournamentAdminMatch match,
    String winnerLabel,
  ) async {
    try {
      await TournamentService().correctAdminMatchResult(
        tournamentId: _tournament.id,
        matchId: match.id,
        winnerLabel: winnerLabel,
      );
      if (!mounted) return;
      await _loadMatches();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resultado corregido: $winnerLabel')),
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

  @override
  Widget build(BuildContext context) {
    final total = _data?.totalMatches ?? 0;
    final completed = _data?.completedMatches ?? 0;
    final live = _data?.liveMatches ?? 0;

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Panel de torneo',
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
        child: RefreshIndicator(
          onRefresh: _loadMatches,
          color: AppColors.SecondBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(
                  tournament: _tournament,
                  completed: completed,
                  live: live,
                  total: total,
                ),
                const SizedBox(height: 12),
                _AdminTopTabs(
                  current: _AdminTournamentTab.matches,
                  tournament: _tournament,
                ),
                const SizedBox(height: 12),
                _MatchFilterBar(
                  filter: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 14),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  _MessageCard(message: _error!)
                else if (_matches.isEmpty)
                  const _EmptyCard()
                else
                  ..._matches.map(
                    (match) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminMatchCard(
                        match: match,
                        onStart: () => _startMatch(match),
                        onFinish: (winnerLabel) =>
                            _finishMatch(match, winnerLabel),
                        onCorrectResult: (winnerLabel) =>
                            _correctMatchResult(match, winnerLabel),
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

enum _AdminTournamentTab { summary, registrations, matches, bracket }

enum _AdminMatchFilter { all, pending, live, finished }

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.tournament,
    required this.completed,
    required this.live,
    required this.total,
  });

  final TournamentRecord tournament;
  final int completed;
  final int live;
  final int total;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(tournament.photoUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tournament.photoUrl != null && tournament.photoUrl!.isNotEmpty)
              tournament.photoUrl!.startsWith('http')
                  ? Image.network(
                      tournament.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppAssets.defaultTournamentImage,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Image.asset(
                          AppAssets.defaultTournamentImage,
                          fit: BoxFit.cover,
                        ))
            else
              Image.asset(
                AppAssets.defaultTournamentImage,
                fit: BoxFit.cover,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$completed de $total partidos completados · $live partidos en curso',
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${tournament.category.toUpperCase()} categoria',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDate(tournament.startsAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} · $hour:$minute';
  }
}

class _AdminTopTabs extends StatelessWidget {
  const _AdminTopTabs({
    required this.current,
    required this.tournament,
  });

  final _AdminTournamentTab current;
  final TournamentRecord tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Resumen',
            selected: current == _AdminTournamentTab.summary,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminScreen(
                    tournament: tournament,
                  ),
                ),
              );
            },
          ),
          _TabButton(
            label: 'Inscritos',
            selected: current == _AdminTournamentTab.registrations,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminRegistrationsScreen(
                    tournament: tournament,
                  ),
                ),
              );
            },
          ),
          _TabButton(
            label: 'Partidos',
            selected: current == _AdminTournamentTab.matches,
            onTap: () {},
          ),
          _TabButton(
            label: 'Bracket',
            selected: current == _AdminTournamentTab.bracket,
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminBracketScreen(
                    tournament: tournament,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.secondaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.84),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchFilterBar extends StatelessWidget {
  const _MatchFilterBar({
    required this.filter,
    required this.onChanged,
  });

  final _AdminMatchFilter filter;
  final ValueChanged<_AdminMatchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'Todos',
            selected: filter == _AdminMatchFilter.all,
            onTap: () => onChanged(_AdminMatchFilter.all),
          ),
          _FilterButton(
            label: 'Pendientes',
            selected: filter == _AdminMatchFilter.pending,
            onTap: () => onChanged(_AdminMatchFilter.pending),
          ),
          _FilterButton(
            label: 'En curso',
            selected: filter == _AdminMatchFilter.live,
            onTap: () => onChanged(_AdminMatchFilter.live),
          ),
          _FilterButton(
            label: 'Finalizados',
            selected: filter == _AdminMatchFilter.finished,
            onTap: () => onChanged(_AdminMatchFilter.finished),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.secondaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.84),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMatchCard extends StatelessWidget {
  const _AdminMatchCard({
    required this.match,
    required this.onStart,
    required this.onFinish,
    required this.onCorrectResult,
  });

  final TournamentAdminMatch match;
  final Future<void> Function() onStart;
  final Future<void> Function(String winnerLabel) onFinish;
  final Future<void> Function(String winnerLabel) onCorrectResult;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (match.status) {
      'PENDING' => 'Pendiente',
      'LIVE' => 'En curso',
      'FINISHED' => 'Finalizado',
      _ => 'Pendiente',
    };
    final statusColor = switch (match.status) {
      'PENDING' => const Color(0xFFF4E58C),
      'LIVE' => const Color(0xFFD7FF59),
      'FINISHED' => const Color(0xFFE7EBF0),
      _ => const Color(0xFFF4E58C),
    };
    final actionLabel = switch (match.status) {
      'PENDING' => 'Iniciar',
      'LIVE' => 'Registrar ganador',
      'FINISHED' => 'Ver resultado',
      _ => 'Iniciar',
    };
    final actionFilled = match.status != 'FINISHED';

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
                    '? ${match.stageLabel}',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.teamOne,
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () {
                            if (match.status == 'PENDING') {
                              showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => _StartMatchDialog(
                                  match: match,
                                  onConfirm: onStart,
                                ),
                              );
                              return;
                            }

                            if (match.status == 'LIVE') {
                              showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) => _RegisterWinnerDialog(
                                  match: match,
                                  onConfirm: onFinish,
                                ),
                              );
                              return;
                            }

                            showDialog<void>(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => _MatchResultDialog(
                                match: match,
                                onCorrectResult: onCorrectResult,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionFilled
                                ? const Color(0xFFD7FF59)
                                : const Color(0xFF8C94A4),
                            foregroundColor: actionFilled
                                ? AppColors.SecondBlue
                                : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFD9E0EB)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      match.teamTwo,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _AdminMatchCardFooter(match: match),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMatchCardFooter extends StatelessWidget {
  const _AdminMatchCardFooter({
    required this.match,
  });

  final TournamentAdminMatch match;

  @override
  Widget build(BuildContext context) {
    if (match.status == 'LIVE') {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3D4A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _LiveElapsedText(start: match.startedAt ?? match.scheduledAt),
        ],
      );
    }

    if (match.status == 'FINISHED') {
      final winner =
          (match.winnerLabel ?? '').replaceFirst('Ganador: ', '').trim();
      return RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          children: [
            const TextSpan(
              text: 'Ganador: ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: winner.isNotEmpty ? winner : match.teamOne),
          ],
        ),
      );
    }

    return Text(
      _formatDate(match.scheduledAt),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 12,
        fontWeight: FontWeight.w700,
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
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} ? $hour:$minute';
  }
}

class _LiveElapsedText extends StatefulWidget {
  const _LiveElapsedText({
    required this.start,
  });

  final DateTime start;

  @override
  State<_LiveElapsedText> createState() => _LiveElapsedTextState();
}

class _LiveElapsedTextState extends State<_LiveElapsedText> {
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
        return Text(
          '$minutes:$seconds',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}

class _StartMatchDialog extends StatefulWidget {
  const _StartMatchDialog({
    required this.match,
    required this.onConfirm,
  });

  final TournamentAdminMatch match;
  final Future<void> Function() onConfirm;

  @override
  State<_StartMatchDialog> createState() => _StartMatchDialogState();
}

class _StartMatchDialogState extends State<_StartMatchDialog> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Iniciar partido',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFDCE3EC),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.match.courtLabel} - ${widget.match.stageLabel}',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    widget.match.teamOne,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFD9E0EB)),
                  const SizedBox(height: 10),
                  Text(
                    widget.match.teamTwo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.78),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(text: 'Este partido pasara a estado '),
                  TextSpan(
                    text: '"En curso"',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              try {
                                await widget.onConfirm();
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Iniciar partido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterWinnerDialog extends StatefulWidget {
  const _RegisterWinnerDialog({
    required this.match,
    required this.onConfirm,
  });

  final TournamentAdminMatch match;
  final Future<void> Function(String winnerLabel) onConfirm;

  @override
  State<_RegisterWinnerDialog> createState() => _RegisterWinnerDialogState();
}

class _RegisterWinnerDialogState extends State<_RegisterWinnerDialog> {
  late String _selectedWinner;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedWinner = widget.match.teamOne;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Registrar ganador',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFDCE3EC),
            ),
            const SizedBox(height: 14),
            const Text(
              '¿Quien gano el partido?',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _WinnerOption(
              label: widget.match.teamOne,
              selected: _selectedWinner == widget.match.teamOne,
              onTap: () =>
                  setState(() => _selectedWinner = widget.match.teamOne),
            ),
            const SizedBox(height: 8),
            _WinnerOption(
              label: widget.match.teamTwo,
              selected: _selectedWinner == widget.match.teamTwo,
              onTap: () =>
                  setState(() => _selectedWinner = widget.match.teamTwo),
            ),
            const SizedBox(height: 10),
            Text(
              'El cuadro se actualizara automaticamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              try {
                                await widget.onConfirm(_selectedWinner);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Confirmar ganador',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FF59) : const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFD7FF59) : const Color(0xFFDCE3EC),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: AppColors.SecondBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchResultDialog extends StatelessWidget {
  const _MatchResultDialog({
    required this.match,
    required this.onCorrectResult,
  });

  final TournamentAdminMatch match;
  final Future<void> Function(String winnerLabel) onCorrectResult;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resultado del partido',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFDCE3EC),
            ),
            const SizedBox(height: 12),
            Text(
              '${match.courtLabel} - ${match.stageLabel}',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.SecondBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _winnerTeamLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _loserTeamLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Estado: Finalizado',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ganador: $_winnerTeamLabel',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog<void>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => _CorrectMatchResultDialog(
                            match: match,
                            onConfirm: onCorrectResult,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Corregir resultado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _winnerTeamLabel {
    final winner = match.winnerLabel?.replaceFirst('Ganador: ', '').trim();
    if (winner != null && winner.isNotEmpty) {
      return winner;
    }
    return match.teamOne;
  }

  String get _loserTeamLabel {
    return _winnerTeamLabel == match.teamOne ? match.teamTwo : match.teamOne;
  }
}

class _CorrectMatchResultDialog extends StatefulWidget {
  const _CorrectMatchResultDialog({
    required this.match,
    required this.onConfirm,
  });

  final TournamentAdminMatch match;
  final Future<void> Function(String winnerLabel) onConfirm;

  @override
  State<_CorrectMatchResultDialog> createState() =>
      _CorrectMatchResultDialogState();
}

class _CorrectMatchResultDialogState extends State<_CorrectMatchResultDialog> {
  late String _selectedWinner;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final winner =
        widget.match.winnerLabel?.replaceFirst('Ganador: ', '').trim();
    _selectedWinner =
        (winner != null && winner.isNotEmpty) ? winner : widget.match.teamOne;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Corregir resultado',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFDCE3EC),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.match.courtLabel} - ${widget.match.stageLabel}',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Resultado actual',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ganador: ${widget.match.winnerLabel?.replaceFirst('Ganador: ', '').trim().isNotEmpty == true ? widget.match.winnerLabel!.replaceFirst('Ganador: ', '').trim() : widget.match.teamOne}',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona el ganador correcto',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _WinnerOption(
              label: widget.match.teamOne,
              selected: _selectedWinner == widget.match.teamOne,
              onTap: () =>
                  setState(() => _selectedWinner = widget.match.teamOne),
            ),
            const SizedBox(height: 8),
            _WinnerOption(
              label: widget.match.teamTwo,
              selected: _selectedWinner == widget.match.teamTwo,
              onTap: () =>
                  setState(() => _selectedWinner = widget.match.teamTwo),
            ),
            const SizedBox(height: 12),
            Text(
              'El bracket se actualizara automaticamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              try {
                                await widget.onConfirm(_selectedWinner);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              } finally {
                                if (mounted) {
                                  setState(() => _submitting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Guardar cambio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Aún no hay cruces suficientes para generar partidos.',
        style: TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
