import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../models/tournament_admin_matches.dart';
import '../models/tournament_record.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'tournament_admin_matches_screen.dart';
import 'tournament_admin_registrations_screen.dart';

enum _AdminTab { summary, registrations, matches, table }

enum _AdminInlineRegistrationFilter { all, withPartner, solo }

enum _AdminInlineMatchFilter { all, pending, live, finished }

class TournamentAdminScreen extends StatefulWidget {
  const TournamentAdminScreen({
    super.key,
    required this.tournament,
    this.initialTabIndex = 0,
  });

  final TournamentRecord tournament;
  final int initialTabIndex;

  @override
  State<TournamentAdminScreen> createState() => _TournamentAdminScreenState();
}

class _TournamentAdminScreenState extends State<TournamentAdminScreen> {
  TournamentRecord? _tournament;
  bool _isLoading = false;
  bool _isLoadingMatches = false;
  bool _isUpdatingRegistrations = false;
  String? _error;
  String? _matchesError;
  _AdminTab _selectedTab = _AdminTab.summary;
  _AdminInlineRegistrationFilter _registrationFilter =
      _AdminInlineRegistrationFilter.all;
  TournamentAdminMatchesData? _adminMatchesData;

  TournamentRecord get _currentTournament => _tournament ?? widget.tournament;

