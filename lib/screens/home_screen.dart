import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lima_padel_clubs.dart';
import '../models/profile_summary.dart';
import '../models/tournament_record.dart';
import '../services/profile_service.dart';
import '../services/tournament_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_options_menu.dart';
import 'activity_screen.dart';
import 'profile_history_screen.dart';
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
  bool _isUpdatingProfile = false;
  bool _hasShownProfileComplete = false;

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
      _checkProfileCompletion();
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

    return 'Estas a 1 partido de subir de categoria';
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
      _checkProfileCompletion();
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
        initial: _profile?.experienceLevel,
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
        experienceLevel: selected,
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
      });
      _checkProfileCompletion();
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
      _checkProfileCompletion();
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

  bool get _isProfileComplete {
    final profile = _profile;
    if (profile == null) return false;
    final side = profile.preferredSide?.trim() ?? '';
    final schedule = profile.experienceLevel?.trim() ?? '';
    final club = profile.preferredClub?.trim() ?? '';
    return side.isNotEmpty && schedule.isNotEmpty && club.isNotEmpty;
  }

  void _checkProfileCompletion() {
    if (!_isProfileComplete || _hasShownProfileComplete) return;
    _hasShownProfileComplete = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => const _ProfileCompleteDialog(),
      );
    });
  }

  Future<void> _openRecommendedTournament() async {
    final tournament = _recommendedTournament;
    if (tournament == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const TournamentsScreen(),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TournamentDescriptionScreen(
            tournament: tournament,
          ),
        ),
      );
    }

    if (!mounted) return;
    _loadProfile();
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
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: AppColors.SecondBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        _isProfileComplete
                            ? _buildProfileReadySection()
                            : _buildCompleteProfileSection(),
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
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _buildProfileSubtitle(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
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
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
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
                    'Progreso a ${_profile?.category ?? '4ta'} categoria',
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

  Widget _buildCompleteProfileSection() {
    final side = _profile?.preferredSide?.trim().isNotEmpty == true
        ? _profile!.preferredSide!
        : 'pendiente';
    final club = _profile?.preferredClub?.trim().isNotEmpty == true
        ? _profile!.preferredClub!
        : 'pendiente';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4E7A),
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
            value: 'pendiente',
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
        : '4ta categoria';
    final side = profile?.preferredSide?.isNotEmpty == true
        ? profile!.preferredSide!
        : 'Drive';
    final schedule = profile?.experienceLevel?.isNotEmpty == true
        ? profile!.experienceLevel!
        : 'Noche';
    final club = profile?.preferredClub?.isNotEmpty == true
        ? profile!.preferredClub!
        : 'One Padel Trigal';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4E7A),
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
            'Tu perfil esta listo',
            style: TextStyle(
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
                child: const Text(
                  'Ver torneos',
                  style: TextStyle(
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
        ClipRRect(
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
                                  (_profile?.category ?? 'Sin categoria'),
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
                                onPressed: _openRecommendedTournament,
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
                                  'Ver mas torneos',
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

class _ProfileCompleteDialog extends StatelessWidget {
  const _ProfileCompleteDialog();

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
              'Tu perfil esta listo',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ya podemos recomendarte mejores torneos y jugadores',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7FF59),
                  foregroundColor: AppColors.SecondBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
