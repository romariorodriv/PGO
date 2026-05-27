import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/open_match_alert.dart';
import '../services/open_match_alert_service.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'main_shell.dart';

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
  bool _hasLocationPermission = false;

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
    return _alerts.where((alert) {
      final matchesTab = switch (_selectedTab) {
        _OpenMatchTabType.available => alert.status.toUpperCase() == 'OPEN' &&
            alert.missingPlayers > 0 &&
            !alert.hasJoined &&
            !alert.isOrganizer,
        _OpenMatchTabType.myAlerts =>
          alert.isOrganizer || _localCreatedAlertIds.contains(alert.id),
        _OpenMatchTabType.myMatches => alert.hasJoined,
      };
      if (!matchesTab) return false;

      if (_selectedFilters.contains(_OpenMatchFilterType.today) &&
          !_isSameLocalDay(alert.startsAt, DateTime.now())) {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.nearMe) &&
          !alert.district.toLowerCase().contains('surco')) {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.fourth) &&
          alert.category.toLowerCase() != '4ta') {
        return false;
      }
      if (_selectedTab == _OpenMatchTabType.available &&
          _selectedFilters.contains(_OpenMatchFilterType.doubles) &&
          alert.format.toLowerCase() != 'dobles') {
        return false;
      }

      if (query.isEmpty) return true;
      return alert.club.toLowerCase().contains(query) ||
          alert.district.toLowerCase().contains(query) ||
          alert.category.toLowerCase().contains(query) ||
          alert.format.toLowerCase().contains(query);
    }).toList();
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
    final updated = await Navigator.of(context).push<OpenMatchAlert>(
      MaterialPageRoute(
        builder: (_) => OpenMatchDetailScreen(alert: alert),
      ),
    );
    if (updated != null) {
      await _loadAlerts();
    }
  }

  Future<bool> _ensureLocationPermission() async {
    if (_hasLocationPermission) return true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Activa la ubicación del celular para ver partidos cerca de ti.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final allowed = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (!mounted) return false;
    setState(() => _hasLocationPermission = allowed);

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Necesitamos permiso de ubicación para filtrar partidos cercanos.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return allowed;
  }

  Future<void> _toggleFilter(_OpenMatchFilterType filter) async {
    if (_selectedTab != _OpenMatchTabType.available) return;

    if (filter == _OpenMatchFilterType.nearMe &&
        !_selectedFilters.contains(filter)) {
      final allowed = await _ensureLocationPermission();
      if (!allowed) return;
    }

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
      padding: const EdgeInsets.only(bottom: 12),
      child: _OpenMatchCard(
        alert: alert,
        onTap: () => _openDetail(alert),
      ),
    );

    if (!canDelete) return card;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.PrimaryGreen,
        foregroundColor: AppColors.SecondBlue,
        elevation: 5,
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _OpenMatchFooter(
        currentTab: PgoNavTab.alerts,
        onBackTap: widget.onBackTap,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
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
                            color: AppColors.SecondBlue.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          hintText: 'Buscar sede, zona o nivel',
                          hintStyle: PgoTextStyles.bodySecondary(
                            color: AppColors.SecondBlue.withValues(alpha: 0.65),
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
                          onToggle: _toggleFilter,
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAlerts,
                          color: AppColors.SecondBlue,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 88),
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

class _OpenMatchTabs extends StatelessWidget {
  const _OpenMatchTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  final _OpenMatchTabType selectedTab;
  final ValueChanged<_OpenMatchTabType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F3F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC9D0DB), width: 1),
        ),
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
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: selected
                    ? const Color(0xFF31577F)
                    : AppColors.SecondBlue.withValues(alpha: 0.48),
                fontSize: 11.1,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          if (selected)
            FractionallySizedBox(
              widthFactor: 0.56,
              child: Container(
                height: 2.4,
                decoration: BoxDecoration(
                  color: const Color(0xFF31577F),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpenMatchFilters extends StatelessWidget {
  const _OpenMatchFilters({
    required this.selectedFilters,
    required this.onToggle,
  });

  final Set<_OpenMatchFilterType> selectedFilters;
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
              label: 'Cerca de mí',
              icon: Icons.location_on,
              selected: selectedFilters.contains(_OpenMatchFilterType.nearMe),
              onTap: () => onToggle(_OpenMatchFilterType.nearMe),
            ),
            _FilterChipPgo(
              label: '4ta',
              icon: Icons.bar_chart_rounded,
              selected: selectedFilters.contains(_OpenMatchFilterType.fourth),
              onTap: () => onToggle(_OpenMatchFilterType.fourth),
            ),
            _FilterChipPgo(
              label: 'Dobles',
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
  final OpenMatchAlertService _service = OpenMatchAlertService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _costController =
      TextEditingController(text: '25');
  final TextEditingController _commentController = TextEditingController(
    text:
        'Partido tranquilo para sumar gente, nivel intermedio, ideal puntualidad.',
  );
  static const List<String> _categories = ['3ra', '4ta', '5ta', '6ta'];
  static const List<({String club, String district})> _clubs = [
    (club: 'One Padel Trigal', district: 'Surco'),
    (club: 'One Padel Olguín', district: 'Surco'),
    (club: 'Lima Padel', district: 'Surco'),
    (club: 'Mad Padel', district: 'La Molina'),
    (club: 'Padel 360', district: 'Surco'),
  ];
  String _category = '4ta';
  String _club = 'One Padel Trigal';
  String _district = 'Surco';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _playerName = 'Jugador';
  String? _playerPhotoUrl;
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
      if (!startsAt.isAfter(DateTime.now())) {
        throw Exception('Elige una fecha y hora futura para publicar.');
      }
      final created = await _service.createAlert(
        category: _category,
        format: _isDoubles ? 'Dobles' : 'Singles',
        startsAt: startsAt,
        club: _club,
        district: _district,
        courtStatus: _courtReserved ? 'Reservada' : 'Por confirmar',
        missingPlayers: _missingPlayers,
        costPerPerson: int.tryParse(_costController.text.trim()) ?? 25,
        paymentLabel: _payOrganizer ? 'Con coordinador' : 'Pago en sede',
        comment: _commentController.text,
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> values,
    required String Function(T value) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
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
                title,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
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
                          onLeft: () => setState(() => _isDoubles = false),
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
                          values: const [1, 2, 3],
                          selected: _missingPlayers,
                          labels: const [
                            '1 jugador',
                            '2 jugadores',
                            '3 jugadores',
                          ],
                          onChanged: (value) =>
                              setState(() => _missingPlayers = value),
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
              child: _input('Nombre del jugador', icon: Icons.search_rounded),
            ),
            const SizedBox(width: 8),
            SizedBox(
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
            const _EmptyPlayerSlot(label: 'Jugador 2'),
            const _EmptyPlayerSlot(label: 'Jugador 3'),
            const _EmptyPlayerSlot(label: 'Jugador 4'),
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
  bool _isUpdatingCoordination = false;
  String? _selectedCoordinationStatus;

  bool get _isMyMatch => _alert.hasJoined || _alert.isOrganizer;
  bool get _isFull =>
      _alert.status.toUpperCase() == 'FULL' || _alert.missingPlayers == 0;
  bool get _resultPending => _isFull && DateTime.now().isAfter(_alert.startsAt);

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
        const SizedBox(height: 12),
        _OpenMatchCommentCard(comment: _alert.comment!.trim()),
      ],
      const SizedBox(height: 10),
      _OpenMatchCreatorCard(alert: _alert),
      const SizedBox(height: 10),
      _OpenMatchConfirmedCard(alert: _alert),
      const SizedBox(height: 10),
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
          onTap: () {},
          height: 38,
          fontSize: 16,
          borderRadius: 22,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Volver a partidos',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.76),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 18),
        _PrimaryButton(
          label: 'Voy en camino',
          onTap: () {},
          height: 38,
          fontSize: 16,
          borderRadius: 22,
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirmar unión',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vas a unirte a este partido abierto.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 20),
            _MiniMatchSummary(alert: alert, compact: true),
            const Divider(height: 20),
            Text(
              'Tu cupo quedará confirmado al instante.',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
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
                    : (alert.missingPlayers == 0 ? 'En camino' : 'Llegu?'),
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
              Text(
                'Ver todo',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w900,
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
            title: '¿Cómo llegar',
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
            children: const [
              Expanded(
                  child: _MapButton(
                      label: 'Abrir en Google Maps', icon: Icons.map)),
              SizedBox(width: 9),
              Expanded(
                  child: _MapButton(
                      label: 'Abrir en Waze', icon: Icons.navigation)),
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
    final slots = alert.totalMissingPlayers + 1;
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
                'Ya confirmados',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(slots.clamp(2, 4), (index) {
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
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.SecondBlue.withValues(alpha: 0.18)),
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
    );
  }
}

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