  List<TournamentRegistrationEntry> get _filteredRegistrationEntries {
    final entries = _currentTournament.registrationEntries;
    switch (_registrationFilter) {
      case _AdminInlineRegistrationFilter.all:
        return entries;
      case _AdminInlineRegistrationFilter.withPartner:
        return entries.where((entry) => entry.hasPartner).toList();
      case _AdminInlineRegistrationFilter.solo:
        return entries.where((entry) => !entry.hasPartner).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _selectedTab = _tabFromIndex(widget.initialTabIndex);
    _loadTournament();
    _loadAdminMatches();
  }

  _AdminTab _tabFromIndex(int index) {
    if (index < 0 || index >= _AdminTab.values.length) {
      return _AdminTab.summary;
    }
    return _AdminTab.values[index];
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament =
          await TournamentService().getTournament(_currentTournament.id);
      if (!mounted) return;
      setState(() {
        _tournament = tournament;
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

  Future<void> _loadAdminMatches() async {
    setState(() {
      _isLoadingMatches = true;
      _matchesError = null;
    });

    try {
      final data =
          await TournamentService().getAdminMatches(_currentTournament.id);
      if (!mounted) return;
      setState(() {
        _adminMatchesData = data;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _matchesError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMatches = false;
        });
      }
    }
  }

  Future<void> _toggleRegistrations() async {
    if (_currentTournament.registrationsOpen) {
      final shouldClose = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => _CloseRegistrationsOnlyDialog(
          isComplete: _currentTournament.registrationsCount >=
              _currentTournament.playerCapacity,
          onGenerateBrackets: () async {
            Navigator.of(context).pop(true);
          },
        ),
      );

      if (shouldClose != true) {
        return;
      }
    }

    setState(() {
      _isUpdatingRegistrations = true;
    });

    try {
      late TournamentRecord updated;
      if (_currentTournament.registrationsOpen) {
        updated = await TournamentService().updateTournament(
          tournamentId: _currentTournament.id,
          registrationsOpen: false,
        );
      } else {
        updated = await TournamentService().updateTournament(
          tournamentId: _currentTournament.id,
          registrationsOpen: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _tournament = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.registrationsOpen
                ? 'Inscripciónes abiertas nuevamente'
                : 'Inscripciones cerradas',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingRegistrations = false;
        });
      }
    }
  }

  void _selectTab(_AdminTab tab) {
    if (tab == _AdminTab.matches) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TournamentAdminMatchesScreen(
            tournament: _currentTournament,
          ),
        ),
      );
      return;
    }

    setState(() => _selectedTab = tab);
  }

  // ignore: unused_element
  String get _formattedHeroDate {
    final date = _currentTournament.startsAt.toLocal();
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

    final weekday = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$weekday ${date.day} $month ? $hour:$minute';
  }

  List<String> get _recentActivity {
    final entries = [..._currentTournament.registrationEntries]
      ..sort((left, right) {
        final leftDate =
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightDate.compareTo(leftDate);
      });

    if (entries.isEmpty) {
      return const ['Aún no hay actividad reciente'];
    }

    final items = <String>[];
    for (final entry in entries.take(2)) {
      if (entry.hasPartner) {
        items.add(
          '${entry.user.name} y ${entry.partnerUser?.name ?? ''} se inscribieron',
        );
      } else {
        items.add('${entry.user.name} esta buscando pareja');
      }
    }
    items.add(
      '${_currentTournament.registrationsCount} de ${_currentTournament.playerCapacity} cupos completados',
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

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
          'Panel de torneo',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
            onRefresh: _loadTournament,
            color: AppColors.SecondBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminHeroCard(
                    tournament: _currentTournament,
                    formattedDate: _formattedHeroDate,
                  ),
                  const SizedBox(height: 12),
                  _buildTabs(context),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PanelCard(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: _buildSelectedTabContent(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            child: _AdminTabButton(
              label: 'Resumen',
              selected: _selectedTab == _AdminTab.summary,
              onTap: () => _selectTab(_AdminTab.summary),
            ),
          ),
          Expanded(
            child: _AdminTabButton(
              label: 'Inscritos',
              selected: _selectedTab == _AdminTab.registrations,
              onTap: () => _selectTab(_AdminTab.registrations),
            ),
          ),
          Expanded(
            child: _AdminTabButton(
              label: 'Partidos',
              selected: _selectedTab == _AdminTab.matches,
              onTap: () => _selectTab(_AdminTab.matches),
            ),
          ),
          Expanded(
            child: _AdminTabButton(
              label: 'Tabla',
              selected: _selectedTab == _AdminTab.table,
              onTap: () => _selectTab(_AdminTab.table),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context) {
    switch (_selectedTab) {
      case _AdminTab.summary:
        return Column(
          children: [
            _buildRegistrationsCard(context),
            const SizedBox(height: 12),
            _buildSummaryCard(),
            const SizedBox(height: 12),
            _buildRecentActivityCard(),
          ],
        );
      case _AdminTab.registrations:
        return _buildInlineRegistrationsPanel();
      case _AdminTab.matches:
        return const SizedBox.shrink();
      case _AdminTab.table:
        return _buildTablePanel(context);
    }
  }

  Widget _buildTablePanel(BuildContext context) {
    final data = _adminMatchesData;
    final standings = _buildStandings(
      _currentTournament.registrationEntries,
      data?.matches ?? const <TournamentAdminMatch>[],
    );
    final totalMatches = data?.totalMatches ?? 0;
    final completedMatches = data?.completedMatches ?? 0;
    final liveMatches = data?.liveMatches ?? 0;
    final pendingMatches =
        math.max(0, totalMatches - completedMatches - liveMatches);
    final progress = totalMatches == 0
        ? 0.0
        : (completedMatches / totalMatches).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelCard(
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
                'Ordenado por partidos ganados, diferencia de games y games a favor.',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.68),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TableStatChip(
                      icon: Icons.groups_rounded,
                      value: '${standings.length}',
                      label: 'Duplas',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TableStatChip(
                      icon: Icons.emoji_events_rounded,
                      value: '$completedMatches',
                      label: 'Partidos jugados',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TableStatChip(
                      icon: Icons.schedule_rounded,
                      value: '$pendingMatches',
                      label: 'Partidos pendientes',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TableStatChip(
                      icon: Icons.query_stats_rounded,
                      value: '${(progress * 100).round()}%',
                      label: 'Progreso',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFE3E7EE),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.PrimaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingMatches)
          const _PanelCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_matchesError != null)
          _PanelCard(
            child: Text(
              _matchesError!,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else ...[
          _PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '#',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      flex: 4,
                      child: Text(
                        'Dupla',
                        style: TextStyle(
                          color: AppColors.SecondBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    for (final label in const [
                      'PJ',
                      'PG',
                      'PP',
                      'GF',
                      'GC',
                      'DG'
                    ])
                      Expanded(
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
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                if (standings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Aún no hay datos suficientes para mostrar la tabla.',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.66),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...standings.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final standing = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                              _TableValue(standing.pj.toString()),
                              _TableValue(standing.pg.toString()),
                              _TableValue(standing.pp.toString()),
                              _TableValue(standing.gf.toString()),
                              _TableValue(standing.gc.toString()),
                              _TableValue(
                                standing.dg >= 0
                                    ? '+${standing.dg}'
                                    : standing.dg.toString(),
                                color: standing.dg >= 0
                                    ? const Color(0xFF9BBB1D)
                                    : const Color(0xFFE05858),
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
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;

              const criterionCard = _PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF97B11B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Criterio de desempate',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _TiebreakRule(number: '1.', label: 'Partidos ganados'),
                    _TiebreakRule(number: '2.', label: 'Diferencia de games'),
                    _TiebreakRule(number: '3.', label: 'Games a favor'),
                    _TiebreakRule(number: '4.', label: 'Games en contra'),
                    _TiebreakRule(number: '5.', label: 'Resultado directo'),
                  ],
                ),
              );

              final actionsCard = _PanelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          size: 18,
                          color: Color(0xFF97B11B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Acciones rápidas',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MiniActionButton(
                      label: 'Ver partidos pendientes',
                      icon: Icons.sports_score_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TournamentAdminMatchesScreen(
                              tournament: _currentTournament,
                              initialFilter: 'pending',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniActionButton(
                      label: 'Registrar resultado',
                      icon: Icons.edit_note_rounded,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TournamentAdminMatchesScreen(
                              tournament: _currentTournament,
                              initialFilter: 'live',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    criterionCard,
                    const SizedBox(height: 10),
                    actionsCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: criterionCard),
                  const SizedBox(width: 10),
                  Expanded(child: actionsCard),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInlineRegistrationsPanel() {
    final entries = _filteredRegistrationEntries;
    final soloCount = _currentTournament.soloRegistrationsCount;

    return Column(
      children: [
        _InlineRegistrationFilterBar(
          filter: _registrationFilter,
          onChanged: (filter) => setState(() => _registrationFilter = filter),
        ),
        const SizedBox(height: 12),
        _InlineRegistrationProgressCard(
          registrationsCount: _currentTournament.registrationsCount,
          playerCapacity: _currentTournament.playerCapacity,
          soloCount: soloCount,
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _PanelCard(
            child: Text(
              'Aún no hay inscritos en esta vista.',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InlineRegistrationCard(
                entry: entry,
                onView: () => _showInlineRegistrationDetails(entry),
                onRemove: _isUpdatingRegistrations
                    ? null
                    : () => _removeInlineRegistration(entry),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showInlineRegistrationDetails(
    TournamentRegistrationEntry entry,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InlineAvatar(photoUrl: entry.user.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.hasPartner
                        ? '${entry.user.name} / ${entry.partnerUser?.name ?? ''}'
                        : entry.user.name,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InlineDetailLine(label: 'Estado', value: entry.statusLabel),
            _InlineDetailLine(
              label: 'Categoría',
              value: entry.user.category ?? 'Sin categoría',
            ),
            if ((entry.preferredSide ?? '').isNotEmpty)
              _InlineDetailLine(label: 'Lado', value: entry.preferredSide!),
            if ((entry.availability ?? '').isNotEmpty)
              _InlineDetailLine(label: 'Horario', value: entry.availability!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE7EBF0),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeInlineRegistration(
    TournamentRegistrationEntry entry,
  ) async {
    setState(() => _isUpdatingRegistrations = true);
    try {
      final updated = await TournamentService().removeAdminRegistration(
        tournamentId: _currentTournament.id,
        registrationId: entry.id,
      );
      if (!mounted) return;
      setState(() {
        _tournament = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscripción quitada')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRegistrations = false);
      }
    }
  }

  Widget _buildRegistrationsCard(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inscripciónes abiertas',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.groups_2_outlined,
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${_currentTournament.registrationsCount} de ${_currentTournament.playerCapacity} jugadores',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _currentTournament.playerCapacity <= 0
                  ? 0
                  : (_currentTournament.registrationsCount /
                          _currentTournament.playerCapacity)
                      .clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFB8C1D3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.PrimaryGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentTournament.registrationsOpen
                ? 'Se cierra al completar cupos'
                : 'Las inscripciones están cerradas',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: 'Ver inscritos',
            filled: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TournamentAdminRegistrationsScreen(
                    tournament: _currentTournament,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: _currentTournament.registrationsOpen
                ? 'Cerrar inscripciones'
                : 'Abrir cupos',
            filled: false,
            enabled: !_isUpdatingRegistrations,
            onTap: _toggleRegistrations,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del torneo',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: 'Cupos',
            value: '${_currentTournament.playerCapacity}',
          ),
          _SummaryLine(label: 'Formato', value: _currentTournament.format),
          const _SummaryLine(
            label: 'Inscripción',
            value: 'Con o sin pareja',
          ),
          _SummaryLine(
            label: 'Costo',
            value: 'S/${_currentTournament.entryFee} x persona',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad reciente',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ..._recentActivity.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecentActivityText(text: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  const _AdminTabButton({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.secondaryGradient : null,
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
  int get points => pg * 3;
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
    final label =
        '${registration.user.name} / ${registration.partnerUser?.name ?? ''}'
            .trim();
    ensureTeam(label);
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

class _TableStatChip extends StatelessWidget {
  const _TableStatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F0)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.SecondBlue, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.68),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final background = switch (rank) {
      1 => const Color(0xFFF8EAA6),
      2 => const Color(0xFFE5EAF0),
      3 => const Color(0xFFEFD8B0),
      _ => const Color(0xFFE5EAF0),
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
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

class _TableValue extends StatelessWidget {
  const _TableValue(this.value, {this.color});

  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$number $label',
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9ECF2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.SecondBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.SecondBlue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineRegistrationFilterBar extends StatelessWidget {
  const _InlineRegistrationFilterBar({
    required this.filter,
    required this.onChanged,
  });

  final _AdminInlineRegistrationFilter filter;
  final ValueChanged<_AdminInlineRegistrationFilter> onChanged;

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
          _InlineFilterButton(
            label: 'Todos',
            selected: filter == _AdminInlineRegistrationFilter.all,
            onTap: () => onChanged(_AdminInlineRegistrationFilter.all),
          ),
          _InlineFilterButton(
            label: 'Con pareja',
            selected: filter == _AdminInlineRegistrationFilter.withPartner,
            onTap: () => onChanged(_AdminInlineRegistrationFilter.withPartner),
          ),
          _InlineFilterButton(
            label: 'Sin pareja',
            selected: filter == _AdminInlineRegistrationFilter.solo,
            onTap: () => onChanged(_AdminInlineRegistrationFilter.solo),
          ),
        ],
      ),
    );
  }
}

class _InlineFilterButton extends StatelessWidget {
  const _InlineFilterButton({
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
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineRegistrationProgressCard extends StatelessWidget {
  const _InlineRegistrationProgressCard({
    required this.registrationsCount,
    required this.playerCapacity,
    required this.soloCount,
  });

  final int registrationsCount;
  final int playerCapacity;
  final int soloCount;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_2_outlined,
                color: AppColors.SecondBlue.withValues(alpha: 0.62),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$registrationsCount de $playerCapacity jugadores',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (soloCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD7FF59),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$soloCount buscando dupla',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: playerCapacity <= 0
                  ? 0
                  : (registrationsCount / playerCapacity).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFB8C1D3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.PrimaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineRegistrationCard extends StatelessWidget {
  const _InlineRegistrationCard({
    required this.entry,
    required this.onView,
    required this.onRemove,
  });

  final TournamentRegistrationEntry entry;
  final VoidCallback onView;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        children: [
          Row(
            children: [
              _InlineAvatar(photoUrl: entry.user.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: entry.user.name,
                            style: const TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (entry.hasPartner)
                            TextSpan(
                              text: ' / ${entry.partnerUser?.name ?? ''}',
                              style: TextStyle(
                                color: AppColors.SecondBlue.withValues(
                                  alpha: 0.55,
                                ),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InlineTag(text: entry.statusLabel, highlighted: true),
                  ],
                ),
              ),
              IconButton(
                onPressed: onView,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.SecondBlue,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFDCE2EB),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineCardActionButton(
                  label: 'Ver',
                  icon: Icons.visibility_outlined,
                  backgroundColor: const Color(0xFFD7FF59),
                  onTap: onView,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineCardActionButton(
                  label: 'Quitar',
                  icon: Icons.remove_circle_outline,
                  backgroundColor: const Color(0xFFE7EBF0),
                  onTap: onRemove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineAvatar extends StatelessWidget {
  const _InlineAvatar({
    required this.photoUrl,
  });

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(photoUrl);

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.PrimaryGreen, width: 1.3),
      ),
      child: ClipOval(
        child: (photoUrl != null && photoUrl!.isNotEmpty)
            ? (photoUrl!.startsWith('http')
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/Logo_Icono.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : (bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/Logo_Icono.png',
                        fit: BoxFit.cover,
                      )))
            : Image.asset(
                'assets/images/Logo_Icono.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _InlineTag extends StatelessWidget {
  const _InlineTag({
    required this.text,
    this.highlighted = false,
  });

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFD7FF59) : AppColors.SecondBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlighted ? AppColors.SecondBlue : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineCardActionButton extends StatelessWidget {
  const _InlineCardActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          side: BorderSide.none,
          backgroundColor: backgroundColor,
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InlineDetailLine extends StatelessWidget {
  const _InlineDetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _InlineMatchFilterBar extends StatelessWidget {
  const _InlineMatchFilterBar({
    required this.filter,
    required this.onChanged,
  });

  final _AdminInlineMatchFilter filter;
  final ValueChanged<_AdminInlineMatchFilter> onChanged;

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
          _InlineMatchFilterButton(
            label: 'Todos',
            selected: filter == _AdminInlineMatchFilter.all,
            onTap: () => onChanged(_AdminInlineMatchFilter.all),
          ),
          _InlineMatchFilterButton(
            label: 'Pendientes',
            selected: filter == _AdminInlineMatchFilter.pending,
            onTap: () => onChanged(_AdminInlineMatchFilter.pending),
          ),
          _InlineMatchFilterButton(
            label: 'En curso',
            selected: filter == _AdminInlineMatchFilter.live,
            onTap: () => onChanged(_AdminInlineMatchFilter.live),
          ),
          _InlineMatchFilterButton(
            label: 'Finalizados',
            selected: filter == _AdminInlineMatchFilter.finished,
            onTap: () => onChanged(_AdminInlineMatchFilter.finished),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _InlineMatchFilterButton extends StatelessWidget {
  const _InlineMatchFilterButton({
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
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _InlineEmptyMatchesCard extends StatelessWidget {
  const _InlineEmptyMatchesCard({
    required this.registrationsOpen,
    required this.hasPendingPairs,
    required this.onGenerate,
  });

  final bool registrationsOpen;
  final bool hasPendingPairs;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            registrationsOpen
                ? 'Cierra las inscripciones para generar los cruces.'
                : hasPendingPairs
                    ? 'Hay jugadores buscando pareja antes de generar cruces.'
                    : 'Aún no hay cruces generados para este torneo.',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (!registrationsOpen && !hasPendingPairs) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text(
                  'Generar cruces automáticamente',
                  style: TextStyle(
                    fontSize: 14,
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

// ignore: unused_element
class _InlineMatchCard extends StatelessWidget {
  const _InlineMatchCard({
    required this.match,
  });

  final TournamentAdminMatch match;

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

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${match.courtLabel} ? ${match.stageLabel}',
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match.teamOne,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFDCE2EB)),
          const SizedBox(height: 8),
          Text(
            match.teamTwo,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((match.score ?? '').trim().isNotEmpty ||
              (match.winnerLabel ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [
                if ((match.winnerLabel ?? '').trim().isNotEmpty)
                  'Ganador: ${match.winnerLabel!.trim()}',
                if ((match.score ?? '').trim().isNotEmpty)
                  'Score: ${match.score!.trim()}',
              ].join(' ? '),
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.68),
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

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.tournament,
    required this.formattedDate,
  });

  final TournamentRecord tournament;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(tournament.photoUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 230,
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
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          tournament.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E58C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tournament.registrationsOpen
                              ? 'Pendiente'
                              : 'Cerrado',
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tournament.category.toUpperCase()} categoría',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
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
                      fontSize: 12,
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

  // ignore: unused_element
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _RecentActivityText extends StatelessWidget {
  const _RecentActivityText({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      color: AppColors.SecondBlue.withValues(alpha: 0.82),
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final boldStyle = GoogleFonts.inter(
      color: AppColors.SecondBlue.withValues(alpha: 0.92),
      fontSize: 13,
      fontWeight: FontWeight.w900,
    );

    final cuposMatch = RegExp(r'^(\d+ de \d+ cupos)(.*)$').firstMatch(text);
    if (cuposMatch != null) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: cuposMatch.group(1), style: boldStyle),
            TextSpan(text: cuposMatch.group(2) ?? ''),
          ],
        ),
      );
    }

    final splitText = text.split(' se ');
    if (splitText.length == 2) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: splitText.first, style: boldStyle),
            TextSpan(text: ' se ${splitText.last}'),
          ],
        ),
      );
    }

    final searchingText = text.split(' esta ');
    if (searchingText.length == 2) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: searchingText.first, style: boldStyle),
            TextSpan(text: ' esta ${searchingText.last}'),
          ],
        ),
      );
    }

    return Text(text, style: baseStyle);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? const Color(0xFFD7FF59) : const Color(0xFFE7EBF0),
          foregroundColor: AppColors.SecondBlue,
          disabledBackgroundColor:
              (filled ? const Color(0xFFD7FF59) : const Color(0xFFE7EBF0))
                  .withValues(alpha: 0.55),
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

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.76),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseRegistrationsOnlyDialog extends StatelessWidget {
  const _CloseRegistrationsOnlyDialog({
    required this.isComplete,
    required this.onGenerateBrackets,
  });

  final bool isComplete;
  final Future<void> Function() onGenerateBrackets;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isComplete ? 'Cupos completos' : 'Cerrar inscripciones',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isComplete
                  ? 'El torneo ya completó sus cupos.\nTodos los inscritos tienen pareja\nLuego podrás generar los cruces manualmente.'
                  : 'Al cerrar las inscripciones ya no entrarán más jugadores.\nLuego podrás generar los cruces manualmente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.78),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onGenerateBrackets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontWeight: FontWeight.w900),
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

// ignore: unused_element
class _CloseRegistrationsDialog extends StatelessWidget {
  const _CloseRegistrationsDialog({
    required this.isComplete,
    required this.onGenerateBrackets,
  });

  final bool isComplete;
  final Future<void> Function() onGenerateBrackets;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isComplete ? 'Cupos completos' : 'Cerrar inscripciones',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isComplete
                  ? 'El torneo ya completó sus cupos.\nTodos los inscritos tienen pareja\nYa puedes generar los cruces del torneo'
                  : 'Al cerrar las inscripciones ya no entrarán más jugadores.\nLuego podrás generar los cruces del torneo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.78),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7EBF0),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onGenerateBrackets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Generar cruces',
                        style: TextStyle(fontWeight: FontWeight.w900),
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
