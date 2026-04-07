import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
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
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onProfileTap;

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<TournamentRecord> _tournaments = const [];
  ProfileSummary? _profile;
  bool _showMyTournaments = false;
  _MyTournamentTab _myTournamentTab = _MyTournamentTab.registered;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
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
          items = items.where((item) => item.registrationUserIds.contains(userId));
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
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBackTap ?? () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/pgoIconoAPP.png',
            height: 62,
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
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Torneos',
                                    style: TextStyle(
                                      color: AppColors.SecondBlue,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              _RefreshButton(
                                isLoading: _isLoading,
                                onTap: _isLoading ? null : _loadData,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildSearchField(),
                          const SizedBox(height: 14),
                          _buildTabs(),
                          if (_showMyTournaments) ...[
                            const SizedBox(height: 10),
                            _buildMyTournamentTabs(),
                          ],
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 42),
                              child: Center(child: CircularProgressIndicator()),
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
                                  : 'Aun no hay torneos disponibles',
                              message: _searchController.text.trim().isEmpty
                                  ? 'Cuando crees o publiques torneos apareceran aqui.'
                                  : 'No encontramos torneos con ese criterio.',
                              actionLabel: 'Actualizar',
                              onTap: _loadData,
                            )
                          else
                            Column(
                              children: _filteredTournaments
                                  .map(
                                    (tournament) => Padding(
                                      padding: const EdgeInsets.only(bottom: 18),
                                      child: _TournamentCard(
                                        tournament: tournament,
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
                                                        tournament: tournament,
                                                      ),
                                                    )
                                              : MaterialPageRoute(
                                                  builder: (context) =>
                                                      TournamentDescriptionScreen(
                                                    tournament: tournament,
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
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 18,
            color: AppColors.SecondBlue.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Nombre del torneo',
                hintStyle: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.72),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Center(
      child: Container(
        width: 224,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE4E8EE),
          borderRadius: BorderRadius.circular(19),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Disponibles',
                    style: TextStyle(
                      color: !_showMyTournaments
                          ? Colors.white
                          : AppColors.SecondBlue.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Mis torneos',
                    style: TextStyle(
                      color: _showMyTournaments
                          ? Colors.white
                          : AppColors.SecondBlue.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
        return 'Aun no estas inscrito en torneos';
      case _MyTournamentTab.created:
        return 'Aun no tienes torneos creados';
      case _MyTournamentTab.draft:
        return 'Aun no tienes borradores';
    }
  }

  Widget _buildMyTournamentTabs() {
    return Center(
      child: Container(
        width: 240,
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
          color: selected ? AppColors.SecondBlue : Colors.transparent,
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!.call(),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.SecondBlue.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: AppColors.SecondBlue,
                ),
              const SizedBox(width: 6),
              Text(
                'Actualizar',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(
                    alpha: onTap == null ? 0.5 : 1,
                  ),
                  fontSize: 12,
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

class _CreateTournamentFab extends StatelessWidget {
  const _CreateTournamentFab({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFD7FF59),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.SecondBlue,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({
    required this.tournament,
    required this.onTap,
  });

  final TournamentRecord tournament;
  final VoidCallback onTap;

  String get _formattedDate {
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

    final date = tournament.startsAt.toLocal();
    final weekday = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday ${date.day} $month';
  }

  String get _badgeText {
    switch (tournament.status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _TournamentCardImage(photoUrl: tournament.photoUrl),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 76,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x1A132033),
                            Color(0xA6132033),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.whatshot,
                                  size: 12,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _badgeText,
                                  style: const TextStyle(
                                    color: AppColors.SecondBlue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7FF59),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tournament.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tournament.title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.location,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'VER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
            'assets/images/trigal_onepadel.png',
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
      'assets/images/trigal_onepadel.png',
      fit: BoxFit.cover,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onTap;

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
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
