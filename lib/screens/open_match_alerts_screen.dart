import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../constants/lima_padel_clubs.dart';
import '../constants/typography.dart';
import '../models/community_user.dart';
import '../models/selected_player.dart';
import '../models/open_match_alert.dart';
import '../services/community_service.dart';
import '../services/match_service.dart';
import '../services/open_match_alert_service.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'main_shell.dart';
import 'match_score_screen.dart';
import 'qr_scanner_screen.dart';

class OpenMatchAlertsScreen extends StatefulWidget {
  const OpenMatchAlertsScreen({
    super.key,
    this.onBackTap,
  });

  final VoidCallback? onBackTap;

  @override
  State<OpenMatchAlertsScreen> createState() => _OpenMatchAlertsScreenState();
}

class _OpenMatchFooter extends StatelessWidget {
  const _OpenMatchFooter({
    required this.currentTab,
    this.onBackTap,
  });

  final PgoNavTab currentTab;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    if (PgoFooterScope.hasFooter(context)) {
      return const SizedBox.shrink();
    }

    return PgoBottomNav(
      currentTab: currentTab,
      onHomeTap: () {
        if (onBackTap != null) {
          onBackTap!();
          return;
        }
        MainShell.openReplacement(context, initialTab: PgoNavTab.home);
      },
      onTournamentsTap: () => MainShell.openReplacement(
        context,
        initialTab: PgoNavTab.tournaments,
      ),
      onAlertsTap: () => MainShell.openReplacement(
        context,
        initialTab: PgoNavTab.alerts,
      ),
      onProfileTap: () => MainShell.openReplacement(
        context,
        initialTab: PgoNavTab.profile,
      ),
    );
  }
}

class _OpenMatchAlertsScreenState extends State<OpenMatchAlertsScreen> {
  final OpenMatchAlertService _service = OpenMatchAlertService();
  final TextEditingController _searchController = TextEditingController();
  List<OpenMatchAlert> _alerts = const [];
  bool _isLoading = true;
  String? _error;
  _OpenMatchTabType _selectedTab = _OpenMatchTabType.available;
  final Set<_OpenMatchFilterType> _selectedFilters = {};
  final Set<String> _localCreatedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OpenMatchAlert> get _visibleAlerts {
    final query = _searchController.text.trim().toLowerCase();
    final districtFilter = _filterDistrict.toLowerCase();
    final categoryFilter = _filterCategory.toLowerCase();
    final formatFilter = _filterFormat.toLowerCase();
    return _alerts.where((alert) {
      final matchesTab = switch (_selectedTab) {
        _OpenMatchTabType.available => alert.status.toUpperCase() == 'OPEN' &&
            alert.missingPlayers > 0 &&
            !alert.hasJoined &&
            !alert.isOrganizer,
        _OpenMatchTabType.myAlerts =>
          alert.isOrganizer || _localCreatedAlertIds.contains(alert.id),
        _OpenMatchTabType.myMatches =>
          alert.hasJoined && alert.status.toUpperCase() != 'COMPLETED',
      };
      if (!matchesTab) return false;

      if (_selectedFilters.contains(_OpenMatchFilterType.today) &&
          !_isSameLocalDay(alert.startsAt, DateTime.now())) {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.nearMe) &&
          districtFilter.isNotEmpty &&
          !alert.district.toLowerCase().contains(districtFilter)) {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.fourth) &&
          categoryFilter.isNotEmpty &&
          alert.category.toLowerCase() != categoryFilter) {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.doubles) &&
          formatFilter.isNotEmpty &&
          alert.format.toLowerCase() != formatFilter) {
        return false;
      }

