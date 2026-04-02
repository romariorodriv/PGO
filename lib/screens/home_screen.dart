import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_options_menu.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'tournament_description_screen.dart';
import 'tournaments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.showBottomNav = true,
    this.bottomNavigationBar,
    this.onTournamentsTap,
    this.onProfileTap,
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onTournamentsTap;
  final VoidCallback? onProfileTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileSummary? _profile;
  List<TournamentRecord> _tournaments = const [];
  bool _isLoadingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ProfileService().getMyProfile(),
        TournamentService().getTournaments(),
      ]);
      final profile = results[0] as ProfileSummary;
      final tournaments = results[1] as List<TournamentRecord>;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _tournaments = tournaments;
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
      }
    }
  }

  String _buildProfileSubtitle() {
    if (_isLoadingProfile) {
      return 'Cargando perfil...';
    }

    if (_profileError != null) {
      return 'No se pudo cargar tu perfil';
    }

    final profile = _profile;
    if (profile == null) {
      return 'Completa tu perfil para continuar';
    }

    final category = profile.category ?? 'Sin categoria';
    return '$category - ${profile.matchesPlayed} partidos - ${profile.wins} victorias';
  }

  String _buildGreetingName() {
    final fullName = (_profile?.name ?? 'Romario').trim();
    if (fullName.isEmpty) {
      return 'Romario';
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

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 28, 30, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        (topInset + AppColors.headerToolbarHeight) -
                        96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 46),
                      _buildWeeklySummarySection(),
                      const SizedBox(height: 18),
                      _buildSuggestionsSection(),
                      const SizedBox(height: 18),
                    ],
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
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Hola ${_buildGreetingName()},',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 39,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _buildProfileSubtitle(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.45),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: 282,
                height: 62,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ActivityScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(31),
                    ),
                  ),
                  child: const Text(
                    'REGISTRAR MATCH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
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
                    'Ranking #${_profile?.rankingPosition ?? 0}',
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildWeeklySummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen semanal',
          style: TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EBF1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/trigal_onepadel.png',
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    left: -8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${_profile?.weeklyStreak ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DayBadge(day: 'L', value: '3'),
                        _DayBadge(day: 'M', value: '15'),
                        _DayBadge(day: 'M', value: '15'),
                        _DayBadge(day: 'J', value: '16'),
                        _DayBadge(day: 'V', value: '17'),
                        _DayBadge(day: 'S', value: '18'),
                        _DayBadge(day: 'D', value: '19'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nivel actual: ${_profile?.category ?? 'Sin categoria'}',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Racha semanal: ${_profile?.weeklyStreak ?? 0}',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ranking local: #${_profile?.rankingPosition ?? 0}',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Ver historial ->',
                        style: TextStyle(
                          color: AppColors.SecondBlue.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _HomeRecommendationImage(
                  imageAsset: 'assets/images/trigal_onepadel.png',
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
                                  (_profile?.category ?? 'Sin categoria'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tournament?.title ?? 'Sin torneos recomendados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 118,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (tournament != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TournamentDescriptionScreen(
                                          tournament: tournament,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TournamentsScreen(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD7FF59),
                                  foregroundColor: AppColors.SecondBlue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: const Text(
                                  'Ver mas torneos',
                                  style: TextStyle(
                                    fontSize: 11,
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
                          const SizedBox(height: 8),
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
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
