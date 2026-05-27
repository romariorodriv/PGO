import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../utils/tournament_rules.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'profile_screen.dart';
import 'tournament_admin_screen.dart';
import 'tournament_create_flow_screen.dart';
import 'tournament_description_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({
    super.key,
    this.showBottomNav = true,
    this.bottomNavigationBar,
    this.onBackTap,
    this.onHomeTap,
    this.onProfileTap,
    this.isActive = true,
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;
  final bool isActive;

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with WidgetsBindingObserver {
  static const _autoRefreshInterval = Duration(seconds: 25);

  final TextEditingController _searchController = TextEditingController();

  List<TournamentRecord> _tournaments = const [];
  ProfileSummary? _profile;
  bool _showMyTournaments = false;
  _MyTournamentTab _myTournamentTab = _MyTournamentTab.registered;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    _loadData();
    _syncAutoRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant TournamentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadData(showLoading: false);
    }
    if (oldWidget.isActive != widget.isActive) {
      _syncAutoRefreshTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _loadData(showLoading: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _syncAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (!widget.isActive) return;
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (mounted && widget.isActive) {
        _loadData(showLoading: false);
      }
    });
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      if (showLoading) {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final results = await Future.wait([
        TournamentService().getTournaments(),
        ProfileService().getMyProfile(),
      ]);

      if (!mounted) return;
      setState(() {
        _tournaments = results[0] as List<TournamentRecord>;
        _profile = results[1] as ProfileSummary;
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
          _isRefreshing = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<TournamentRecord> get _filteredTournaments {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<TournamentRecord> items = _tournaments;

    if (_showMyTournaments && _profile != null) {
      final userId = _profile!.id;
      switch (_myTournamentTab) {
        case _MyTournamentTab.registered:
          items =
              items.where((item) => item.registrationUserIds.contains(userId));
          break;
        case _MyTournamentTab.created:
          items = items.where(
            (item) => item.createdById == userId && item.status != 'DRAFT',
          );
          break;
        case _MyTournamentTab.draft:
          items = items.where(
            (item) => item.createdById == userId && item.status == 'DRAFT',
          );
          break;
      }
    } else {
      items = items.where((item) => item.status != 'DRAFT');
      if (_profile != null) {
        final userId = _profile!.id;
        items = items.where((item) => item.createdById != userId);
      }
    }

    if (query.isNotEmpty) {
      items = items.where(
        (item) =>
            item.title.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query),
      );
    }

    return items.toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
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
          onPressed: widget.onBackTap ?? () => Navigator.of(context).pop(),
        ),
        titleSpacing: -4,
        title: Row(
          children: [
            Image.asset(
              'assets/images/pgoIconoAPP.png',
              height: 56,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: const [
          PgoOptionsMenuButton(),
        ],
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.SecondBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Text(
                                    'Torneos',
                                    style: PgoTextStyles.screenTitle()
                                        .copyWith(fontSize: 30),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildSearchField(),
                            const SizedBox(height: 10),
                            _buildTabs(),
                            if (_showMyTournaments) ...[
                              const SizedBox(height: 10),
                              _buildMyTournamentTabs(),
                            ],
                            const SizedBox(height: 14),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 42),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              )
                            else if (_error != null)
                              _StatusCard(
                                title: 'No pudimos cargar los torneos',
                                message: _error!,
                                actionLabel: 'Reintentar',
                                onTap: _loadData,
                              )
                            else if (_filteredTournaments.isEmpty)
                              _StatusCard(
                                title: _showMyTournaments
                                    ? _emptyMyTournamentsTitle
                                    : 'Aún no hay torneos disponibles',
                                message: _searchController.text.trim().isEmpty
                                    ? 'Cuando crees o publiques torneos aparecerán aquí.'
                                    : 'No encontramos torneos con ese criterio.',
                              )
                            else
                              Column(
                                children: _filteredTournaments
                                    .map(
                                      (tournament) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 18),
                                        child: _TournamentCard(
                                          tournament: tournament,
                                          isRegistered: _showMyTournaments &&
                                              _myTournamentTab ==
                                                  _MyTournamentTab.registered,
                                          isCreated: _showMyTournaments &&
                                              _myTournamentTab ==
                                                  _MyTournamentTab.created,
                                          isDraft: _showMyTournaments &&
                                              _myTournamentTab ==
                                                  _MyTournamentTab.draft,
                                          onTap: () {
                                            final route = _showMyTournaments &&
                                                    _myTournamentTab ==
                                                        _MyTournamentTab.draft
                                                ? MaterialPageRoute(
                                                    builder: (context) =>
                                                        TournamentCreateFlowScreen(
                                                      initialTournament:
                                                          tournament,
                                                    ),
                                                  )
                                                : _showMyTournaments &&
                                                        _myTournamentTab ==
                                                            _MyTournamentTab
                                                                .created
                                                    ? MaterialPageRoute(
                                                        builder: (context) =>
                                                            TournamentAdminScreen(
                                                          tournament:
                                                              tournament,
                                                        ),
                                                      )
                                                    : MaterialPageRoute(
                                                        builder: (context) =>
                                                            TournamentDescriptionScreen(
                                                          tournament:
                                                              tournament,
                                                        ),
                                                      );
                                            Navigator.of(context)
                                                .push(route)
                                                .then((_) => _loadData());
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      bottom: 22,
                      child: _CreateTournamentFab(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TournamentCreateFlowScreen(),
                            ),
                          );
                          if (!mounted) return;
                          _loadData();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showBottomNav)
                widget.bottomNavigationBar ??
                    PgoBottomNav(
                      currentTab: PgoNavTab.tournaments,
                      onHomeTap:
                          widget.onHomeTap ?? () => Navigator.of(context).pop(),
                      onTournamentsTap: () {},
                      onProfileTap: widget.onProfileTap ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 17,
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Nombre del torneo',
                  hintStyle: PgoTextStyles.bodyLarge(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Center(
      child: Container(
        width: 238,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E8EE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showMyTournaments = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: !_showMyTournaments
                        ? AppColors.SecondBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Disponibles',
                    style: PgoTextStyles.tabLabel(
                      color: !_showMyTournaments
                          ? Colors.white
                          : AppColors.SecondBlue.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showMyTournaments = true;
                    _myTournamentTab = _MyTournamentTab.registered;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _showMyTournaments
                        ? AppColors.SecondBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Mis torneos',
                    style: PgoTextStyles.tabLabel(
                      color: _showMyTournaments
                          ? Colors.white
                          : AppColors.SecondBlue.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _emptyMyTournamentsTitle {
    switch (_myTournamentTab) {
      case _MyTournamentTab.registered:
        return 'Aún no estás inscrito en torneos';
      case _MyTournamentTab.created:
        return 'Aún no tienes torneos creados';
      case _MyTournamentTab.draft:
        return 'Aún no tienes borradores';
    }
  }

  Widget _buildMyTournamentTabs() {
    return Center(
      child: Container(
        width: 248,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E8EE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _MyTournamentTabButton(
                label: 'Inscrito',
                selected: _myTournamentTab == _MyTournamentTab.registered,
                onTap: () {
                  setState(() {
                    _myTournamentTab = _MyTournamentTab.registered;
                  });
                },
              ),
            ),
            Expanded(
              child: _MyTournamentTabButton(
                label: 'Creados',
                selected: _myTournamentTab == _MyTournamentTab.created,
                onTap: () {
                  setState(() {
                    _myTournamentTab = _MyTournamentTab.created;
                  });
                },
              ),
            ),
            Expanded(
              child: _MyTournamentTabButton(
                label: 'Borradores',
                selected: _myTournamentTab == _MyTournamentTab.draft,
                onTap: () {
                  setState(() {
                    _myTournamentTab = _MyTournamentTab.draft;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MyTournamentTab {
  registered,
  created,
  draft,
}

class _MyTournamentTabButton extends StatelessWidget {
  const _MyTournamentTabButton({
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
        decoration: BoxDecoration(
          gradient: selected ? AppColors.secondaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: PgoTextStyles.filterLabel(
            color: selected
                ? Colors.white
                : AppColors.SecondBlue.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _CreateTournamentFab extends StatelessWidget {
  const _CreateTournamentFab({
    required this.onTap,
  });

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
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.SecondBlue,
          size: 34,
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onTap,
    this.isRegistered = false,
    this.isCreated = false,
    this.isDraft = false,
  });

  final TournamentRecord tournament;
  final VoidCallback onTap;
  final bool isRegistered;
  final bool isCreated;
  final bool isDraft;

  String get _displayTitle => tournament.title
      .replaceFirst(RegExp(r'^\[DEMO\]\s*', caseSensitive: false), '');

  String get _formattedDate {
    const weekDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
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

    final date = tournament.startsAt.toLocal();
    final weekday = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month';
  }

  String get _badgeText {
    if (TournamentRules.isFull(tournament)) {
      return 'cupos completos';
    }

    final soloCount = tournament.soloRegistrationsCount;
    if (soloCount > 0) {
      return '$soloCount buscando dupla';
    }

    return TournamentRules.statusLabel(tournament);
  }

  bool get _isFull => TournamentRules.isFull(tournament);

  @override
  Widget build(BuildContext context) {
    if (isRegistered) return _buildRegisteredCard();
    if (isCreated) return _buildCreatedCard();
    if (isDraft) return _buildDraftCard();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 152,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 145,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TournamentCardImage(photoUrl: tournament.photoUrl),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x0D132033),
                          Color(0x1A132033),
                          Color(0xAA132033),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.PrimaryGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tournament.category.toUpperCase(),
                            style: PgoTextStyles.chip().copyWith(fontSize: 10),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFull ? Icons.lock_outline : Icons.whatshot,
                                size: 12,
                                color: _isFull
                                    ? const Color(0xFFC13A3A)
                                    : AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _badgeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PgoTextStyles.chip()
                                      .copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayTitle.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PgoTextStyles.cardTitle(
                              color: AppColors.SecondBlue,
                            ).copyWith(fontSize: 16, height: 1.0),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: AppColors.SecondBlue.withValues(
                                    alpha: 0.72),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '$_formattedDate · $_formattedTime',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PgoTextStyles.cardDetail(
                                    color: AppColors.SecondBlue.withValues(
                                        alpha: 0.82),
                                    weight: FontWeight.w600,
                                  ).copyWith(fontSize: 10.5, height: 1.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 11,
                                color: AppColors.SecondBlue.withValues(
                                    alpha: 0.72),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  tournament.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PgoTextStyles.cardDetail(
                                    color: AppColors.SecondBlue.withValues(
                                        alpha: 0.82),
                                    weight: FontWeight.w600,
                                  ).copyWith(fontSize: 10.5, height: 1.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 1,
                            color: AppColors.SecondBlue.withValues(alpha: 0.12),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _TournamentStatCell(
                                icon: Icons.groups_outlined,
                                value: tournament.format,
                                label: tournament.modality,
                              ),
                              _TournamentStatCell(
                                icon: Icons.groups_outlined,
                                value: '${tournament.playerCapacity}',
                                label: 'Cupos',
                              ),
                              const _TournamentStatCell(
                                icon: Icons.schedule_outlined,
                                value: '2h',
                                label: 'Duración',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 25,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.PrimaryGreen,
                          foregroundColor: AppColors.SecondBlue,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ver torneo',
                              style: PgoTextStyles.buttonSecondary(
                                weight: FontWeight.w900,
                              ).copyWith(fontSize: 10.5),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, size: 15),
                            const SizedBox(width: 6),
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
    );
  }

  Widget _buildRegisteredCard() {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _TournamentCardImage(photoUrl: tournament.photoUrl),
                    Padding(
                      padding: const EdgeInsets.all(7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.PrimaryGreen,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tournament.category.toUpperCase(),
                              style:
                                  PgoTextStyles.chip().copyWith(fontSize: 10),
                            ),
                          ),
                          const Spacer(),
                          _StatusBadge(
                            icon: Icons.whatshot,
                            label: _badgeText,
                            color: AppColors.primaryOrange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 8, 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayTitle.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: PgoTextStyles.cardTitle(
                                color: AppColors.SecondBlue,
                              ).copyWith(fontSize: 16, height: 1.0),
                            ),
                            const SizedBox(height: 6),
                            _InfoLine(
                              icon: Icons.calendar_today_outlined,
                              text: _formattedDate,
                            ),
                            const SizedBox(height: 4),
                            _InfoLine(
                              icon: Icons.schedule_outlined,
                              text: _formattedTime,
                            ),
                            const SizedBox(height: 4),
                            _InfoLine(
                              icon: Icons.place_outlined,
                              text: tournament.location,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const _StatusBadge(
                            icon: Icons.check_circle_outline,
                            label: 'Inscrito',
                            color: Color(0xFF45A832),
                            fill: Color(0xFFE8F8E5),
                          ),
                          const SizedBox(height: 9),
                          SizedBox(
                            width: 62,
                            height: 29,
                            child: OutlinedButton(
                              onPressed: onTap,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.SecondBlue,
                                side: BorderSide(
                                  color: AppColors.SecondBlue.withValues(
                                      alpha: 0.28),
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Ver',
                                    style: PgoTextStyles.buttonSecondary()
                                        .copyWith(fontSize: 10),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 1,
                    color: AppColors.SecondBlue.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _RegisteredStatCell(
                        icon: Icons.groups_outlined,
                        value: tournament.format,
                        label: tournament.modality,
                      ),
                      const _StatDivider(),
                      _RegisteredStatCell(
                        icon: Icons.person_add_alt_1_outlined,
                        value: '${tournament.playerCapacity}',
                        label: 'Cupos',
                      ),
                      const _StatDivider(),
                      const _RegisteredStatCell(
                        icon: Icons.calendar_month_outlined,
                        value: 'Hoy',
                        label: '',
                        color: Color(0xFF67B83F),
                      ),
                      const _StatDivider(),
                      _RegisteredStatCell(
                        icon: Icons.whatshot,
                        value: tournament.soloRegistrationsCount > 0
                            ? 'Buscando'
                            : _badgeText,
                        label: '',
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedCard() {
    return Container(
      height: 224,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 116,
                  height: 116,
                  child: _TournamentCardImage(photoUrl: tournament.photoUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.PrimaryGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tournament.category.toUpperCase(),
                            style: PgoTextStyles.chip().copyWith(fontSize: 8),
                          ),
                        ),
                        const Spacer(),
                        const _StatusBadge(
                          icon: Icons.circle,
                          label: 'Publicado',
                          color: AppColors.SecondBlue,
                          fill: AppColors.PrimaryGreen,
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.SecondBlue.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _displayTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PgoTextStyles.cardTitle(
                        color: AppColors.SecondBlue,
                      ).copyWith(fontSize: 16, height: 1),
                    ),
                    const SizedBox(height: 9),
                    _InfoLine(
                      icon: Icons.calendar_today_outlined,
                      text: '$_formattedDate, $_formattedTime',
                    ),
                    const SizedBox(height: 5),
                    _InfoLine(
                      icon: Icons.place_outlined,
                      text: tournament.location,
                    ),
                    const SizedBox(height: 5),
                    _InfoLine(
                      icon: Icons.sports_tennis,
                      text:
                          '${tournament.category} categoría · ${tournament.format}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 128),
            color: AppColors.SecondBlue.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _CreatedMetric(
                icon: Icons.groups_outlined,
                value:
                    '${tournament.registrationsCount}/${tournament.playerCapacity}',
                label: 'inscritos',
              ),
              const _StatDivider(),
              _CreatedMetric(
                icon: Icons.whatshot,
                value: '${tournament.soloRegistrationsCount}',
                label: 'buscando dupla',
              ),
              const _StatDivider(),
              const _CreatedMetric(
                icon: Icons.calendar_today_outlined,
                value: '4',
                label: 'partidos programados',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.settings_outlined, size: 15),
                    label: Text(
                      'Gestionar',
                      style: PgoTextStyles.buttonSecondary()
                          .copyWith(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.PrimaryGreen,
                      foregroundColor: AppColors.SecondBlue,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Container(
                width: 48,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  color: AppColors.SecondBlue,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard() {
    final missing = <String>[
      if (tournament.location.trim().isEmpty) 'Falta sede',
      if (tournament.startsAt.year < 2000) 'Falta fecha',
      if (tournament.playerCapacity <= 0) 'Faltan cupos',
    ];
    final progress = missing.isEmpty ? 1.0 : 0.6;

    return Container(
      height: missing.isEmpty ? 214 : 176,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: missing.isEmpty ? 108 : 118,
              height: double.infinity,
              child: _TournamentCardImage(photoUrl: tournament.photoUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayTitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PgoTextStyles.cardTitle(
                          color: AppColors.SecondBlue,
                        ).copyWith(fontSize: 16, height: 1),
                      ),
                    ),
                    const _DraftBadge(label: 'Borrador'),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.calendar_today_outlined,
                  text: missing.contains('Falta fecha')
                      ? 'Fecha por definir'
                      : '$_formattedDate · $_formattedTime',
                ),
                const SizedBox(height: 5),
                _InfoLine(
                  icon: Icons.place_outlined,
                  text: tournament.location.trim().isEmpty
                      ? 'Sede por confirmar'
                      : tournament.location,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: AppColors.SecondBlue.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 8),
                if (missing.isEmpty)
                  Row(
                    children: [
                      _RegisteredStatCell(
                        icon: Icons.groups_outlined,
                        value: tournament.format,
                        label: tournament.modality,
                      ),
                      const _StatDivider(),
                      _RegisteredStatCell(
                        icon: Icons.groups_outlined,
                        value: '${tournament.playerCapacity}',
                        label: 'cupos',
                      ),
                      const _StatDivider(),
                      const _RegisteredStatCell(
                        icon: Icons.schedule_outlined,
                        value: 'Lista',
                        label: 'para publicar',
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: missing
                        .take(2)
                        .map((item) => _DraftMissingChip(label: item))
                        .toList(),
                  ),
                const Spacer(),
                Text(
                  'Completado ${(progress * 100).round()}%',
                  style: PgoTextStyles.caption(
                    color: AppColors.SecondBlue,
                    weight: FontWeight.w900,
                  ).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(999),
                  color: progress == 1 ? AppColors.PrimaryGreen : Colors.orange,
                  backgroundColor: AppColors.SecondBlue.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.PrimaryGreen,
                            foregroundColor: AppColors.SecondBlue,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            missing.isEmpty ? 'Continuar' : 'Continuar edición',
                            style: PgoTextStyles.buttonSecondary()
                                .copyWith(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (missing.isEmpty)
                      SizedBox(
                        width: 90,
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.rocket_launch_outlined,
                              size: 13),
                          label: Text(
                            'Publicar',
                            style: PgoTextStyles.buttonSecondary()
                                .copyWith(fontSize: 10),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.SecondBlue,
                            side: const BorderSide(
                              color: AppColors.PrimaryGreen,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 86,
                        height: 30,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.SecondBlue,
                          ),
                          child: Text(
                            'Descartar',
                            style: PgoTextStyles.caption(
                              color: AppColors.SecondBlue,
                              weight: FontWeight.w800,
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
      ),
    );
  }

  String get _formattedTime {
    final date = tournament.startsAt.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }
}

class _TournamentStatCell extends StatelessWidget {
  const _TournamentStatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: AppColors.SecondBlue.withValues(alpha: 0.84),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PgoTextStyles.title(
                      weight: FontWeight.w900,
                    ).copyWith(
                      fontSize: label.isEmpty ? 9.5 : 10,
                      height: 1.0,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PgoTextStyles.caption(
                        color: AppColors.SecondBlue.withValues(alpha: 0.72),
                        weight: FontWeight.w600,
                      ).copyWith(fontSize: 7.5, height: 1.0),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisteredStatCell extends StatelessWidget {
  const _RegisteredStatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Icon(
              icon,
              size: 13,
              color: color ?? AppColors.SecondBlue.withValues(alpha: 0.84),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PgoTextStyles.title(weight: FontWeight.w900).copyWith(
                fontSize: label.isEmpty ? 9.5 : 10.5,
                height: 1,
                color: color,
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PgoTextStyles.caption(
                  color: AppColors.SecondBlue.withValues(alpha: 0.7),
                  weight: FontWeight.w600,
                ).copyWith(fontSize: 7.5, height: 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 23,
      color: AppColors.SecondBlue.withValues(alpha: 0.1),
    );
  }
}

class _CreatedMetric extends StatelessWidget {
  const _CreatedMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 16, color: AppColors.SecondBlue),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PgoTextStyles.title(weight: FontWeight.w900)
                      .copyWith(fontSize: 14, height: 1),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PgoTextStyles.caption(
                    color: AppColors.SecondBlue.withValues(alpha: 0.75),
                    weight: FontWeight.w600,
                  ).copyWith(fontSize: 9, height: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PgoTextStyles.caption(
          color: AppColors.SecondBlue.withValues(alpha: 0.7),
          weight: FontWeight.w800,
        ).copyWith(fontSize: 9),
      ),
    );
  }
}

class _DraftMissingChip extends StatelessWidget {
  const _DraftMissingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 11, color: Colors.orange),
          const SizedBox(width: 3),
          Text(
            label,
            style: PgoTextStyles.caption(
              color: const Color(0xFFE48A00),
              weight: FontWeight.w900,
            ).copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: AppColors.SecondBlue.withValues(alpha: 0.76),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PgoTextStyles.cardDetail(
              color: AppColors.SecondBlue.withValues(alpha: 0.75),
              weight: FontWeight.w600,
            ).copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.fill,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: fill ?? Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PgoTextStyles.chip().copyWith(
                fontSize: 9,
                color: color == AppColors.primaryOrange ? null : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentCardImage extends StatelessWidget {
  const _TournamentCardImage({
    required this.photoUrl,
  });

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('http')) {
        return Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            AppAssets.defaultTournamentImage,
            fit: BoxFit.cover,
          ),
        );
      }

      final bytes = tryDecodeDataUrl(photoUrl);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }

    return Image.asset(
      AppAssets.defaultTournamentImage,
      fit: BoxFit.cover,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PgoTextStyles.title(),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: PgoTextStyles.bodySecondary(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
