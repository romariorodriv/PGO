import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/tournament_admin_bracket.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_admin_matches_screen.dart';
import 'tournament_admin_registrations_screen.dart';
import 'tournament_admin_screen.dart';

class TournamentAdminBracketScreen extends StatefulWidget {
  const TournamentAdminBracketScreen({
    super.key,
    required this.tournament,
  });

  final TournamentRecord tournament;

  @override
  State<TournamentAdminBracketScreen> createState() =>
      _TournamentAdminBracketScreenState();
}

class _TournamentAdminBracketScreenState
    extends State<TournamentAdminBracketScreen> {
  String? _stageKey;
  TournamentAdminBracketData? _data;
  bool _isLoading = false;
  String? _error;

  TournamentRecord get _tournament => widget.tournament;

  List<TournamentAdminBracketMatch> get _matches {
    final stageKeys = _data?.stageKeys ?? const <String>[];
    final stageKey =
        _stageKey ?? (stageKeys.isNotEmpty ? stageKeys.first : null);
    final matches =
        _data?.stages[stageKey] ?? const <TournamentAdminBracketMatch>[];
    return [...matches]..sort(_compareMatchesByCourt);
  }

  int _compareMatchesByCourt(
    TournamentAdminBracketMatch left,
    TournamentAdminBracketMatch right,
  ) {
    final courtCompare =
        _courtNumber(left.courtLabel).compareTo(_courtNumber(right.courtLabel));
    if (courtCompare != 0) return courtCompare;
    return left.scheduledAt.compareTo(right.scheduledAt);
  }

  int _courtNumber(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 999;
  }

  Future<void> _startVisiblePendingMatches() async {
    final pending = _matches
        .where(
          (match) =>
              match.status == 'PENDING' &&
              match.teamOne.trim() != 'TBD' &&
              match.teamTwo.trim() != 'TBD',
        )
        .toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay partidos pendientes en esta ronda')),
      );
      return;
    }

    try {
      for (final match in pending) {
        await TournamentService().startAdminMatch(
          tournamentId: _tournament.id,
          matchId: match.id,
        );
      }
      if (!mounted) return;
      await _loadBracket();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pending.length} partidos iniciados')),
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
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await TournamentService().getAdminBracket(_tournament.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _stageKey = data.stageKeys.contains(_stageKey)
            ? _stageKey
            : (data.stageKeys.isNotEmpty ? data.stageKeys.first : null);
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
          onRefresh: _loadBracket,
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
                  current: _AdminTournamentTab.bracket,
                  tournament: _tournament,
                ),
                const SizedBox(height: 12),
                if ((_data?.stageKeys.length ?? 0) > 1) ...[
                  _StageFilterBar(
                    stageKeys: _data?.stageKeys ?? const [],
                    selected: _stageKey,
                    onChanged: (stage) => setState(() => _stageKey = stage),
                  ),
                  const SizedBox(height: 14),
                ],
                const _InstructionCard(
                  label: 'Toca un partido para operar',
                ),
                if (_matches.any(
                  (match) =>
                      match.status == 'PENDING' &&
                      match.teamOne.trim() != 'TBD' &&
                      match.teamTwo.trim() != 'TBD',
                )) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _startVisiblePendingMatches,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.SecondBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text(
                        'INICIAR RONDA COMPLETA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  _MessageCard(message: _error!)
                else if (_matches.isEmpty)
                  const _MessageCard(
                      message: 'Aún no hay cruces para esta ronda.')
                else
                  ..._matches.map(
                    (match) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BracketMatchCard(
                        match: match,
                        tournament: _tournament,
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
                    '${tournament.category.toUpperCase()} categoría',
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
          _TabButton(
            label: 'Bracket',
            selected: current == _AdminTournamentTab.bracket,
            onTap: () {},
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

class _StageFilterBar extends StatelessWidget {
  const _StageFilterBar({
    required this.stageKeys,
    required this.selected,
    required this.onChanged,
  });

  final List<String> stageKeys;
  final String? selected;
  final ValueChanged<String> onChanged;

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
        children: stageKeys
            .map(
              (stage) => _StageButton(
                label: _stageLabel(stage),
                selected: selected == stage,
                onTap: () => onChanged(stage),
              ),
            )
            .toList(),
      ),
    );
  }

  String _stageLabel(String stage) {
    if (stage == 'final') return 'Final';
    if (stage.startsWith('juego-')) {
      final number = stage.replaceFirst('juego-', '');
      return 'Juego $number';
    }
    if (stage == 'semis') return 'Semis';
    return '${stage[0].toUpperCase()}${stage.substring(1)}';
  }
}

class _StageButton extends StatelessWidget {
  const _StageButton({
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

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE7EBF0),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  const _BracketMatchCard({
    required this.match,
    required this.tournament,
  });

  final TournamentAdminBracketMatch match;
  final TournamentRecord tournament;

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

    return GestureDetector(
      onTap: () {
        final initialFilter = switch (match.status) {
          'LIVE' => 'live',
          'FINISHED' => 'finished',
          _ => 'pending',
        };
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TournamentAdminMatchesScreen(
              tournament: tournament,
              initialFilter: initialFilter,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF142743),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                  Text(
                    match.teamOne,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFD9E0EB)),
                  const SizedBox(height: 10),
                  Text(
                    match.teamTwo,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.status == 'FINISHED'
                          ? match.winnerLabel ?? _formatDate(match.scheduledAt)
                          : _formatDate(match.scheduledAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (match.status == 'LIVE') ...[
                    _BracketLiveBadge(
                      start: match.startedAt ?? match.scheduledAt,
                      score: match.score,
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
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]} · $hour:$minute';
  }
}

class _BracketLiveBadge extends StatefulWidget {
  const _BracketLiveBadge({
    required this.start,
    required this.score,
  });

  final DateTime start;
  final String? score;

  @override
  State<_BracketLiveBadge> createState() => _BracketLiveBadgeState();
}

class _BracketLiveBadgeState extends State<_BracketLiveBadge> {
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
