import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lima_padel_clubs.dart';
import '../models/open_match_alert.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/open_match_alert_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_options_menu.dart';
import 'activity_screen.dart';
import 'notifications_screen.dart';
import 'open_match_alerts_screen.dart';
import 'profile_history_screen.dart';
import 'profile_screen.dart';
import 'tournament_description_screen.dart';
import 'tournaments_screen.dart';

const homeCtaGreen = Color(0xFFD7FF4F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.bottomNavigationBar,
    this.onTournamentsTap,
    this.onAlertsTap,
    this.onProfileTap,
    this.initialProfile,
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onTournamentsTap;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;
  final ProfileSummary? initialProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeGuideSeenPrefix = 'home_guide_seen_';

  final List<GlobalKey> _quickAccessKeys = List.generate(4, (_) => GlobalKey());
  ProfileSummary? _profile;
  List<TournamentRecord> _tournaments = const [];
  List<OpenMatchAlert> _openMatchAlerts = const [];
  bool _isLoadingProfile = true;
  String? _profileError;
  bool _isUpdatingProfile = false;
  bool _hasSeenHomeGuide = false;
  bool _isHomeGuideVisible = false;
  int _homeGuideStep = 0;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapHome();
  }

  void _logTiming(String label, Stopwatch watch) {
    debugPrint('pgo_startup $label ${watch.elapsedMilliseconds}ms');
  }

  Future<void> _bootstrapHome() async {
    final watch = Stopwatch()..start();
    if (widget.initialProfile != null) {
      final profile = widget.initialProfile!;
      final hasSeenHomeGuide =
          profile.hasSeenHomeGuide ?? await _readHomeGuideSeen(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _hasSeenHomeGuide = hasSeenHomeGuide;
        _isLoadingProfile = false;
      });
      _logTiming('first_screen_ready', watch);
      _checkHomeGuide();
      unawaited(_loadSecondaryHomeData(watch));
      return;
    }
    await _loadProfile(watch);
  }

  Future<void> _loadProfile([Stopwatch? startupWatch]) async {
    final watch = startupWatch ?? (Stopwatch()..start());
    try {
      final profile = await ProfileService().getMyProfile();
      _logTiming('profile_loaded', watch);
      final hasSeenHomeGuide =
          profile.hasSeenHomeGuide ?? await _readHomeGuideSeen(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _hasSeenHomeGuide = hasSeenHomeGuide;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        _logTiming('first_screen_ready', watch);
        _checkHomeGuide();
        unawaited(_loadSecondaryHomeData(watch));
      }
    }
  }

  Future<void> _loadSecondaryHomeData(Stopwatch watch) async {
    final results = await Future.wait([
      TournamentService().getTournaments().catchError(
            (_) => const <TournamentRecord>[],
          ),
      NotificationService()
          .getNotifications()
          .then((value) => value.unreadCount)
          .catchError((_) => 0),
      OpenMatchAlertService().getAlerts().catchError(
            (_) => const <OpenMatchAlert>[],
          ),
    ]);
    if (!mounted) return;
    setState(() {
      _tournaments = results[0] as List<TournamentRecord>;
      _notificationCount = results[1] as int;
      _openMatchAlerts = results[2] as List<OpenMatchAlert>;
    });
    _logTiming('home_data_loaded', watch);
  }

  String _buildProfileSubtitle() {
    if (_isLoadingProfile) {
      return 'Cargando perfil...';
    }

    if (_profileError != null) {
      return 'No se pudo cargar tu perfil';
    }

    return 'Estás a 1 partido de subir de categoría';
  }

  String _buildGreetingName() {
    final fullName = (_profile?.name ?? 'Jugador').trim();
    if (fullName.isEmpty) {
      return 'Jugador';
    }

    return fullName.split(RegExp(r'\s+')).first;
  }

  TournamentRecord? get _recommendedTournament {
    final profileCategory = _profile?.category?.trim().toUpperCase();
    final upcoming = _tournaments
        .where((item) => item.status == 'PUBLISHED')
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    for (final tournament in upcoming) {
      if (profileCategory != null &&
          profileCategory.isNotEmpty &&
          tournament.category.toUpperCase() == profileCategory) {
        return tournament;
      }
    }

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  OpenMatchAlert? get _recommendedOpenMatch {
    final profileCategory = _normalizeText(_profile?.category);
    final preferredClub = _normalizeText(_profile?.preferredClub);

    final openAlerts = _openMatchAlerts
        .where(
          (item) =>
              item.status == 'OPEN' &&
              !item.hasJoined &&
              !item.isOrganizer &&
              item.missingPlayers > 0,
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    for (final alert in openAlerts) {
      final sameCategory = profileCategory.isNotEmpty &&
          _normalizeText(alert.category) == profileCategory;
      final sameClub = preferredClub.isNotEmpty &&
          _normalizeText(alert.club) == preferredClub;
      if (sameCategory && sameClub) return alert;
    }
    for (final alert in openAlerts) {
      if (profileCategory.isNotEmpty &&
          _normalizeText(alert.category) == profileCategory) {
        return alert;
      }
    }
    return openAlerts.isNotEmpty ? openAlerts.first : null;
  }

  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _formatTournamentDate(DateTime value) {
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

    final local = value.toLocal();
    return '${weekDays[local.weekday - 1]} ${local.day} ${months[local.month - 1]}';
  }

  Future<void> _openActivity() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActivityScreen(),
      ),
    );
    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileHistoryScreen(),
      ),
    );
    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _openSidePicker() async {
    if (_profile == null || _isUpdatingProfile) return;

    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SidePickerDialog(
        initial: _profile?.preferredSide,
      ),
    );

    if (!mounted || selected == null) return;
    if (selected == 'omit') return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final updated = await ProfileService().updateMyProfile(
        name: _profile?.name ?? '',
        preferredSide: selected,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar tu lado de juego.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _openSchedulePicker() async {
    if (_profile == null || _isUpdatingProfile) return;

    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SchedulePickerDialog(
        initial: _profile?.racketModel,
      ),
    );

    if (!mounted || selected == null) return;
    if (selected == 'omit') return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final updated = await ProfileService().updateMyProfile(
        name: _profile?.name ?? '',
        racketModel: selected,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar tu horario habitual.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _openClubPicker() async {
    if (_profile == null || _isUpdatingProfile) return;

    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ClubPickerDialog(
        initial: _profile?.preferredClub,
      ),
    );

    if (!mounted || selected == null) return;
    if (selected == 'omit') return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final updated = await ProfileService().updateMyProfile(
        name: _profile?.name ?? '',
        preferredClub: selected,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar tu club habitual.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<bool> _readHomeGuideSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_homeGuideSeenPrefix$userId') ?? false;
  }

  Future<void> _saveHomeGuideSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_homeGuideSeenPrefix$userId', true);
    try {
      await ProfileService().markHomeGuideSeen();
    } catch (_) {
      // Backend support is optional; local state still prevents repeats.
    }
  }

  void _checkHomeGuide() {
    if (_isLoadingProfile || _profile == null) return;
    if (_hasSeenHomeGuide || _isHomeGuideVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasSeenHomeGuide || _isHomeGuideVisible) return;
      setState(() {
        _isHomeGuideVisible = true;
        _homeGuideStep = 0;
      });
    });
  }

  Future<void> _finishHomeGuide() async {
    final userId = _profile?.id;
    setState(() {
      _isHomeGuideVisible = false;
      _hasSeenHomeGuide = true;
    });
    if (userId != null) {
      await _saveHomeGuideSeen(userId);
    }
  }

  void _nextHomeGuideStep() {
    if (_homeGuideStep >= _HomeGuideOverlay.steps.length - 1) {
      _finishHomeGuide();
      return;
    }
    setState(() {
      _homeGuideStep += 1;
    });
  }

  Future<void> _openRecommendedTournament() async {
    final tournament = _recommendedTournament;
    if (tournament == null) {
      await _openTournamentsSection();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentDescriptionScreen(
          tournament: tournament,
        ),
      ),
    );

    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _openTournamentsSection() async {
    if (widget.onTournamentsTap != null) {
      widget.onTournamentsTap!();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TournamentsScreen(),
      ),
    );

    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _openAlertsSection() async {
    if (widget.onAlertsTap != null) {
      widget.onAlertsTap!();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OpenMatchAlertsScreen(),
      ),
    );

    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _openCreateOpenMatch() async {
    final created = await Navigator.of(context).push<OpenMatchAlert>(
      MaterialPageRoute(
        builder: (context) => const CreateOpenMatchScreen(),
      ),
    );

    if (created != null && mounted) {
      setState(() {
        _openMatchAlerts = [
          created,
          ..._openMatchAlerts.where((alert) => alert.id != created.id),
        ];
      });
      _loadProfile();
    }
  }

  Future<void> _openRecommendedOpenMatch() async {
    final alert = _recommendedOpenMatch;
    if (alert == null) {
      await _openAlertsSection();
      return;
    }

    final updated = await Navigator.of(context).push<OpenMatchAlert>(
      MaterialPageRoute(
        builder: (context) => OpenMatchDetailScreen(alert: alert),
      ),
    );

    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _openMatchAlerts = [
          updated,
          ..._openMatchAlerts.where((item) => item.id != updated.id),
        ];
      });
    }
    _loadProfile();
  }

  Future<void> _openRecommendationButton() async {
    await _openTournamentsSection();
  }

  Future<void> _openRecommendationCard() async {
    final tournament = _recommendedTournament;
    if (tournament == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const TournamentsScreen(),
        ),
      );
      if (!mounted) return;
      _loadProfile();
      return;
    }

    await _openRecommendedTournament();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (!mounted) return;
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF7F7F8),
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: AppColors.headerToolbarHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: const DecoratedBox(
              decoration: AppColors.headerGradientDecoration,
            ),
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/pgoIconoAPP.png',
                  height: 66,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            actions: [
              _HeaderNotificationButton(
                count: _notificationCount,
                onTap: _openNotifications,
              ),
              const SizedBox(width: 2),
              const PgoOptionsMenuButton(),
            ],
          ),
          body: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: AppColors.headerGradientDecoration,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topInset + AppColors.headerToolbarHeight,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F3F5),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(34)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadProfile,
                    color: AppColors.SecondBlue,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 82),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height -
                              (topInset + AppColors.headerToolbarHeight) -
                              96,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHomeHeroSection(),
                            const SizedBox(height: 28),
                            _buildQuickAccessSection(),
                            const SizedBox(height: 34),
                            _buildActivityOverviewCardV2(),
                            const SizedBox(height: 34),
                            _buildHomeRecommendationsSection(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: widget.showBottomNav
              ? widget.bottomNavigationBar ??
                  PgoBottomNav(
                    currentTab: PgoNavTab.home,
                    onHomeTap: () {},
                    onTournamentsTap: widget.onTournamentsTap ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TournamentsScreen(),
                            ),
                          );
                        },
                    onAlertsTap: widget.onAlertsTap ?? _openAlertsSection,
                    onProfileTap: widget.onProfileTap ??
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                  )
              : null,
        ),
        if (_isHomeGuideVisible)
          _HomeGuideOverlay(
            stepIndex: _homeGuideStep,
            targetKey: _quickAccessKeys[_homeGuideStep],
            onSkip: _finishHomeGuide,
            onNext: _nextHomeGuideStep,
          ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Hola ${_buildGreetingName()},',
            textAlign: TextAlign.center,
            style: PgoTextStyles.screenTitle(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _buildProfileSubtitle(),
          textAlign: TextAlign.center,
          style: PgoTextStyles.screenSubtitle(
            color: AppColors.SecondBlue.withValues(alpha: 0.45),
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: 292,
                height: 58,
                child: ElevatedButton(
                  onPressed: _openActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.homeGreen,
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                  ),
                  child: Text(
                    'REGISTRAR MATCH',
                    style: PgoTextStyles.button(weight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Progreso a ${_profile?.category ?? '4ta'} categoría',
                    style: PgoTextStyles.caption(
                      color: AppColors.SecondBlue,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola ${_buildGreetingName()},',
          style: PgoTextStyles.screenTitle().copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Listo para un nuevo partido?',
          style: PgoTextStyles.screenSubtitle(
            color: const Color(0xFF7D8795),
            weight: FontWeight.w600,
          ).copyWith(
            fontSize: 13,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: PgoTextStyles.sectionTitle(
            color: AppColors.SecondBlue,
            weight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QuickAccessButton(
              key: _quickAccessKeys[0],
              assetPath: 'assets/images/quick_register_match.png',
              label: 'Registrar\nmatch',
              onTap: _openActivity,
            ),
            _QuickAccessButton(
              key: _quickAccessKeys[1],
              assetPath: 'assets/images/quick_create_alert.png',
              label: 'Crear\nalerta',
              onTap: _openCreateOpenMatch,
            ),
            _QuickAccessButton(
              key: _quickAccessKeys[2],
              assetPath: 'assets/images/quick_find_match.png',
              label: 'Buscar\npartido',
              onTap: _openAlertsSection,
            ),
            _QuickAccessButton(
              key: _quickAccessKeys[3],
              assetPath: 'assets/images/quick_find_tournament.png',
              label: 'Buscar\ntorneo',
              onTap: _openTournamentsSection,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityOverviewCardV2() {
    final profile = _profile;
    final category = profile?.category?.trim().isNotEmpty == true
        ? profile!.category!
        : '5ta categoría';
    final matches = profile?.matchesPlayed ?? 0;
    final winRate = (profile?.winRate ?? 0).round();
    final monthlyMatches = profile?.weeklyStreak ?? 0;
    final progress = (winRate / 100).clamp(0.08, 1.0);
    final lastResult = _formatLastActivityResult(profile);

    return Container(
      height: 206,
      padding: const EdgeInsets.fromLTRB(18, 15, 14, 14),
      decoration: _homeCardDecoration(radius: 22),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniBadge(text: category),
                      const SizedBox(height: 8),
                      Text(
                        'Tu actividad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.cardTitle(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF9AC529),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Último resultado: ',
                            style: PgoTextStyles.caption(
                              color: const Color(0xFF7A8492),
                              weight: FontWeight.w800,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              lastResult.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PgoTextStyles.caption(
                                color: lastResult.isPositive
                                    ? const Color(0xFF9AC529)
                                    : const Color(0xFF7A8492),
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildActivityMetricRow(
                        matches: matches,
                        winRate: winRate,
                        progress: progress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 104,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/images/home_activity_padel.png',
                      width: 112,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE1E5EC)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EDF3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.SecondBlue,
                  size: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Este mes: ',
                style: PgoTextStyles.caption(
                  color: const Color(0xFF66717F),
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                '$monthlyMatches partidos',
                style: PgoTextStyles.caption(
                  color: const Color(0xFF9AC529),
                  weight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetricRow({
    required int matches,
    required int winRate,
    required double progress,
  }) {
    return SizedBox(
      height: 54,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/home_matches_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.view_week_rounded,
                color: AppColors.SecondBlue,
                size: 38,
              ),
            ),
            const SizedBox(width: 9),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$matches',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'partidos',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(
              width: 1,
              height: 43,
              color: const Color(0xFFE1E5EC),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: const Color(0xFFE6EAF0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9BC62E),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$winRate%',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'win rate',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({String label, bool isPositive}) _formatLastActivityResult(
    ProfileSummary? profile,
  ) {
    final history = profile?.matchHistory ?? const <Map<String, dynamic>>[];
    if (history.isEmpty) {
      return (label: 'Aún sin resultados', isPositive: false);
    }

    final item = history.first;
    final result = (item['result'] as String? ?? '').toUpperCase();
    final score = (item['score'] ??
            item['finalScore'] ??
            item['setsScore'] ??
            item['resultScore'] ??
            '')
        .toString()
        .trim();

    if (result == 'WIN') {
      return (
        label: score.isNotEmpty ? 'Ganaste $score' : 'Ganaste',
        isPositive: true,
      );
    }

    if (result == 'LOSS') {
      return (
        label: score.isNotEmpty ? 'Perdiste $score' : 'Perdiste',
        isPositive: false,
      );
    }

    return (label: 'Resultado pendiente', isPositive: false);
  }

  Widget _buildActivityOverviewCard() {
    final profile = _profile;
    final category = profile?.category?.trim().isNotEmpty == true
        ? profile!.category!
        : '5ta categoría';
    final matches = profile?.matchesPlayed ?? 0;
    final winRate = (profile?.winRate ?? 0).round();
    final monthlyMatches = profile?.weeklyStreak ?? 0;
    final progress = (winRate / 100).clamp(0.08, 1.0);
    final lastResult = _formatLastActivityResult(profile);

    return Container(
      height: 198,
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: _homeCardDecoration(radius: 22),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: 0,
            bottom: 24,
            child: Image.asset(
              'assets/images/home_activity_padel.png',
              width: 136,
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.high,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniBadge(text: category),
              const SizedBox(height: 8),
              Text(
                'Tu actividad',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF9AC529),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Último resultado: ',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7A8492),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Ganaste 2 - 0',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9AC529),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 232,
                height: 44,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/home_matches_icon.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.view_week_rounded,
                          color: AppColors.SecondBlue,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$matches',
                        style: GoogleFonts.inter(
                          color: AppColors.SecondBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'partidos',
                        style: GoogleFonts.inter(
                          color: AppColors.SecondBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 1,
                        height: 42,
                        color: const Color(0xFFE1E5EC),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: const Color(0xFFE6EAF0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF9BC62E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$winRate%',
                        style: GoogleFonts.inter(
                          color: AppColors.SecondBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'win rate',
                        style: GoogleFonts.inter(
                          color: AppColors.SecondBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE1E5EC)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Image.asset(
                    'assets/images/home_matches_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.SecondBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Este mes: ',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF66717F),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$monthlyMatches partidos',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9AC529),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            'Recomendaciones para ti',
            style: PgoTextStyles.sectionTitle(
              color: AppColors.SecondBlue,
              weight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildFeaturedTournamentCard(),
        const SizedBox(height: 24),
        _buildFeaturedOpenMatchCard(),
      ],
    );
  }

  Widget _buildFeaturedTournamentCard() {
    final tournament = _recommendedTournament;
    final title = tournament?.title ?? 'Torneo PGO';
    final category =
        tournament?.category ?? (_profile?.category ?? '5ta categoría');
    final club = tournament?.location ?? 'One Padel Trigal';
    final date = tournament == null
        ? 'Lunes 19 Dic'
        : _formatTournamentDate(tournament.startsAt);

    return GestureDetector(
      onTap: _openRecommendedTournament,
      child: Container(
        height: 172,
        decoration: _homeCardDecoration(radius: 24),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HomeRecommendationImage(
              imageAsset: AppAssets.defaultTournamentImage,
              photoUrl: tournament?.photoUrl,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.94),
                    Colors.white.withValues(alpha: 0.72),
                    Colors.white.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [
                    0,
                    0.34,
                    0.52,
                    0.68,
                    0.84,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _MiniBadge(text: category),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: PgoTextStyles.cardTitle(),
                        ),
                        const SizedBox(height: 7),
                        _TournamentMetaLine(
                          icon: Icons.location_on,
                          text: '$club · Surco',
                          color: AppColors.SecondBlue,
                        ),
                        const SizedBox(height: 5),
                        _TournamentMetaLine(
                          icon: Icons.calendar_month_rounded,
                          text: date,
                          color: AppColors.SecondBlue,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 145,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: _openTournamentsSection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: homeCtaGreen,
                              foregroundColor: AppColors.SecondBlue,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Ver más torneos',
                              textAlign: TextAlign.center,
                              style: PgoTextStyles.buttonSecondary(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _WhiteInfoChip(
                        icon: Icons.local_fire_department_rounded,
                        text: tournament == null
                            ? '1 buscando dupla'
                            : '${tournament.soloRegistrationsCount} buscando dupla',
                      ),
                      const SizedBox(height: 7),
                      _WhiteInfoChip(
                        icon: Icons.local_fire_department_rounded,
                        text:
                            '${tournament?.registeredPlayers.length ?? 3} amigos inscritos',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedOpenMatchCard() {
    final alert = _recommendedOpenMatch;
    final category = alert?.category ?? (_profile?.category ?? '4ta');
    final format = alert?.format ?? 'Dobles';
    final club = alert?.club ?? 'One Padel Trigal';
    final time = alert == null ? '6:00 pm' : _formatTime(alert.startsAt);
    final dayLabel = alert == null ? 'Hoy' : _formatShortDay(alert.startsAt);
    final missing = alert?.missingPlayers ?? 2;

    return GestureDetector(
      onTap: _openRecommendedOpenMatch,
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: EdgeInsets.zero,
        decoration: _homeCardDecoration(radius: 19),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarCircle(
                    photoUrl: alert?.organizer.photoUrl,
                    borderColor: homeCtaGreen,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$category · $format',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PgoTextStyles.cardSubtitle(
                            weight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: const Color(0xFF566170),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$dayLabel · $time',
                              style: PgoTextStyles.cardDetail(
                                color: const Color(0xFF566170),
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: Color(0xFF566170),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '$club · Surco',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PgoTextStyles.cardDetail(
                                  color: const Color(0xFF566170),
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: SizedBox(
                      width: 112,
                      height: 33,
                      child: ElevatedButton(
                        onPressed: _openRecommendedOpenMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: homeCtaGreen,
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Ver partido',
                          style: PgoTextStyles.buttonSecondary(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              top: 12,
              child: _MiniBadge(
                text: 'Partido sugerido para ti',
                color: const Color(0xFFE9F8CB),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: _MiniBadge(
                text: 'Faltan $missing jugadores',
                color: homeCtaGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $suffix';
  }

  String _formatShortDay(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Hoy';
    if (day == today.add(const Duration(days: 1))) return 'Mañana';
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[local.weekday - 1];
  }

  BoxDecoration _homeCardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _buildCompleteProfileSection() {
    final side = _profile?.preferredSide?.trim().isNotEmpty == true
        ? _profile!.preferredSide!
        : 'pendiente';
    final schedule = _profile?.racketModel?.trim().isNotEmpty == true
        ? _profile!.racketModel!
        : 'pendiente';
    final club = _profile?.preferredClub?.trim().isNotEmpty == true
        ? _profile!.preferredClub!
        : 'pendiente';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completa tu perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Te podremos recomendar mejores torneos y jugadores',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileHintRow(
            icon: Icons.sports_tennis,
            label: 'Lado de juego',
            value: side,
            onTap: _openSidePicker,
          ),
          const SizedBox(height: 8),
          _ProfileHintRow(
            icon: Icons.schedule,
            label: 'Horario habitual',
            value: schedule,
            onTap: _openSchedulePicker,
          ),
          const SizedBox(height: 8),
          _ProfileHintRow(
            icon: Icons.place,
            label: 'Club habitual',
            value: club,
            onTap: _openClubPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileReadySection() {
    final profile = _profile;
    final category = profile?.category?.isNotEmpty == true
        ? profile!.category!
        : '4ta categoría';
    final side = profile?.preferredSide?.isNotEmpty == true
        ? profile!.preferredSide!
        : 'Drive';
    final schedule = profile?.racketModel?.isNotEmpty == true
        ? profile!.racketModel!
        : 'Noche';
    final club = profile?.preferredClub?.isNotEmpty == true
        ? profile!.preferredClub!
        : 'One Padel Trigal';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu perfil está listo',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ya podemos recomendarte mejores torneos y jugadores',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EBF2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$category | $side | $schedule | $club',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 170,
              height: 36,
              child: ElevatedButton(
                onPressed: _openRecommendedTournament,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Ver torneos',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Editar perfil',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    final tournament = _recommendedTournament;
    final tournamentDate =
        tournament == null ? null : _formatTournamentDate(tournament.startsAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones para ti',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openRecommendationCard,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HomeRecommendationImage(
                    imageAsset: AppAssets.defaultTournamentImage,
                    photoUrl: tournament?.photoUrl,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.34, 0.7, 1.0],
                        colors: [
                          Color(0xE623334B),
                          Color(0xC623334B),
                          Color(0x4023334B),
                          Color(0x10000000),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tournament?.category ??
                                    (_profile?.category ?? 'Sin categoría'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tournament?.title ?? 'Sin torneos recomendados',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 118,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: _openRecommendationButton,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.homeGreen,
                                    foregroundColor: AppColors.SecondBlue,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver más torneos',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _InfoChip(
                              icon: Icons.whatshot,
                              text: tournament == null
                                  ? 'Sin recomendacion'
                                  : '${tournament.registrationsCount} inscritos',
                            ),
                            const SizedBox(height: 6),
                            _InfoChip(
                              icon: Icons.sports_tennis,
                              text: tournament == null
                                  ? 'Explora torneos'
                                  : tournament.format,
                            ),
                            const Spacer(),
                            Text(
                              tournament == null
                                  ? (_profile?.preferredClub ??
                                      'Sin club favorito')
                                  : '$tournamentDate\n${tournament.location}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TournamentMetaLine extends StatelessWidget {
  const _TournamentMetaLine({
    required this.icon,
    required this.text,
    this.color = Colors.white,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeGuideStep {
  const _HomeGuideStep({
    required this.count,
    required this.title,
    required this.body,
    required this.assetPath,
  });

  final String count;
  final String title;
  final String body;
  final String assetPath;
}

class _HomeGuideOverlay extends StatelessWidget {
  const _HomeGuideOverlay({
    required this.stepIndex,
    required this.targetKey,
    required this.onSkip,
    required this.onNext,
  });

  static const steps = [
    _HomeGuideStep(
      count: '1/4',
      title: 'Registra tu actividad',
      body: 'Guarda tus partidos y resultados para actualizar tu historial.',
      assetPath: 'assets/images/quick_register_match.png',
    ),
    _HomeGuideStep(
      count: '2/4',
      title: 'Crea un partido',
      body:
          'Publica un partido abierto para encontrar jugadores y coordinar facilmente.',
      assetPath: 'assets/images/quick_create_alert.png',
    ),
    _HomeGuideStep(
      count: '3/4',
      title: 'Encuentra un partido',
      body: 'Descubre partidos abiertos segun tu categoria, horario y zona.',
      assetPath: 'assets/images/quick_find_match.png',
    ),
    _HomeGuideStep(
      count: '4/4',
      title: 'Unete a un torneo',
      body:
          'Explora torneos disponibles, inscribete y sigue tus partidos desde la app.',
      assetPath: 'assets/images/quick_find_tournament.png',
    ),
  ];

  final int stepIndex;
  final GlobalKey targetKey;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final step = steps[stepIndex];
    final size = MediaQuery.sizeOf(context);
    final target = _targetRect();
    final guideIconRect = target.inflate(18);
    final cardWidth = (size.width * 0.52).clamp(210.0, 268.0);
    final left = (target.center.dx - cardWidth / 2).clamp(
      18.0,
      size.width - cardWidth - 18,
    );
    final belowTop = target.bottom + 36;
    final aboveTop = target.top - 178;
    final top = belowTop + 174 < size.height ? belowTop : aboveTop;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(color: Colors.black.withValues(alpha: 0.58)),
            ),
          ),
          Positioned.fromRect(
            rect: guideIconRect,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.95),
                      blurRadius: 18,
                      spreadRadius: 9,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.65),
                      blurRadius: 34,
                      spreadRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: target,
            child: IgnorePointer(
              child: Image.asset(
                step.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: cardWidth,
            child: _HomeGuideCard(
              step: step,
              isLast: stepIndex == steps.length - 1,
              arrowX: target.center.dx - left,
              onSkip: onSkip,
              onNext: onNext,
            ),
          ),
        ],
      ),
    );
  }

  Rect _targetRect() {
    final context = targetKey.currentContext;
    if (context == null) return const Rect.fromLTWH(80, 310, 82, 82);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return const Rect.fromLTWH(80, 310, 82, 82);
    }
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }
}

class _HomeGuideCard extends StatelessWidget {
  const _HomeGuideCard({
    required this.step,
    required this.isLast,
    required this.arrowX,
    required this.onSkip,
    required this.onNext,
  });

  final _HomeGuideStep step;
  final bool isLast;
  final double arrowX;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final clampedArrow = arrowX.clamp(22.0, 246.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -11,
          left: clampedArrow - 11,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 22, height: 22, color: Colors.white),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const ShapeDecoration(
                  color: Color(0xFFD7FF4F),
                  shape: StadiumBorder(),
                ),
                child: Text(
                  step.count,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.body,
                style: GoogleFonts.inter(
                  color: const Color(0xFF5F6978),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.SecondBlue,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 34),
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF4F),
                        foregroundColor: AppColors.SecondBlue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        isLast ? 'Entendido' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderNotificationButton extends StatelessWidget {
  const _HeaderNotificationButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visibleCount = count > 99 ? '99+' : '$count';

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        onPressed: onTap,
        tooltip: 'Notificaciones',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 27,
            ),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7FF4F),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.SecondBlue, width: 1),
                  ),
                  child: Text(
                    visibleCount,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            SizedBox(
              height: 82,
              child: OverflowBox(
                maxWidth: 112,
                maxHeight: 112,
                child: Image.asset(
                  assetPath,
                  width: 108,
                  height: 108,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      color: AppColors.SecondBlue,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue,
                fontSize: 8.2,
                fontWeight: FontWeight.w600,
                height: 1.08,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.SecondBlue,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.SecondBlue,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.text,
    this.color = const Color(0xFFE9F8CB),
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WhiteInfoChip extends StatelessWidget {
  const _WhiteInfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    this.photoUrl,
    this.borderColor = AppColors.PrimaryGreen,
  });

  final String? photoUrl;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();

    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: borderColor,
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _DefaultAvatar(),
                )
              : const _DefaultAvatar(),
        ),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7EAF0),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8D96A4),
        size: 34,
      ),
    );
  }
}

class _HomeRecommendationImage extends StatelessWidget {
  const _HomeRecommendationImage({
    required this.imageAsset,
    this.photoUrl,
  });

  final String imageAsset;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dataBytes = tryDecodeDataUrl(photoUrl);
        final fallback = Image.asset(
          imageAsset,
          width: constraints.maxWidth * 1.18,
          height: constraints.maxHeight * 1.08,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        );

        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.center,
            child: photoUrl != null && photoUrl!.startsWith('http')
                ? Image.network(
                    photoUrl!,
                    width: constraints.maxWidth * 1.18,
                    height: constraints.maxHeight * 1.08,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => fallback,
                  )
                : dataBytes != null
                    ? Image.memory(
                        dataBytes,
                        width: constraints.maxWidth * 1.18,
                        height: constraints.maxHeight * 1.08,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      )
                    : fallback,
          ),
        );
      },
    );
  }
}

class _DayBadge extends StatelessWidget {
  final String day;
  final String value;

  const _DayBadge({
    required this.day,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHintRow extends StatelessWidget {
  const _ProfileHintRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.SecondBlue,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}

class _ProfileOnboardingResult {
  const _ProfileOnboardingResult({
    required this.name,
    required this.phone,
    required this.photoUrl,
    this.omitted = false,
  });

  final String name;
  final String phone;
  final String photoUrl;
  final bool omitted;
}

class _CompleteProfileOnboardingDialog extends StatefulWidget {
  const _CompleteProfileOnboardingDialog({
    required this.initialName,
    required this.email,
    required this.initialPhotoUrl,
    required this.initialPhone,
  });

  final String initialName;
  final String email;
  final String? initialPhotoUrl;
  final String initialPhone;

  @override
  State<_CompleteProfileOnboardingDialog> createState() =>
      _CompleteProfileOnboardingDialogState();
}

class _CompleteProfileOnboardingDialogState
    extends State<_CompleteProfileOnboardingDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _photoDataUrl;
  bool _savingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _photoDataUrl = widget.initialPhotoUrl;
    _nameController.addListener(_refresh);
    _phoneController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _phoneController.removeListener(_refresh);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        !_savingImage;
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickPhoto() async {
    try {
      setState(() {
        _savingImage = true;
      });
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) {
        setState(() {
          _savingImage = false;
        });
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final mimeType = _guessMimeType(picked.path);
      setState(() {
        _photoDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
        _savingImage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo seleccionar la foto.')),
      );
    }
  }

  String _guessMimeType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final photoBytes = tryDecodeDataUrl(_photoDataUrl);
    final hasNetworkPhoto =
        _photoDataUrl != null && _photoDataUrl!.startsWith('http');

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Completa tu perfil',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Añade tus datos básicos para empezar a jugar',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.74),
                  fontSize: 12.3,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB6C3D9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.SecondBlue.withValues(alpha: 0.08),
                      ),
                    ),
                    child: photoBytes != null
                        ? ClipOval(
                            child: Image.memory(photoBytes, fit: BoxFit.cover),
                          )
                        : hasNetworkPhoto
                            ? ClipOval(
                                child: Image.network(
                                  _photoDataUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.add_rounded,
                                    size: 84,
                                    color: Color(0xFFE9EEF7),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_rounded,
                                size: 84,
                                color: Color(0xFFE9EEF7),
                              ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Material(
                      color: AppColors.SecondBlue,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _savingImage ? null : _pickPhoto,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Haz que otros jugadores te reconozcan más fácil.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _OnboardingFieldLabel(text: 'Nombre'),
              const SizedBox(height: 6),
              _OnboardingTextField(
                controller: _nameController,
                hintText: 'Romario Moises',
              ),
              const SizedBox(height: 14),
              _OnboardingFieldLabel(text: 'Correo registrado'),
              const SizedBox(height: 6),
              _OnboardingTextField(
                initialValue: widget.email,
                enabled: false,
              ),
              const SizedBox(height: 14),
              _OnboardingFieldLabel(text: 'Número de teléfono'),
              const SizedBox(height: 6),
              _OnboardingTextField(
                controller: _phoneController,
                hintText: '999 999 999',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit
                      ? () {
                          Navigator.of(context).pop(
                            _ProfileOnboardingResult(
                              name: _nameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              photoUrl: (_photoDataUrl ?? '').trim(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    foregroundColor: AppColors.SecondBlue,
                    disabledBackgroundColor:
                        const Color(0xFFD7FF59).withValues(alpha: 0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Guardar y continuar',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  const _ProfileOnboardingResult(
                    name: '',
                    phone: '',
                    photoUrl: '',
                    omitted: true,
                  ),
                ),
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Omitir',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.56),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _OnboardingFieldLabel extends StatelessWidget {
  const _OnboardingFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.SecondBlue,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OnboardingTextField extends StatelessWidget {
  const _OnboardingTextField({
    this.controller,
    this.initialValue,
    this.hintText,
    this.enabled = true,
    this.keyboardType,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue.withValues(alpha: 0.92),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE3E6EC),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SidePickerDialog extends StatefulWidget {
  const _SidePickerDialog({
    this.initial,
  });

  final String? initial;

  @override
  State<_SidePickerDialog> createState() => _SidePickerDialogState();
}

class _SidePickerDialogState extends State<_SidePickerDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial?.toLowerCase();
    if (initial == 'drive' || initial == 'reves') {
      _selected = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu lado de juego',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Juegas de drive o reves?',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _SideOptionPill(
              label: 'Drive',
              selected: _selected == 'drive',
              onTap: () => setState(() => _selected = 'drive'),
            ),
            const SizedBox(height: 10),
            _SideOptionPill(
              label: 'Reves',
              selected: _selected == 'reves',
              onTap: () => setState(() => _selected = 'reves'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  disabledBackgroundColor:
                      const Color(0xFFD7FF59).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop('omit'),
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Omitir',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideOptionPill extends StatelessWidget {
  const _SideOptionPill({
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : const Color(0xFFE7EBF2),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.SecondBlue,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SchedulePickerDialog extends StatefulWidget {
  const _SchedulePickerDialog({
    this.initial,
  });

  final String? initial;

  @override
  State<_SchedulePickerDialog> createState() => _SchedulePickerDialogState();
}

class _SchedulePickerDialogState extends State<_SchedulePickerDialog> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial?.toLowerCase();
    if (initial == 'flexible' || initial == 'tarde' || initial == 'noche') {
      _selected = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu lado de juego',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'En que horario sueles jugar',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _ScheduleOptionRow(
              options: const ['Flexible', 'Tarde', 'Noche'],
              selected: _selected,
              onSelected: (value) => setState(() => _selected = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  disabledBackgroundColor:
                      const Color(0xFFD7FF59).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop('omit'),
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Omitir',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleOptionRow extends StatelessWidget {
  const _ScheduleOptionRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EBF2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: options
            .map(
              (label) => Expanded(
                child: _ScheduleOptionPill(
                  label: label,
                  selected: selected == label.toLowerCase(),
                  onTap: () => onSelected(label.toLowerCase()),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ScheduleOptionPill extends StatelessWidget {
  const _ScheduleOptionPill({
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
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.SecondBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.SecondBlue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ClubPickerDialog extends StatefulWidget {
  const _ClubPickerDialog({
    this.initial,
  });

  final String? initial;

  @override
  State<_ClubPickerDialog> createState() => _ClubPickerDialogState();
}

class _ClubPickerDialogState extends State<_ClubPickerDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial?.trim();
    _selected =
        initial != null && initial.isNotEmpty ? initial : limaPadelClubs.first;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu lado de juego',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecciona tu club preferido',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EBF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selected,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: limaPadelClubs
                      .map(
                        (club) => DropdownMenuItem(
                          value: club,
                          child: Text(
                            club,
                            style: const TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selected = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop('omit'),
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'Omitir',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