      if (query.isEmpty) return true;
      return alert.club.toLowerCase().contains(query) ||
          alert.district.toLowerCase().contains(query) ||
          alert.category.toLowerCase().contains(query) ||
          alert.format.toLowerCase().contains(query);
    }).toList();
  }

  Iterable<OpenMatchAlert> get _availableAlerts => _alerts.where((alert) =>
      alert.status.toUpperCase() == 'OPEN' &&
      alert.missingPlayers > 0 &&
      !alert.hasJoined &&
      !alert.isOrganizer);

  String get _filterDistrict => _firstAvailableValue((alert) => alert.district);
  String get _filterCategory => _firstAvailableValue((alert) => alert.category);
  String get _filterFormat => _firstAvailableValue((alert) => alert.format);

  String _firstAvailableValue(String Function(OpenMatchAlert alert) select) {
    final values = _availableAlerts
        .map(select)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values.isEmpty ? '' : values.first;
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final alerts = await _service.getAlerts();
      if (!mounted) return;
      setState(() => _alerts = alerts);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<OpenMatchAlert>(
      MaterialPageRoute(
        builder: (_) => const CreateOpenMatchScreen(),
      ),
    );
    if (created != null) {
      setState(() {
        _selectedTab = _OpenMatchTabType.myAlerts;
        _selectedFilters.clear();
        _localCreatedAlertIds.add(created.id);
        _alerts = [
          created,
          ..._alerts.where((alert) => alert.id != created.id),
        ];
      });
      await _loadAlerts();
      if (!mounted) return;
      setState(() {
        if (!_alerts.any((alert) => alert.id == created.id)) {
          _alerts = [created, ..._alerts];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Partido publicado',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDetail(OpenMatchAlert alert) async {
    final updated = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => OpenMatchDetailScreen(alert: alert),
      ),
    );
    if (updated != null) {
      await _loadAlerts();
    }
  }

  Future<void> _toggleFilter(_OpenMatchFilterType filter) async {
    if (_selectedTab != _OpenMatchTabType.available) return;

    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  Future<bool> _confirmDeleteAlert(OpenMatchAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Eliminar alerta',
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Esta alerta dejará de aparecer para otros jugadores.',
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                color: const Color(0xFFFF334B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<bool> _deleteAlert(OpenMatchAlert alert) async {
    final confirmed = await _confirmDeleteAlert(alert);
    if (!confirmed) return false;

    setState(() {
      _alerts = _alerts.where((item) => item.id != alert.id).toList();
      _localCreatedAlertIds.remove(alert.id);
    });

    try {
      await _service.deleteAlert(alert.id);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alerta eliminada',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _alerts = [alert, ..._alerts.where((item) => item.id != alert.id)];
        _localCreatedAlertIds.add(alert.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Widget _buildAlertListItem(OpenMatchAlert alert) {
    final canDelete = _selectedTab == _OpenMatchTabType.myAlerts &&
        (alert.isOrganizer || _localCreatedAlertIds.contains(alert.id));

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _OpenMatchCard(
        alert: alert,
        onTap: () => _openDetail(alert),
      ),
    );

    if (!canDelete) return card;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: ValueKey('open-match-alert-${alert.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _deleteAlert(alert),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFF334B),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: _OpenMatchCard(
          alert: alert,
          onTap: () => _openDetail(alert),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      bottomNavigationBar: _OpenMatchFooter(
        currentTab: PgoNavTab.alerts,
        onBackTap: widget.onBackTap,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 14, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: widget.onBackTap ??
                                  () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Partidos',
                                style: PgoTextStyles.screenTitle(
                                  color: Colors.white,
                                  weight: FontWeight.w900,
                                ).copyWith(fontSize: 25, height: 1),
                              ),
                            ),
                            const PgoOptionsMenuButton(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 38,
                          margin: const EdgeInsets.only(left: 14, right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.only(top: 8, right: 12),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 38,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color:
                                    AppColors.SecondBlue.withValues(alpha: 0.9),
                                size: 16,
                              ),
                              hintText: 'Buscar partido, club o distrito',
                              hintStyle: PgoTextStyles.bodySecondary(
                                color: AppColors.SecondBlue.withValues(
                                    alpha: 0.65),
                                weight: FontWeight.w500,
                              ).copyWith(fontSize: 12),
                            ),
                            style: PgoTextStyles.body(
                              color: AppColors.SecondBlue,
                              weight: FontWeight.w600,
                            ).copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F3F5),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Column(
                        children: [
                          _OpenMatchTabs(
                            selectedTab: _selectedTab,
                            onChanged: (tab) => setState(() {
                              _selectedTab = tab;
                              if (tab != _OpenMatchTabType.available) {
                                _selectedFilters.clear();
                              }
                            }),
                          ),
                          if (_selectedTab == _OpenMatchTabType.available)
                            _OpenMatchFilters(
                              selectedFilters: _selectedFilters,
                              districtLabel: _filterDistrict.isEmpty
                                  ? 'Zona'
                                  : _filterDistrict,
                              categoryLabel: _filterCategory.isEmpty
                                  ? 'Nivel'
                                  : _filterCategory,
                              formatLabel: _filterFormat.isEmpty
                                  ? 'Formato'
                                  : _filterFormat,
                              onToggle: _toggleFilter,
                            ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadAlerts,
                              color: AppColors.SecondBlue,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 112),
                                children: [
                                  if (_isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 76),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    )
                                  else if (_error != null)
                                    _EmptyAlertsCard(text: _error!)
                                  else if (_visibleAlerts.isEmpty)
                                    const _EmptyAlertsCard(
                                      text:
                                          'Aún no hay partidos abiertos disponibles.',
                                    )
                                  else
                                    ..._visibleAlerts.map(
                                      _buildAlertListItem,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 18,
                bottom: 124,
                child: _CreateOpenMatchFab(onTap: _openCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameLocalDay(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

enum _OpenMatchTabType { available, myAlerts, myMatches }

enum _OpenMatchFilterType { today, nearMe, fourth, doubles }

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late int _hour = widget.initialTime.hourOfPeriod == 0
      ? 12
      : widget.initialTime.hourOfPeriod;
  late int _minute = widget.initialTime.minute ~/ 15 * 15;
  late bool _isPm = widget.initialTime.period == DayPeriod.pm;

  TimeOfDay get _value {
    final hour =
        _isPm ? (_hour == 12 ? 12 : _hour + 12) : (_hour == 12 ? 0 : _hour);
    return TimeOfDay(hour: hour, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 58,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DAE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hora del partido',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeWheel(
                    values: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                    selected: _hour,
                    labelBuilder: (value) => value.toString().padLeft(2, '0'),
                    onChanged: (value) => setState(() => _hour = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeWheel(
                    values: const [0, 15, 30, 45],
                    selected: _minute,
                    labelBuilder: (value) => value.toString().padLeft(2, '0'),
                    onChanged: (value) => setState(() => _minute = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      _PeriodButton(
                        label: 'am',
                        selected: !_isPm,
                        onTap: () => setState(() => _isPm = false),
                      ),
                      const SizedBox(height: 8),
                      _PeriodButton(
                        label: 'pm',
                        selected: _isPm,
                        onTap: () => setState(() => _isPm = true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PrimaryButton(
              label: 'Usar ${_formatTimeOfDay(_value)}',
              onTap: () => Navigator.of(context).pop(_value),
              height: 44,
              fontSize: 13.5,
              borderRadius: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<int> values;
  final int selected;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 42,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.003,
        diameterRatio: 1.4,
        controller: FixedExtentScrollController(
          initialItem: values.indexOf(selected).clamp(0, values.length - 1),
        ),
        onSelectedItemChanged: (index) => onChanged(values[index]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: values.length,
          builder: (context, index) {
            final value = values[index];
            final isSelected = value == selected;
            return Center(
              child: Text(
                labelBuilder(value),
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: isSelected ? 24 : 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FF4F) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlayerSearchSheet extends StatefulWidget {
  const _PlayerSearchSheet({
    required this.selectedUserIds,
    this.currentUserId,
  });

  final String? currentUserId;
  final Set<String> selectedUserIds;

  @override
  State<_PlayerSearchSheet> createState() => _PlayerSearchSheetState();
}

class _PlayerSearchSheetState extends State<_PlayerSearchSheet> {
  final CommunityService _communityService = CommunityService();
  final _controller = TextEditingController();
  List<CommunityUser> _results = const [];
  bool _isSearching = false;
  String? _error;

  List<CommunityUser> _filterUsers(List<CommunityUser> users) {
    final currentUserId = widget.currentUserId?.trim().toLowerCase();
    final selectedIds = widget.selectedUserIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();

    return users.where((user) {
      final userId = user.id.trim().toLowerCase();
      if (userId.isEmpty) return false;
      if (user.isActive == false ||
          user.allowsMatchInvites == false ||
          user.hasScheduleConflict == true) {
        return false;
      }
      if (currentUserId != null &&
          currentUserId.isNotEmpty &&
          userId == currentUserId) {
        return false;
      }
      return !selectedIds.contains(userId);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final users = await _communityService.getSuggestions();
      if (!mounted) return;
      setState(() => _results = _filterUsers(users));
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      await _loadSuggestions();
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final users = await _communityService.searchCommunity(query);
      if (!mounted) return;
      setState(() {
        _results = _filterUsers(users);
        if (_results.isEmpty) _error = 'No encontramos jugadores con ese dato';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DAE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(
              icon: Icons.person_add_alt_1,
              title: 'Agregar jugador',
              subtitle: 'Busca por nombre, correo o ID de jugador',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E4E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.SecondBlue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _search(),
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Nombre, correo o ID',
                            ),
                            style: GoogleFonts.inter(
                              color: AppColors.SecondBlue,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.PrimaryGreen,
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Buscar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _InviteMessage(text: _error!)
            else if (_results.isEmpty)
              const _InviteMessage(text: 'Busca un jugador para invitarlo')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return _PlayerResultTile(
                      user: user,
                      onTap: () => Navigator.of(context).pop(user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateOpenMatchFab extends StatelessWidget {
  const _CreateOpenMatchFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Color(0xFFD7FF59),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.SecondBlue,
          size: 34,
        ),
      ),
    );
  }
}

class _OpenMatchTabs extends StatelessWidget {
  const _OpenMatchTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  final _OpenMatchTabType selectedTab;
  final ValueChanged<_OpenMatchTabType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFDDE3EC)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _OpenMatchTab(
                label: 'Disponibles',
                selected: selectedTab == _OpenMatchTabType.available,
                onTap: () => onChanged(_OpenMatchTabType.available),
              ),
            ),
            Expanded(
              child: _OpenMatchTab(
                label: 'Mis alertas',
                selected: selectedTab == _OpenMatchTabType.myAlerts,
                onTap: () => onChanged(_OpenMatchTabType.myAlerts),
              ),
            ),
            Expanded(
              child: _OpenMatchTab(
                label: 'Mis partidos',
                selected: selectedTab == _OpenMatchTabType.myMatches,
                onTap: () => onChanged(_OpenMatchTabType.myMatches),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenMatchTab extends StatelessWidget {
  const _OpenMatchTab({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7FF4F) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: selected
                ? AppColors.SecondBlue
                : AppColors.SecondBlue.withValues(alpha: 0.56),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OpenMatchFilters extends StatelessWidget {
  const _OpenMatchFilters({
    required this.selectedFilters,
    required this.districtLabel,
    required this.categoryLabel,
    required this.formatLabel,
    required this.onToggle,
  });

  final Set<_OpenMatchFilterType> selectedFilters;
  final String districtLabel;
  final String categoryLabel;
  final String formatLabel;
  final ValueChanged<_OpenMatchFilterType> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FilterChipPgo(
              label: 'Hoy',
              icon: Icons.calendar_month,
              selected: selectedFilters.contains(_OpenMatchFilterType.today),
              onTap: () => onToggle(_OpenMatchFilterType.today),
            ),
            _FilterChipPgo(
              label: districtLabel,
              icon: Icons.location_on,
              selected: selectedFilters.contains(_OpenMatchFilterType.nearMe),
              onTap: () => onToggle(_OpenMatchFilterType.nearMe),
            ),
            _FilterChipPgo(
              label: categoryLabel,
              icon: Icons.bar_chart_rounded,
              selected: selectedFilters.contains(_OpenMatchFilterType.fourth),
              onTap: () => onToggle(_OpenMatchFilterType.fourth),
            ),
            _FilterChipPgo(
              label: formatLabel,
              icon: Icons.groups_rounded,
              selected: selectedFilters.contains(_OpenMatchFilterType.doubles),
              onTap: () => onToggle(_OpenMatchFilterType.doubles),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipPgo extends StatelessWidget {
  const _FilterChipPgo({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 23,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFC7D3E4) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected ? const Color(0xFF9CB0CA) : const Color(0xFFBBC3D0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 11,
                color: selected
                    ? const Color(0xFF31577F)
                    : AppColors.SecondBlue.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected
                      ? const Color(0xFF31577F)
                      : AppColors.SecondBlue.withValues(alpha: 0.55),
                  fontSize: 9.6,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateOpenMatchScreen extends StatefulWidget {
  const CreateOpenMatchScreen({super.key});

  @override
  State<CreateOpenMatchScreen> createState() => _CreateOpenMatchScreenState();
}

class _CreateOpenMatchScreenState extends State<CreateOpenMatchScreen> {
  static const bool _backendSupportsInvitations = true;

  final OpenMatchAlertService _service = OpenMatchAlertService();
  final CommunityService _communityService = CommunityService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _costController =
      TextEditingController(text: '25');
  final TextEditingController _commentController = TextEditingController(
    text:
        'Partido tranquilo para sumar gente, nivel intermedio, ideal puntualidad.',
  );
  static const List<String> _categories = ['3ra', '4ta', '5ta', '6ta'];
  static final List<({String club, String district})> _clubs = [
    for (final club in limaPadelClubDetails)
      (club: club.name, district: club.district),
  ];
  String _category = '4ta';
  String _club = 'One Padel Trigal';
  String _district = 'Surco';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _playerId;
  String? _playerEmail;
  String _playerName = 'Jugador';
  String? _playerPhotoUrl;
  final List<CommunityUser> _selectedPlayers = [];
  bool _isDoubles = true;
  bool _courtReserved = true;
  int _missingPlayers = 2;
  bool _payOrganizer = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nextSix = DateTime(now.year, now.month, now.day, 18);
    final startsAt =
        nextSix.isAfter(now) ? nextSix : nextSix.add(const Duration(days: 1));
    _selectedDate = DateTime(startsAt.year, startsAt.month, startsAt.day);
    _selectedTime = TimeOfDay(hour: startsAt.hour, minute: startsAt.minute);
    _loadProfile();
  }

  @override
  void dispose() {
    _costController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _playerId = profile.id;
        _playerEmail = profile.email;
        _playerName = profile.name.trim().isEmpty ? 'Jugador' : profile.name;
        _playerPhotoUrl = profile.photoUrl;
        if ((profile.category ?? '').trim().isNotEmpty) {
          _category = profile.category!.trim();
        }
        if ((profile.preferredClub ?? '').trim().isNotEmpty) {
          _club = profile.preferredClub!.trim();
          final knownClub = _clubs.where((item) => item.club == _club);
          if (knownClub.isNotEmpty) {
            _district = knownClub.first.district;
          }
        }
      });
    } catch (_) {
      // La alerta se puede crear aunque el perfil demore o falle.
    }
  }

  DateTime get _startsAt => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _publish() async {
    setState(() => _isSaving = true);
    try {
      final startsAt = _startsAt;
      if (!startsAt.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
        throw Exception('El partido debe iniciar al menos en 30 minutos.');
      }
      final cost = int.tryParse(_costController.text.trim());
      if (cost == null || cost < 0) {
        throw Exception('Ingresa un costo válido.');
      }
      if (!_isDoubles && _missingPlayers != 1) {
        throw Exception('Singles solo permite 1 jugador faltante.');
      }
      if (_commentController.text.trim().length > 240) {
        throw Exception('El comentario no puede superar 240 caracteres.');
      }
      final created = await _service.createAlert(
        category: _category,
        format: _isDoubles ? 'Dobles' : 'Singles',
        startsAt: startsAt,
        club: _club,
        district: _district,
        courtStatus: _courtReserved ? 'Reservada' : 'Por confirmar',
        missingPlayers: _missingPlayers,
        costPerPerson: cost,
        paymentLabel: _payOrganizer ? 'Con coordinador' : 'Pago en sede',
        comment: _commentController.text,
        invitedUserIds: _selectedPlayers.map((user) => user.id).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectCategory() async {
    final value = await _showOptionSheet<String>(
      title: 'Categoría',
      values: _categories,
      labelBuilder: (value) => value,
    );
    if (value != null) setState(() => _category = value);
  }

  Future<void> _selectClub() async {
    final value = await _showOptionSheet<({String club, String district})>(
      title: 'Club/Sede',
      values: _clubs,
      labelBuilder: (value) => '${value.club} - ${value.district}',
    );
    if (value != null) {
      setState(() {
        _club = value.club;
        _district = value.district;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _selectTime() async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _TimePickerSheet(initialTime: _selectedTime),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _searchPlayer() async {
    final user = await showModalBottomSheet<CommunityUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.78,
        child: _PlayerSearchSheet(
          currentUserId: _playerId,
          selectedUserIds: _selectedPlayers.map((user) => user.id).toSet(),
        ),
      ),
    );
    if (user == null) return;
    _addSelectedPlayer(user);
  }

  Future<void> _scanPlayerQr() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (value == null || value.trim().isEmpty) return;
    try {
      await _addPlayerByQuery(_extractPlayerQrQuery(value));
    } catch (error) {
      _showPlayerMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _addPlayerByQuery(String query) async {
    try {
      final users = await _communityService.searchCommunity(query);
      if (!mounted) return;
      CommunityUser? user;
      for (final item in users) {
        final q = query.trim().toLowerCase();
        if (item.id == query ||
            (item.email ?? '').toLowerCase() == q ||
            item.name.toLowerCase().contains(q)) {
          user = item;
          break;
        }
      }
      user ??= users.isNotEmpty ? users.first : null;
      if (user == null) throw Exception('No encontramos un jugador');
      _addSelectedPlayer(user);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _extractPlayerQrQuery(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is Map<String, dynamic>) {
        final type = decoded['type']?.toString().trim().toLowerCase();
        if (type != 'player') {
          throw Exception('Escanea un QR de jugador PGO valido.');
        }

        for (final key in const ['id', 'email', 'name']) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}

    throw Exception('Escanea un QR de jugador PGO valido.');
  }

  void _addSelectedPlayer(CommunityUser user) {
    final userId = user.id.trim();
    if (userId.isEmpty) {
      _showPlayerMessage('No pudimos validar ese jugador.');
      return;
    }
    if (_isCurrentPlayer(user)) {
      _showPlayerMessage('No puedes invitarte a ti mismo.');
      return;
    }
    if (user.isActive == false) {
      _showPlayerMessage('Ese jugador no esta activo.');
      return;
    }
    if (user.allowsMatchInvites == false) {
      _showPlayerMessage('Ese jugador no permite invitaciones.');
      return;
    }
    if (user.hasScheduleConflict == true) {
      _showPlayerMessage('Ese jugador ya tiene un partido en ese horario.');
      return;
    }
    if (_selectedPlayers.any((item) => item.id == user.id)) {
      _showPlayerMessage('Ese jugador ya fue agregado');
      return;
    }
    if (_selectedPlayers.length >= _missingPlayers) {
      _showPlayerMessage('No hay más cupos para agregar jugadores');
      return;
    }
    final compatibilityMessage = _categoryCompatibilityMessage(user);
    if (compatibilityMessage != null) {
      _showPlayerMessage(compatibilityMessage);
      return;
    }
    setState(() => _selectedPlayers.add(user));
  }

  void _removeSelectedPlayer(CommunityUser user) {
    setState(() => _selectedPlayers.removeWhere((item) => item.id == user.id));
  }

  bool _isCurrentPlayer(CommunityUser user) {
    final userId = user.id.trim().toLowerCase();
    final currentId = _playerId?.trim().toLowerCase();
    if (currentId != null && currentId.isNotEmpty && userId == currentId) {
      return true;
    }

    final email = user.email?.trim().toLowerCase();
    final currentEmail = _playerEmail?.trim().toLowerCase();
    return email != null &&
        email.isNotEmpty &&
        currentEmail != null &&
        currentEmail.isNotEmpty &&
        email == currentEmail;
  }

  String? _categoryCompatibilityMessage(CommunityUser user) {
    final alertCategory = _categoryRank(_category);
    final userCategory = _categoryRank(user.category);
    if (alertCategory == null || userCategory == null) return null;

    if ((alertCategory - userCategory).abs() > 1) {
      return 'Ese jugador no coincide con el nivel del partido.';
    }
    return null;
  }

  int? _categoryRank(String? value) {
    final match = RegExp(r'\d+').firstMatch(value ?? '');
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  void _showPlayerMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> values,
    required String Function(T value) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: values.length > 4 ? 0.58 : 0.42,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 58,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DAE3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      for (final value in values)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            labelBuilder(value),
                            style: GoogleFonts.inter(
                              color: AppColors.SecondBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(value),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      bottomNavigationBar: const _OpenMatchFooter(
        currentTab: PgoNavTab.alerts,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Crear partido abierto',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Completa los datos para que otros se sumen',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                    children: [
                      _row('Categoría', _categorySelector()),
                      _row(
                        'Formato',
                        _segmented(
                          left: 'Singles',
                          right: 'Dobles',
                          rightSelected: _isDoubles,
                          onLeft: () => setState(() {
                            _isDoubles = false;
                            _missingPlayers = 1;
                            if (_selectedPlayers.length > 1) {
                              _selectedPlayers.removeRange(
                                  1, _selectedPlayers.length);
                            }
                          }),
                          onRight: () => setState(() => _isDoubles = true),
                        ),
                      ),
                      _row(
                          'Fecha',
                          _tappableInput(_createDateLabel(_selectedDate),
                              onTap: _selectDate)),
                      _row(
                          'Hora',
                          _tappableInput(_formatTimeOfDay(_selectedTime),
                              onTap: _selectTime)),
                      _row(
                          'Club/Sede',
                          _tappableInput(_club,
                              trailing: true, onTap: _selectClub)),
                      _row(
                        'Cancha',
                        _segmented(
                          left: 'Por confirmar',
                          right: 'Reservada',
                          rightSelected: _courtReserved,
                          onLeft: () => setState(() => _courtReserved = false),
                          onRight: () => setState(() => _courtReserved = true),
                        ),
                      ),
                      _row(
                        'Faltan',
                        _threeSegment(
                          values: _isDoubles ? const [1, 2, 3] : const [1],
                          selected: _missingPlayers,
                          labels: _isDoubles
                              ? const [
                                  '1 jugador',
                                  '2 jugadores',
                                  '3 jugadores'
                                ]
                              : const ['1 jugador'],
                          onChanged: (value) => setState(() {
                            _missingPlayers = _isDoubles ? value : 1;
                            if (_selectedPlayers.length > _missingPlayers) {
                              _selectedPlayers.removeRange(
                                _missingPlayers,
                                _selectedPlayers.length,
                              );
                            }
                          }),
                        ),
                      ),
                      _row(
                        'Costo estimado\npor persona',
                        _editableInput(_costController, prefix: 'S/ '),
                      ),
                      _segmented(
                        left: 'Pago en sede',
                        right: 'Pago al organizador',
                        rightSelected: _payOrganizer,
                        onLeft: () => setState(() => _payOrganizer = false),
                        onRight: () => setState(() => _payOrganizer = true),
                      ),
                      const SizedBox(height: 20),
                      _playersSection(),
                      const SizedBox(height: 22),
                      _commentSection(),
                      const SizedBox(height: 26),
                      _PrimaryButton(
                        label: _isSaving ? 'Publicando...' : 'Publicar partido',
                        onTap: _isSaving ? null : () => _publish(),
                        height: 46,
                        fontSize: 13.5,
                        borderRadius: 23,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categorySelector() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E4E9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (final category in _categories)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _category = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _category.toLowerCase() == category.toLowerCase()
                        ? AppColors.SecondBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      color: _category.toLowerCase() == category.toLowerCase()
                          ? Colors.white
                          : AppColors.SecondBlue.withValues(alpha: 0.74),
                      fontSize: 12.5,
                      fontWeight:
                          _category.toLowerCase() == category.toLowerCase()
                              ? FontWeight.w900
                              : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 12.2,
                fontWeight: FontWeight.w800,
                height: 1.16,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _playersSection() {
    final remaining = _missingPlayers - _selectedPlayers.length;
    final totalOpenSlots = _isDoubles ? 3 : 1;
    final missingText = remaining <= 0
        ? 'Equipo completo'
        : remaining == 1
            ? 'Falta 1 jugador'
            : 'Faltan $remaining jugadores';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.SecondBlue.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.group_add_rounded,
                    color: AppColors.SecondBlue,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Jugadores invitados',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _InviteCounter(
                    selected: _selectedPlayers.length,
                    total: _missingPlayers,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$missingText. Puedes invitar hasta ${math.max(remaining, 0)} jugador${remaining == 1 ? '' : 'es'} más.',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const _InviteNotice(
                text: _backendSupportsInvitations
                    ? 'La invitacion requiere aceptacion del jugador antes de confirmar el cupo.'
                    : 'Seleccionar jugadores no reserva cupos todavia. Quita los invitados para publicar.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InviteActionButton(
                      label: 'Buscar jugador',
                      icon: Icons.search_rounded,
                      onTap: _selectedPlayers.length >= _missingPlayers
                          ? null
                          : _searchPlayer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InviteQrButton(
                    onTap: _selectedPlayers.length >= _missingPlayers
                        ? null
                        : _scanPlayerQr,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PlayerSelectionCard(
                    name: _playerName,
                    imageUrl: _playerPhotoUrl,
                    label: 'Organizador',
                  ),
                  for (final user in _selectedPlayers)
                    _PlayerSelectionCard(
                      name: user.name,
                      imageUrl: user.photoUrl,
                      label: user.category ?? 'Invitado',
                      onRemove: () => _removeSelectedPlayer(user),
                    ),
                  for (var i = _selectedPlayers.length; i < totalOpenSlots; i++)
                    _EmptyInviteSlot(
                      label: i < _missingPlayers ? 'Cupo libre' : 'Sin cupo',
                      onTap: i < _missingPlayers ? _searchPlayer : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _playersSectionLegacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Añadir jugadores',
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 12.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _tappableInput(
                'Nombre, correo o ID',
                icon: Icons.search_rounded,
                onTap: _searchPlayer,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _scanPlayerQr,
              child: SizedBox(
                width: 48,
                height: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E4E9),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      'QR',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PlayerBubble(
              name: _playerName,
              imageUrl: _playerPhotoUrl,
            ),
            for (var i = 0; i < _missingPlayers; i++)
              i < _selectedPlayers.length
                  ? _PlayerBubble(
                      name: _selectedPlayers[i].name,
                      imageUrl: _selectedPlayers[i].photoUrl,
                    )
                  : _EmptyPlayerSlot(label: 'Jugador ${i + 2}'),
          ],
        ),
      ],
    );
  }

  Widget _commentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comentario opcional',
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 12.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E4E9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class OpenMatchDetailScreen extends StatefulWidget {
  const OpenMatchDetailScreen({
    super.key,
    required this.alert,
  });

  final OpenMatchAlert alert;

  @override
  State<OpenMatchDetailScreen> createState() => _OpenMatchDetailScreenState();
}

class _OpenMatchDetailScreenState extends State<OpenMatchDetailScreen> {
  final OpenMatchAlertService _service = OpenMatchAlertService();
  late OpenMatchAlert _alert = widget.alert;
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isUpdatingCoordination = false;
  String? _selectedCoordinationStatus;

  bool get _isMyMatch => _alert.hasJoined || _alert.isOrganizer;
  bool get _isFull =>
      _alert.status.toUpperCase() == 'FULL' || _alert.missingPlayers == 0;
  bool get _isCompleted => _alert.status.toUpperCase() == 'COMPLETED';
  bool get _isCanceled => _alert.status.toUpperCase() == 'CANCELED';
  bool get _canLeaveMatch =>
      _alert.hasJoined && !_alert.isOrganizer && !_isCompleted && !_isCanceled;
  bool get _resultPending =>
      !_isCompleted && _isFull && DateTime.now().isAfter(_alert.startsAt);
  String? get _resultUnavailableMessage {
    if (_isCompleted) return 'Este partido ya tiene resultado registrado.';
    if (!_isFull) return 'El partido aún no está completo.';
    if (DateTime.now().isBefore(_alert.startsAt)) {
      return 'El partido aún no empezó.';
    }
    if (!_isMyMatch) {
      return 'Debes participar en el partido para registrar resultado.';
    }
    return null;
  }

  Future<void> _confirmJoin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _JoinConfirmDialog(alert: _alert),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isJoining = true);
    try {
      final updated = await _service.joinAlert(_alert.id);
      if (!mounted) return;
      setState(() => _alert = updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _JoinSuccessDialog(alert: _alert),
    );
  }

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del partido'),
        content: const Text('Tu cupo quedará libre para otro jugador.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      await _service.leaveAlert(_alert.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saliste del partido.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  Future<void> _updateCoordination(String status) async {
    if (_isUpdatingCoordination) return;
    setState(() => _isUpdatingCoordination = true);
    try {
      final updated = await _service.updateCoordination(
        id: _alert.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _alert = updated;
        _selectedCoordinationStatus = status;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingCoordination = false);
    }
  }

  List<Widget> _openMatchChildren() {
    return [
      _OpenMatchHeroCard(alert: _alert),
      if ((_alert.comment ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _OpenMatchCommentCard(comment: _alert.comment!.trim()),
      ],
      const SizedBox(height: 14),
      _OpenMatchCreatorCard(alert: _alert),
      const SizedBox(height: 14),
      _OpenMatchConfirmedCard(alert: _alert),
      const SizedBox(height: 14),
      _InfoBlock(
        rows: [
          ('Formato', _alert.format, Icons.groups),
          ('Cancha', _alert.courtStatus, Icons.calendar_month),
          ('Nivel', _alert.category, Icons.bar_chart),
        ],
      ),
      const SizedBox(height: 54),
      _PrimaryButton(
        label: _alert.hasJoined
            ? 'Ya estás dentro'
            : (_isJoining ? 'Uniendo...' : 'Unirme'),
        onTap: _alert.hasJoined || _isJoining ? null : () => _confirmJoin(),
        height: 36,
        fontSize: 14,
        borderRadius: 18,
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Compartir partido',
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ];
  }

  List<Widget> _myMatchChildren() {
    final resultUnavailableMessage = _resultUnavailableMessage;
    return [
      _MyOpenMatchHeroCard(alert: _alert, resultPending: _resultPending),
      const SizedBox(height: 16),
      if (_resultPending)
        _OpenMatchResultPendingCard(alert: _alert)
      else
        _OpenMatchCoordinationCard(
          isFull: _isFull,
          selectedStatus: _selectedCoordinationStatus,
          onSelected: _updateCoordination,
          isUpdating: _isUpdatingCoordination,
        ),
      if (!_resultPending && resultUnavailableMessage != null) ...[
        const SizedBox(height: 16),
        _OpenMatchResultUnavailableCard(message: resultUnavailableMessage),
      ],
      const SizedBox(height: 16),
      _QuickChatCard(alert: _alert),
      const SizedBox(height: 16),
      _HowToArriveCard(alert: _alert),
      if (!_isFull) ...[
        const SizedBox(height: 18),
        _PrimaryButton(
          label: 'Voy en camino',
          onTap: () => _updateCoordination('ON_THE_WAY'),
          height: 38,
          fontSize: 16,
          borderRadius: 22,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Compartir partido',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.65),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ] else if (_resultPending) ...[
        const SizedBox(height: 42),
        _PrimaryButton(
          label: 'Registrar resultado',
          onTap: _openResultPendingNotice,
          height: 38,
          fontSize: 16,
          borderRadius: 22,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Volver a partidos',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.76),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 18),
        _PrimaryButton(
          label: 'Voy en camino',
          onTap: () => _updateCoordination('ON_THE_WAY'),
          height: 38,
          fontSize: 16,
          borderRadius: 22,
        ),
      ],
      if (_canLeaveMatch) ...[
        const SizedBox(height: 18),
        TextButton(
          onPressed: _isLeaving ? null : _confirmLeave,
          child: Text(
            _isLeaving ? 'Saliendo...' : 'Salir del partido',
            style: GoogleFonts.inter(
              color: const Color(0xFFFF334B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      bottomNavigationBar: const _OpenMatchFooter(
        currentTab: PgoNavTab.alerts,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 18, 18),
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        _isMyMatch ? 'Mi partido' : 'Partido abierto',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const PgoOptionsMenuButton(),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 64,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F3F5),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 20,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: _isMyMatch
                            ? _myMatchChildren()
                            : _openMatchChildren(),
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

  Future<void> _openResultPendingNotice() async {
    final users = <OpenMatchUser>[
      _alert.organizer,
      ..._alert.participants,
    ].where((user) => user.id.isNotEmpty).toList();
    final unique = <String, OpenMatchUser>{
      for (final user in users) user.id: user,
    }.values.toList();

    if (unique.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesitan 4 jugadores para registrar resultado.'),
        ),
      );
      return;
    }

    try {
      final profile = await ProfileService().getMyProfile();
      if (!unique.any((user) => user.id == profile.id)) {
        throw Exception(
            'Debes participar en el partido para registrar resultado');
      }
      final match = await MatchService().createMatch(
        clubName: _alert.club,
        playedAt: _alert.startsAt,
        matchType: 'FRIENDLY',
        participantIds: unique.map((user) => user.id).toList(),
        openMatchAlertId: _alert.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchScoreScreen(
            match: match,
            players: unique
                .map(
                  (user) => SelectedPlayer(
                    id: user.id,
                    name: user.name,
                    photoUrl: user.photoUrl,
                    category: null,
                    rankingPosition: 0,
                  ),
                )
                .toList(),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _OpenMatchCard extends StatelessWidget {
  const _OpenMatchCard({
    required this.alert,
    required this.onTap,
    this.expanded = false,
  });

  final OpenMatchAlert alert;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return _buildCompactCard();
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DogAvatar(radius: 36, imageUrl: alert.organizer.photoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${alert.category} · ${alert.format}',
                          style: const TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${_dateLabel(alert.startsAt)} · ${_timeLabel(alert.startsAt)}',
                          style: TextStyle(
                            color: AppColors.SecondBlue.withValues(alpha: 0.72),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 17, color: AppColors.SecondBlue),
                            Expanded(
                              child: Text(
                                '${alert.club} · ${alert.district}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.SecondBlue.withValues(
                                      alpha: 0.72),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            alert.missingPlayers == 0
                                ? 'Completo'
                                : 'Faltan ${alert.missingPlayers} jugadores',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFD7DDE6)),
              _tinyInfo(Icons.attach_money,
                  'Costo estimado: S/ ${alert.costPerPerson} por persona'),
              const SizedBox(height: 6),
              _tinyInfo(Icons.person, 'Pago: ${alert.paymentLabel}'),
              if (expanded && (alert.comment ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    alert.comment!,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    final startsAt = alert.startsAt.toLocal();
    final dateText = DateFormat('EEEE d MMMM', 'es').format(startsAt);
    final timeText = _timeLabel(startsAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      elevation: 3.5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 15, 12, 13),
          child: Row(
            children: [
              _DogAvatar(radius: 27, imageUrl: alert.organizer.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.category} · ${alert.format}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.74),
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.68),
                        fontSize: 10.4,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 11,
                          color: AppColors.SecondBlue,
                        ),
                        Expanded(
                          child: Text(
                            '${alert.club} · ${alert.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.78),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        alert.missingPlayers == 0
                            ? 'Completo'
                            : 'Faltan ${alert.missingPlayers} jugadores',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Creador: ${alert.organizer.name.isEmpty ? 'Jugador' : alert.organizer.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.78),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                height: 31,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.PrimaryGreen,
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Ver',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tinyInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: AppColors.SecondBlue.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.72),
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JoinConfirmDialog extends StatelessWidget {
  const _JoinConfirmDialog({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirmar unión',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vas a unirte a este partido abierto.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 10.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 24),
            _MiniMatchSummary(alert: alert, compact: true),
            const Divider(height: 24),
            Text(
              'Tu cupo quedará confirmado al instante.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.75),
                fontSize: 10.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'Cancelar',
                    filled: false,
                    compact: true,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DialogButton(
                    label: 'Confirmar unión',
                    filled: true,
                    compact: true,
                    onTap: () => Navigator.of(context).pop(true),
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

class _JoinSuccessDialog extends StatelessWidget {
  const _JoinSuccessDialog({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.PrimaryGreen,
              child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 10),
            Text(
              'Ya estás dentro del partido',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            _MiniMatchSummary(alert: alert, compact: true),
            const SizedBox(height: 12),
            SizedBox(
              width: 122,
              child: _DialogButton(
                label: 'Ver partido',
                filled: true,
                compact: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMatchSummary extends StatelessWidget {
  const _MiniMatchSummary({
    required this.alert,
    this.compact = false,
  });

  final OpenMatchAlert alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 9 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: compact ? 7 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${alert.category} · ${alert.format}',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: compact ? 11 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${_dateLabel(alert.startsAt)} · ${_timeLabel(alert.startsAt)}',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: compact ? 10 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '📍${alert.club} · ${alert.district}',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: compact ? 8 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Divider(height: compact ? 12 : 24),
          Text(
            'Costo estimado: S/ ${alert.costPerPerson} por persona',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: compact ? 6.5 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Pago: ${alert.paymentLabel} · cancha confirmada',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: compact ? 6.5 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyOpenMatchHeroCard extends StatelessWidget {
  const _MyOpenMatchHeroCard({
    required this.alert,
    required this.resultPending,
  });

  final OpenMatchAlert alert;
  final bool resultPending;

  int get _displayMissingPlayers {
    if (alert.totalMissingPlayers > 0) {
      return alert.totalMissingPlayers;
    }
    return alert.missingPlayers;
  }

  String get _missingLabel {
    final missing = _displayMissingPlayers;
    return missing == 1 ? 'Falta 1 jugador' : 'Faltan $missing jugadores';
  }

  List<OpenMatchUser?> get _slots {
    final confirmed = <OpenMatchUser>[alert.organizer, ...alert.participants];
    final totalSlots = math.max(confirmed.length + _displayMissingPlayers, 4);
    return List<OpenMatchUser?>.generate(
      totalSlots.clamp(2, 4),
      (index) => index < confirmed.length ? confirmed[index] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DogAvatar(radius: 28, imageUrl: alert.organizer.photoUrl),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${alert.category} · ${alert.format}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.SecondBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: resultPending
                              ? 'Listo para registrar'
                              : (alert.missingPlayers == 0
                                  ? 'Partido completo'
                                  : _missingLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_dateLabel(alert.startsAt)} · ${_timeLabel(alert.startsAt)}',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppColors.SecondBlue),
                        Expanded(
                          child: Text(
                            '${alert.club} · ${alert.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.74),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFD7DDE6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _slots.map((user) {
              if (user == null) return const _PendingPlayerBubble();
              return _MatchStatusPlayerBubble(
                user: user,
                status: resultPending
                    ? null
                    : (alert.missingPlayers == 0 ? 'En camino' : 'Llegué'),
              );
            }).toList(),
          ),
          const Divider(height: 22, color: Color(0xFFD7DDE6)),
          _InfoMiniRow(
            icon: Icons.attach_money,
            label: 'Costo estimado',
            value: 'S/ ${alert.costPerPerson} por persona',
          ),
          const Divider(height: 1, color: Color(0xFFD7DDE6)),
          _InfoMiniRow(
            icon: Icons.person,
            label: 'Pago',
            value: alert.paymentLabel,
          ),
          const Divider(height: 1, color: Color(0xFFD7DDE6)),
          _InfoMiniRow(
            icon: Icons.calendar_month,
            label: 'Cancha',
            value: alert.courtStatus,
          ),
        ],
      ),
    );
  }
}

class _OpenMatchCoordinationCard extends StatelessWidget {
  const _OpenMatchCoordinationCard({
    required this.isFull,
    required this.selectedStatus,
    required this.onSelected,
    required this.isUpdating,
  });

  final bool isFull;
  final String? selectedStatus;
  final ValueChanged<String> onSelected;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.groups_rounded,
            title: 'Coordinación',
            subtitle: isFull
                ? 'Indica tu estado para coordinar mejor'
                : 'Coordina mientras se completa el partido',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _CoordinationButton(
                      icon: Icons.check_circle,
                      label: 'Llegué',
                      selected: selectedStatus == 'ARRIVED',
                      enabled: !isUpdating,
                      onTap: () => onSelected('ARRIVED'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _CoordinationButton(
                      icon: Icons.directions_car,
                      label: 'Voy en\ncamino',
                      selected: selectedStatus == 'ON_THE_WAY',
                      highlighted: true,
                      enabled: !isUpdating,
                      onTap: () => onSelected('ON_THE_WAY'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _CoordinationButton(
                      icon: Icons.schedule,
                      label: 'Llego en\n10 min',
                      selected: selectedStatus == 'ARRIVING_10',
                      enabled: !isUpdating,
                      onTap: () => onSelected('ARRIVING_10'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _CoordinationButton(
                      icon: Icons.cancel,
                      label: 'No podré\nir',
                      selected: selectedStatus == 'CANNOT_GO',
                      danger: true,
                      enabled: !isUpdating,
                      onTap: () => onSelected('CANNOT_GO'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChatCard extends StatelessWidget {
  const _QuickChatCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    final updates = alert.coordinationUpdates.take(3).toList();
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 13, color: AppColors.SecondBlue),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Chat rápido',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OpenMatchChatScreen(alert: alert),
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'Ver todo',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (updates.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Aún no hay novedades. Usa coordinación para avisar tu estado.',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            )
          else
            for (final update in updates) _ChatPreviewRow(update: update),
        ],
      ),
    );
  }
}

class OpenMatchChatScreen extends StatefulWidget {
  const OpenMatchChatScreen({super.key, required this.alert});

  final OpenMatchAlert alert;

  @override
  State<OpenMatchChatScreen> createState() => _OpenMatchChatScreenState();
}

class _OpenMatchChatScreenState extends State<OpenMatchChatScreen> {
  final _controller = TextEditingController();

  bool get _canCoordinate =>
      DateTime.now().isAfter(widget.alert.startsAt.subtract(
        const Duration(hours: 1),
      ));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canCoordinate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El chat abre 1 hora antes del partido.')),
      );
      return;
    }
    if (_controller.text.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat real pendiente de backend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updates = widget.alert.coordinationUpdates;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        title: const Text('Chat del partido'),
        backgroundColor: AppColors.SecondBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: updates.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay mensajes.',
                        style: GoogleFonts.inter(
                          color: AppColors.SecondBlue.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      itemBuilder: (_, index) {
                        final update = updates[index];
                        return _ChatPreviewRow(update: update);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: updates.length,
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: _canCoordinate,
                      decoration: InputDecoration(
                        hintText: _canCoordinate
                            ? 'Escribe un mensaje'
                            : 'Disponible 1 hora antes',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.PrimaryGreen,
                      foregroundColor: AppColors.SecondBlue,
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

class _HowToArriveCard extends StatelessWidget {
  const _HowToArriveCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.location_on,
            title: 'Cómo llegar',
            subtitle: 'Encuentra el club y llega sin problemas',
          ),
          const SizedBox(height: 7),
          Text(
            '${alert.club} · ${alert.district}',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 9.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Cerca de la sede principal',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.64),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                  child: _MapButton(
                label: 'Abrir en Google Maps',
                icon: Icons.map,
                query: '${alert.club}, ${alert.district}',
                app: _MapApp.googleMaps,
              )),
              const SizedBox(width: 9),
              Expanded(
                  child: _MapButton(
                label: 'Abrir en Waze',
                icon: Icons.navigation,
                query: '${alert.club}, ${alert.district}',
                app: _MapApp.waze,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvitePlayersCard extends StatelessWidget {
  const _InvitePlayersCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.person_add_alt_1,
            title: 'Invitar jugadores',
            subtitle: 'Comparte e invita a más jugadores',
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                  child: _MapButton(
                      label: 'Compartir por WhatsApp',
                      icon: Icons.chat_bubble_outline)),
              SizedBox(width: 9),
              Expanded(
                  child: _MapButton(
                      label: 'Invitar en PGO', icon: Icons.person_add_alt_1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenMatchResultPendingCard extends StatelessWidget {
  const _OpenMatchResultPendingCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE8F9BB),
            child: Icon(Icons.emoji_events,
                color: AppColors.secondaryGreen, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultado pendiente',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'El partido ya terminó. Registra el resultado para guardar XP y actualizar tu perfil.',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.66),
                    fontSize: 8.2,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ResultChecklistItem(label: 'Resultado'),
              _ResultChecklistItem(label: 'Ganadores'),
              _ResultChecklistItem(label: 'Foto del match'),
              _ResultChecklistItem(label: 'Descripción'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenMatchHeroCard extends StatelessWidget {
  const _OpenMatchHeroCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DogAvatar(radius: 25, imageUrl: alert.organizer.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.category} · ${alert.format}',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 15.2,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_dateLabel(alert.startsAt)} · ${_timeLabel(alert.startsAt)}',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 11, color: AppColors.SecondBlue),
                        Expanded(
                          child: Text(
                            '${alert.club} · ${alert.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.78),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _MissingPlayersPill(
                      missingPlayers: alert.missingPlayers,
                      horizontalPadding: 12,
                      verticalPadding: 3.5,
                      fontSize: 8.2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 21, color: Color(0xFFD7DDE6)),
          _CompactInfoLine(
            icon: Icons.attach_money,
            text: 'Costo estimado: S/ ${alert.costPerPerson} por persona',
          ),
          const SizedBox(height: 3),
          _CompactInfoLine(
            icon: Icons.person,
            text: 'Pago: ${alert.paymentLabel}',
          ),
        ],
      ),
    );
  }
}

class _OpenMatchCommentCard extends StatelessWidget {
  const _OpenMatchCommentCard({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 11, color: AppColors.SecondBlue),
              const SizedBox(width: 5),
              Text(
                'Comentario',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.74),
              fontSize: 9.6,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenMatchResultUnavailableCard extends StatelessWidget {
  const _OpenMatchResultUnavailableCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE9EEF6),
            child: Icon(Icons.info_outline_rounded,
                color: AppColors.SecondBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenMatchCreatorCard extends StatelessWidget {
  const _OpenMatchCreatorCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        children: [
          _DogAvatar(radius: 21, imageUrl: alert.organizer.photoUrl),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creador',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${alert.organizer.name.isEmpty ? 'Jugador' : alert.organizer.name} · ${alert.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.78),
                    fontSize: 9.2,
                    fontWeight: FontWeight.w700,
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

class _OpenMatchConfirmedCard extends StatelessWidget {
  const _OpenMatchConfirmedCard({required this.alert});

  final OpenMatchAlert alert;

  @override
  Widget build(BuildContext context) {
    final confirmed = <OpenMatchUser>[alert.organizer, ...alert.participants];
    final slots = alert.format.toLowerCase() == 'dobles'
        ? 4
        : math
            .max(confirmed.length + alert.missingPlayers, 2)
            .clamp(2, 4)
            .toInt();
    final missingText = alert.missingPlayers == 0
        ? 'Equipo completo'
        : alert.missingPlayers == 1
            ? 'Falta 1 jugador'
            : 'Faltan ${alert.missingPlayers} jugadores';
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, size: 13, color: AppColors.SecondBlue),
              const SizedBox(width: 6),
              Text(
                'Jugadores',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            missingText,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.62),
              fontSize: 10.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(slots, (index) {
              if (index < confirmed.length) {
                return _ConfirmedPlayerBubble(user: confirmed[index]);
              }
              return const _OpenSlotBubble();
            }),
          ),
        ],
      ),
    );
  }
}

class _ConfirmedPlayerBubble extends StatelessWidget {
  const _ConfirmedPlayerBubble({required this.user});

  final OpenMatchUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          _DogAvatar(radius: 24, imageUrl: user.photoUrl),
          const SizedBox(height: 4),
          Text(
            user.name.isEmpty ? 'Jugador' : user.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenSlotBubble extends StatelessWidget {
  const _OpenSlotBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.SecondBlue.withValues(alpha: 0.34),
        ),
        child: const SizedBox.expand(
          child: Icon(
            Icons.add,
            color: AppColors.SecondBlue,
            size: 29,
          ),
        ),
      ),
    );
  }
}

class _PendingPlayerBubble extends StatelessWidget {
  const _PendingPlayerBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: AppColors.SecondBlue.withValues(alpha: 0.34),
              ),
              child: const SizedBox.expand(
                child:
                    Icon(Icons.person, color: AppColors.SecondBlue, size: 31),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Pendiente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 9.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchStatusPlayerBubble extends StatelessWidget {
  const _MatchStatusPlayerBubble({
    required this.user,
    this.status,
  });

  final OpenMatchUser user;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _DogAvatar(radius: 28, imageUrl: user.photoUrl),
              if (status != null)
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: AppColors.secondaryGreen,
                    child: Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            user.name.isEmpty ? 'Jugador' : user.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 9.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (status != null)
            Text(
              status!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.64),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 1.1;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const dashCount = 18;
    final step = (math.pi * 2) / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * step, step * 0.56, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MissingPlayersPill extends StatelessWidget {
  const _MissingPlayersPill({
    required this.missingPlayers,
    this.horizontalPadding = 10,
    this.verticalPadding = 3,
    this.fontSize = 7.2,
  });

  final int missingPlayers;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        missingPlayers == 0 ? 'Completo' : 'Faltan $missingPlayers jugadores',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactInfoLine extends StatelessWidget {
  const _CompactInfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 13, color: AppColors.SecondBlue.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 9.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoMiniRow extends StatelessWidget {
  const _InfoMiniRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon,
              size: 15, color: AppColors.SecondBlue.withValues(alpha: 0.62)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.SecondBlue),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.62),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoordinationButton extends StatelessWidget {
  const _CoordinationButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.danger = false,
    this.selected = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final bool danger;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Colors.redAccent
        : (highlighted ? AppColors.secondaryGreen : AppColors.SecondBlue);
    final borderColor = selected ? color : color.withValues(alpha: 0.35);
    final backgroundColor = selected
        ? color.withValues(alpha: danger ? 0.10 : 0.16)
        : (highlighted ? const Color(0xFFF0FFD1) : Colors.white);
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 8.6,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatPreviewRow extends StatelessWidget {
  const _ChatPreviewRow({required this.update});

  final OpenMatchCoordinationUpdate update;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          _DogAvatar(radius: 18, imageUrl: update.user.photoUrl),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              update.user.name.isEmpty
                  ? 'Jugador'
                  : '${update.user.name.split(' ').first} H.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEEFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                update.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _chatTimeLabel(update.createdAt),
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.58),
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.label,
    required this.icon,
    this.query,
    this.app,
  });

  final String label;
  final IconData icon;
  final String? query;
  final _MapApp? app;

  Future<void> _open(BuildContext context) async {
    if (query == null || app == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acción pendiente de integración.')),
      );
      return;
    }
    final encoded = Uri.encodeComponent(query!);
    final uri = app == _MapApp.waze
        ? Uri.parse('waze://?q=$encoded&navigate=yes')
        : Uri.parse('comgooglemaps://?q=$encoded');
    final fallback = app == _MapApp.waze
        ? Uri.parse('https://waze.com/ul?q=$encoded&navigate=yes')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(fallback, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos abrir el mapa.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border.all(color: AppColors.SecondBlue.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.SecondBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 9,
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

enum _MapApp { googleMaps, waze }

class _ResultChecklistItem extends StatelessWidget {
  const _ResultChecklistItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
              radius: 3, backgroundColor: AppColors.secondaryGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.68),
              fontSize: 7.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.075),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.rows});

  final List<(String, String, IconData)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.075),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.5),
              child: Row(
                children: [
                  Icon(rows[index].$3,
                      size: 15,
                      color: AppColors.SecondBlue.withValues(alpha: 0.55)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      rows[index].$1,
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.55),
                        fontSize: 9.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    rows[index].$2,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 9.6,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (index != rows.length - 1)
              Divider(
                height: 1,
                color: AppColors.SecondBlue.withValues(alpha: 0.10),
              ),
          ],
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final sameDay = now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;
  if (sameDay) return 'Hoy';
  return DateFormat("EEEE d 'de' MMMM", 'es').format(local);
}

String _timeLabel(DateTime date) {
  return DateFormat('h:mm a', 'es')
      .format(date.toLocal())
      .replaceAll('a. m.', 'am')
      .replaceAll('p. m.', 'pm')
      .replaceAll('a.m.', 'am')
      .replaceAll('p.m.', 'pm');
}

String _chatTimeLabel(DateTime date) {
  return DateFormat('h:mm a', 'es')
      .format(date.toLocal())
      .replaceAll('a. m.', 'am')
      .replaceAll('p. m.', 'pm')
      .replaceAll('a.m.', 'am')
      .replaceAll('p.m.', 'pm');
}

Widget _input(String text, {bool trailing = false, IconData? icon}) {
  return Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E4E9),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.SecondBlue, size: 13),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing)
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.SecondBlue, size: 22),
      ],
    ),
  );
}

Widget _tappableInput(
  String text, {
  bool trailing = false,
  IconData? icon,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: _input(text, trailing: trailing, icon: icon),
    ),
  );
}

Widget _editableInput(
  TextEditingController controller, {
  String prefix = '',
}) {
  return Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E4E9),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        if (prefix.isNotEmpty)
          Text(
            prefix,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration.collapsed(hintText: ''),
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _createDateLabel(DateTime date) {
  return DateFormat("EEEE d 'de' MMMM", 'es').format(date);
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'am' : 'pm';
  return '$hour:$minute $suffix';
}

Widget _segmented({
  required String left,
  required String right,
  required bool rightSelected,
  required VoidCallback onLeft,
  required VoidCallback onRight,
}) {
  return Container(
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFE2E4E9),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Expanded(
          child: _segmentButton(left, !rightSelected, onLeft),
        ),
        Expanded(
          child: _segmentButton(right, rightSelected, onRight),
        ),
      ],
    ),
  );
}

Widget _threeSegment({
  required List<int> values,
  required List<String> labels,
  required int selected,
  required ValueChanged<int> onChanged,
}) {
  return Container(
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFE2E4E9),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: _segmentButton(
              labels[i],
              selected == values[i],
              () => onChanged(values[i]),
              small: true,
            ),
          ),
      ],
    ),
  );
}

Widget _segmentButton(
  String label,
  bool selected,
  VoidCallback onTap, {
  bool small = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.SecondBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : AppColors.SecondBlue,
              fontSize: small ? 10.6 : 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlayerBubble extends StatelessWidget {
  const _PlayerBubble({
    required this.name,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          _DogAvatar(radius: 21, imageUrl: imageUrl),
          const SizedBox(height: 5),
          Text(
            name.split(' ').take(2).join(' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlayerSlot extends StatelessWidget {
  const _EmptyPlayerSlot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.SecondBlue.withValues(alpha: 0.24),
                width: 1.2,
              ),
              color: const Color(0xFFF4F6F9),
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.6),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCounter extends StatelessWidget {
  const _InviteCounter({
    required this.selected,
    required this.total,
  });

  final int selected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.PrimaryGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$selected/$total',
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InviteActionButton extends StatelessWidget {
  const _InviteActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.SecondBlue.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.SecondBlue, size: 15),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteQrButton extends StatelessWidget {
  const _InviteQrButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.SecondBlue.withValues(alpha: 0.14),
            ),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.SecondBlue,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _PlayerSelectionCard extends StatelessWidget {
  const _PlayerSelectionCard({
    required this.name,
    required this.label,
    this.imageUrl,
    this.onRemove,
  });

  final String name;
  final String label;
  final String? imageUrl;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.SecondBlue.withValues(alpha: 0.10),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DogAvatar(radius: 19, imageUrl: imageUrl),
              const SizedBox(height: 6),
              Text(
                name.trim().isEmpty ? 'Jugador' : name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.58),
                  fontSize: 8.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (onRemove != null)
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9EDF3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.SecondBlue,
                    size: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyInviteSlot extends StatelessWidget {
  const _EmptyInviteSlot({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: 98,
          height: 89,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.SecondBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.58),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteMessage extends StatelessWidget {
  const _InviteMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.65),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InviteNotice extends StatelessWidget {
  const _InviteNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.PrimaryGreen.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.PrimaryGreen.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.SecondBlue,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({
    required this.user,
    required this.onTap,
  });

  final CommunityUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.SecondBlue.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            _DogAvatar(radius: 20, imageUrl: user.photoUrl),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'Jugador' : user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((user.category ?? '').isNotEmpty) user.category!,
                      if ((user.preferredClub ?? '').isNotEmpty)
                        user.preferredClub!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.58),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.add_circle_rounded,
              color: AppColors.secondaryGreen,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DogAvatar extends StatelessWidget {
  const _DogAvatar({
    required this.radius,
    this.imageUrl,
  });

  final double radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.PrimaryGreen, width: 1.3),
      ),
      child: ClipOval(
        child: (imageUrl ?? '').isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(radius: radius),
              )
            : _AvatarFallback(radius: radius),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E8ED),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: AppColors.SecondBlue.withValues(alpha: 0.55),
        size: radius,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.height = 56,
    this.fontSize = 20,
    this.borderRadius = 20,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          disabledBackgroundColor:
              AppColors.PrimaryGreen.withValues(alpha: 0.5),
          foregroundColor: AppColors.SecondBlue,
          elevation: 6,
          shadowColor: AppColors.PrimaryGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 27 : 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? AppColors.PrimaryGreen : const Color(0xFFE2E4E9),
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 11 : 18),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: compact ? 10 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
