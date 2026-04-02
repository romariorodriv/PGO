import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../models/profile_history.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'main_shell.dart';
import 'profile_screen.dart';

enum _HistoryFilter {
  all,
  wins,
  losses,
}

class ProfileHistoryScreen extends StatefulWidget {
  const ProfileHistoryScreen({super.key});

  @override
  State<ProfileHistoryScreen> createState() => _ProfileHistoryScreenState();
}

class _ProfileHistoryScreenState extends State<ProfileHistoryScreen> {
  ProfileHistory? _history;
  bool _isLoading = true;
  String? _error;
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ProfileService().getMyHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _error = null;
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
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Historial',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: const [
        PgoOptionsMenuButton(),
      ],
      body: ColoredBox(
        color: const Color(0xFFF7F7F8),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _HistoryErrorState(
                      message: _error!,
                      onRetry: _loadHistory,
                    )
                  : _history == null
                      ? _HistoryErrorState(
                          message: 'No se encontro historial.',
                          onRetry: _loadHistory,
                        )
                      : _HistoryContent(
                          history: _history!,
                          selectedFilter: _selectedFilter,
                          onFilterChanged: (filter) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
        ),
      ),
      bottomNavigationBar: PgoBottomNav(
        currentTab: PgoNavTab.profile,
        onHomeTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.home);
        },
        onTournamentsTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.tournaments);
        },
        onProfileTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
        },
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.history,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ProfileHistory history;
  final _HistoryFilter selectedFilter;
  final ValueChanged<_HistoryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filterHistory(history.history, selectedFilter);
    final groupedHistory = _groupHistoryByMonth(filteredHistory);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 250,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(
              history: history,
              selectedFilter: selectedFilter,
              onFilterChanged: onFilterChanged,
            ),
            const SizedBox(height: 18),
            if (groupedHistory.isEmpty)
              const _EmptyHistoryState()
            else
              ...groupedHistory.entries.expand((entry) {
                return [
                  _MonthHeader(label: entry.key),
                  const SizedBox(height: 10),
                  _MonthHistoryCard(matches: entry.value),
                  const SizedBox(height: 16),
                ];
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.history,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ProfileHistory history;
  final _HistoryFilter selectedFilter;
  final ValueChanged<_HistoryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('${history.matchesPlayed}', 'Partidos'),
      ('${history.wins}', 'Victorias'),
      ('${history.winRate.round()} %', 'Win rate'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Row(
            children: stats
                .map(
                  (item) => Expanded(
                    child: Column(
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: TextStyle(
                            color: AppColors.SecondBlue.withValues(alpha: 0.62),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FilterPill(
                  label: 'Todos',
                  selected: selectedFilter == _HistoryFilter.all,
                  onTap: () => onFilterChanged(_HistoryFilter.all),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterPill(
                  label: 'Ganados',
                  selected: selectedFilter == _HistoryFilter.wins,
                  onTap: () => onFilterChanged(_HistoryFilter.wins),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterPill(
                  label: 'Perdidos',
                  selected: selectedFilter == _HistoryFilter.losses,
                  onTap: () => onFilterChanged(_HistoryFilter.losses),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FF59) : const Color(0xFFE5E8EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(
              alpha: selected ? 1 : 0.72,
            ),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' ');

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Text(
            parts.first,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.74),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (parts.length > 1) ...[
            const SizedBox(width: 8),
            Text(
              parts.sublist(1).join(' '),
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHistoryCard extends StatelessWidget {
  const _MonthHistoryCard({
    required this.matches,
  });

  final List<ProfileHistoryMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: profileCardDecoration(),
      child: Column(
        children: matches
            .asMap()
            .entries
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  top: entry.key == 0 ? 0 : 10,
                  bottom: entry.key == matches.length - 1 ? 0 : 10,
                ),
                child: _HistoryMatchRow(match: entry.value),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _HistoryMatchRow extends StatelessWidget {
  const _HistoryMatchRow({
    required this.match,
  });

  final ProfileHistoryMatch match;

  @override
  Widget build(BuildContext context) {
    final isWin = match.result == 'WIN';
    final accentColor =
        isWin ? AppColors.PrimaryGreen : const Color(0xFFFF334B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isWin ? Icons.check : Icons.close,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.title,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _buildSubtitle(match),
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.68),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMM yyyy', 'es').format(match.playedAt),
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.44),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${match.xpDelta >= 0 ? '+' : ''}${match.xpDelta} XP',
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(ProfileHistoryMatch match) {
    if (match.subtitle.isNotEmpty) {
      return '${match.matchTypeLabel} - ${match.subtitle}';
    }
    return '${match.matchTypeLabel} - ${match.clubName}';
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 42,
            color: AppColors.SecondBlue.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Aun no tienes historial registrado.',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando registres partidos, apareceran aqui agrupados por mes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.5),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_edu_outlined,
              color: AppColors.SecondBlue,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7FF59),
                foregroundColor: AppColors.SecondBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ProfileHistoryMatch> _filterHistory(
  List<ProfileHistoryMatch> history,
  _HistoryFilter filter,
) {
  switch (filter) {
    case _HistoryFilter.wins:
      return history.where((item) => item.result == 'WIN').toList();
    case _HistoryFilter.losses:
      return history.where((item) => item.result == 'LOSS').toList();
    case _HistoryFilter.all:
      return history;
  }
}

Map<String, List<ProfileHistoryMatch>> _groupHistoryByMonth(
  List<ProfileHistoryMatch> history,
) {
  final grouped = <String, List<ProfileHistoryMatch>>{};

  for (final match in history) {
    final key =
        DateFormat('MMMM yyyy', 'es').format(match.playedAt).toUpperCase();
    grouped.putIfAbsent(key, () => []).add(match);
  }

  return grouped;
}

extension on ProfileHistoryMatch {
  String get matchTypeLabel {
    switch (matchType.toUpperCase()) {
      case 'RANKED':
        return 'Torneo PGO';
      case 'FRIENDLY':
        return 'Partido amistoso';
      default:
        return 'Partido';
    }
  }
}
