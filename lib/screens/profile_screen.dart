import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/community_user.dart';
import '../models/friend_request.dart';
import '../models/profile_summary.dart';
import '../models/selected_player.dart';
import '../services/community_service.dart';
import '../services/match_service.dart';
import '../services/profile_service.dart';
import '../services/social_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_options_menu.dart';
import '../widgets/pgo_header_scaffold.dart';
import 'match_summary_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_history_screen.dart';
import 'profile_public_preview_screen.dart';
import 'qr_scanner_screen.dart';
import 'tournaments_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.bottomNavigationBar,
    this.onBackTap,
    this.onHomeTap,
    this.onTournamentsTap,
    this.openFriendsOnStart = false,
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTournamentsTap;
  final bool openFriendsOnStart;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileSummary? _profile;
  bool _isLoading = true;
  bool _isOpeningMatchSummary = false;
  bool _didOpenFriendsOnStart = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = _profile == null;
      });
    }

    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _error = null;
      });
      if (widget.openFriendsOnStart && !_didOpenFriendsOnStart) {
        _didOpenFriendsOnStart = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _profile != null) {
            _openFriendsSheet(_profile!);
          }
        });
      }
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

  Future<void> _openMatchSummary(HistoryItemData item) async {
    if (_isOpeningMatchSummary) return;

    setState(() {
      _isOpeningMatchSummary = true;
    });

    _MatchSummaryData? summaryData;

    try {
      final matchId = item.raw['id'] as String?;
      if (matchId != null && matchId.isNotEmpty) {
        final matches = await MatchService().getMyMatches();
        final fullMatch = matches.cast<MatchRecord?>().firstWhere(
              (match) => match?.id == matchId,
              orElse: () => null,
            );

        if (fullMatch != null) {
          summaryData = _buildMatchSummaryDataFromRecord(fullMatch);
        }
      }
    } catch (_) {
      summaryData = null;
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningMatchSummary = false;
        });
      }
    }

    summaryData ??= _buildMatchSummaryData(item.raw);

    if (summaryData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay suficiente información para abrir el resumen.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final data = summaryData;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          matchDate: _formatHistoryDate(data.match.playedAt),
          match: data.match,
          players: data.players,
          winnerTeam: data.match.winnerTeam ?? 1,
        ),
      ),
    );
  }

  void _openFriendsSheet(ProfileSummary profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FriendSearchSheet(profile: profile),
    ).whenComplete(_loadProfile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
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
        title: Text(
          'Perfil',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          PgoOptionsMenuButton(
            notificationCount: profile?.socialNotificationsCount ?? 0,
            onNotificationsTap:
                profile == null ? null : () => _openFriendsSheet(profile),
          ),
        ],
        body: Column(
          children: [
            _ProfileHeaderSearchBar(
              enabled: profile != null && !_isLoading,
              onTap: profile == null ? null : () => _openFriendsSheet(profile),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ProfileErrorState(
                            message: _error!,
                            onRetry: _loadProfile,
                          )
                        : profile == null
                            ? _ProfileErrorState(
                                message:
                                    'No se encontro información del perfil.',
                                onRetry: _loadProfile,
                              )
                            : SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 24, 18, 24),
                                child: Column(
                                  children: [
                                    _ProfileHeroCard(
                                      profile: profile,
                                      onPreview: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePublicPreviewScreen(
                                              profile: profile,
                                            ),
                                          ),
                                        );
                                      },
                                      onEdit: () async {
                                        final updatedProfile =
                                            await Navigator.of(context)
                                                .push<ProfileSummary>(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileEditScreen(
                                              profile: profile,
                                            ),
                                          ),
                                        );

                                        if (updatedProfile != null && mounted) {
                                          setState(() {
                                            _profile = updatedProfile;
                                          });
                                          _loadProfile();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    StatsStrip(profile: profile),
                                    const SizedBox(height: 16),
                                    ProfilePreferencesCard(profile: profile),
                                    const SizedBox(height: 16),
                                    RecentHistoryCard(
                                      history: buildHistoryItems(profile),
                                      onHistoryTap: _openMatchSummary,
                                      onViewAll: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfileHistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    FriendsCard(
                                      profile: profile,
                                      onOpenFriends: () =>
                                          _openFriendsSheet(profile),
                                    ),
                                  ],
                                ),
                              ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.showBottomNav
            ? widget.bottomNavigationBar ??
                PgoBottomNav(
                  currentTab: PgoNavTab.profile,
                  onHomeTap:
                      widget.onHomeTap ?? () => Navigator.of(context).pop(),
                  onTournamentsTap: widget.onTournamentsTap ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TournamentsScreen(),
                          ),
                        );
                      },
                  onProfileTap: () {},
                )
            : null,
      ),
    );
  }
}

class _ProfileHeaderSearchBar extends StatelessWidget {
  const _ProfileHeaderSearchBar({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 0, 42, 12),
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 34,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: AppColors.SecondBlue.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Buscar amigos o personas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.onPreview,
    required this.onEdit,
  });

  final ProfileSummary profile;
  final VoidCallback onPreview;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final progress = xpLevelProgress(profile);
    final levelRange = xpLevelRange(profile.experiencePoints);
    final remainingXp =
        (levelRange.next - profile.experiencePoints).clamp(0, levelRange.next);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showProfileQr(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAEE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 17,
                    color: Color(0xFF7E8590),
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 11,
                            color: Color(0xFF7E8590),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Editar perfil',
                            style: TextStyle(
                              color: Color(0xFF7E8590),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: onPreview,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAEE),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.visibility_outlined,
                          size: 17,
                          color: Color(0xFF7E8590),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: ProfileAvatar(
              photoUrl: profile.photoUrl,
              radius: 40,
              experienceLevel: profile.experienceLevel,
            ),
          ),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7FF59),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.SecondBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              profile.category ?? '4ta categoría',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFD9DDE3)),
          const SizedBox(height: 10),
          Text(
            '${profile.experiencePoints} XP',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Nivel ${formatExperienceLevel(profile.experienceLevel)} - '
            '$remainingXp XP para el siguiente nivel',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.72),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE4E8EE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD5FF59),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${levelRange.current} XP',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${levelRange.next} XP',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PillInfo(
                  leading: null,
                  text: '+${profile.weeklyStreak * 30 + 30} XP esta semana',
                  accent: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillInfo(
                  leading: null,
                  text: '${profile.weeklyStreak} dias de racha',
                  accent: AppColors.SecondBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileQr(BuildContext context) {
    final qrValue = jsonEncode({
      'type': 'player',
      'id': profile.id,
      'email': profile.email,
      'name': profile.name,
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.64,
          minChildSize: 0.32,
          maxChildSize: 0.82,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final maxHeight = MediaQuery.of(context).size.height * 0.75;
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8DDE5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Mi QR de jugador',
                            style: GoogleFonts.inter(
                              color: AppColors.SecondBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Compártelo para que te agreguen rápido a un match o torneo.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.62),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE2E7EE),
                              ),
                            ),
                            child: QrImageView(
                              data: qrValue,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.SecondBlue,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.SecondBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile.name,
                            style: GoogleFonts.inter(
                              color: AppColors.SecondBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${profile.id}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.52),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class StatsStrip extends StatelessWidget {
  const StatsStrip({
    super.key,
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('${profile.matchesPlayed}', 'Partidos'),
      ('${profile.wins}', 'Victorias'),
      ('${profile.winRate.round()}%', 'Win rate'),
      ('${profile.weeklyStreak}', 'Racha Semanal'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: stats
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({
    super.key,
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Lado',
        profile.preferredSide?.trim().isNotEmpty == true
            ? profile.preferredSide!
            : mapPreferredSide(profile.experienceLevel),
        Icons.sports_tennis_rounded,
      ),
      (
        'Horario',
        mapSchedule(profile.experienceLevel),
        Icons.schedule_rounded,
      ),
      (
        'Club',
        profile.preferredClub?.trim().isNotEmpty == true
            ? profile.preferredClub!
            : 'Sin club',
        Icons.location_on_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferencias de juego',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Datos que luego podrás editar para emparejarte mejor.',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.52),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            item.$3,
                            color: AppColors.SecondBlue,
                            size: 18,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$1,
                            style: TextStyle(
                              color:
                                  AppColors.SecondBlue.withValues(alpha: 0.48),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class RecentHistoryCard extends StatelessWidget {
  const RecentHistoryCard({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onViewAll,
  });

  final List<HistoryItemData> history;
  final ValueChanged<HistoryItemData> onHistoryTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Historial reciente',
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (history.isEmpty) ...[
            const SizedBox(height: 18),
            Icon(
              Icons.history_toggle_off_rounded,
              size: 34,
              color: AppColors.SecondBlue.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 10),
            Text(
              'Aún no tienes historial reciente.',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Registra partidos para ver tu actividad aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Toca un partido para ver su resumen',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.45),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...history.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  onTap: () => onHistoryTap(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: item.isWin
                                ? AppColors.PrimaryGreen
                                : const Color(0xFFFF334B),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isWin ? Icons.check : Icons.close,
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
                                item.title,
                                style: const TextStyle(
                                  color: AppColors.SecondBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: AppColors.SecondBlue.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.isWin ? '+' : '-'}${item.xp} XP',
                          style: TextStyle(
                            color: item.isWin
                                ? AppColors.PrimaryGreen
                                : const Color(0xFFFF334B),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.SecondBlue.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7FF59),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Ver historial completo',
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
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

class _MatchSummaryData {
  const _MatchSummaryData({
    required this.match,
    required this.players,
  });

  final MatchRecord match;
  final List<SelectedPlayer> players;
}

_MatchSummaryData? _buildMatchSummaryDataFromRecord(MatchRecord match) {
  final participants = match.participants.toList()
    ..sort((a, b) => a.slot.compareTo(b.slot));

  if (participants.length < 4) {
    return null;
  }

  final players = participants.take(4).map((participant) {
    final user = participant.user;
    return SelectedPlayer(
      id: user?.id ?? participant.userId,
      name: (user?.name.trim().isNotEmpty ?? false)
          ? user!.name
          : 'Jugador ${participant.slot}',
      photoUrl: user?.photoUrl,
      category: user?.category,
      rankingPosition: 0,
    );
  }).toList();

  return _MatchSummaryData(
    match: match,
    players: players,
  );
}

_MatchSummaryData? _buildMatchSummaryData(Map<String, dynamic> item) {
  final id = item['id'] as String?;
  final participantsJson = (item['participants'] as List?) ?? const [];
  if (id == null || id.isEmpty || participantsJson.isEmpty) {
    return null;
  }

  final playedAtValue = item['playedAt'];
  final playedAt = playedAtValue is String
      ? DateTime.tryParse(playedAtValue) ?? DateTime.now()
      : playedAtValue is DateTime
          ? playedAtValue
          : DateTime.now();

  final participants = participantsJson
      .whereType<Map>()
      .map((raw) => Map<String, dynamic>.from(raw))
      .toList()
    ..sort(
      (a, b) => ((a['slot'] as num?)?.toInt() ?? 0).compareTo(
        (b['slot'] as num?)?.toInt() ?? 0,
      ),
    );

  final selectedPlayers = <SelectedPlayer>[];
  final matchParticipants = <MatchParticipantRecord>[];

  for (var index = 0; index < participants.length; index++) {
    final participant = participants[index];
    final user = participant['user'] is Map
        ? Map<String, dynamic>.from(participant['user'] as Map)
        : <String, dynamic>{};
    final profile = user['profile'] is Map
        ? Map<String, dynamic>.from(user['profile'] as Map)
        : <String, dynamic>{};
    final userId = user['id'] as String? ?? 'player-$index';
    final name = user['name'] as String? ?? 'Jugador ${index + 1}';
    final photoUrl = profile['photoUrl'] as String?;
    final category = profile['category'] as String?;
    final slot = (participant['slot'] as num?)?.toInt() ?? index + 1;
    final team = (participant['team'] as num?)?.toInt() ?? (index < 2 ? 1 : 2);

    selectedPlayers.add(
      SelectedPlayer(
        id: userId,
        name: name,
        photoUrl: photoUrl,
        category: category,
        rankingPosition: 0,
      ),
    );

    matchParticipants.add(
      MatchParticipantRecord(
        id: '$id-$userId-$slot',
        userId: userId,
        slot: slot,
        team: team,
        user: MatchParticipantUserRecord(
          id: userId,
          name: name,
          photoUrl: photoUrl,
          category: category,
        ),
      ),
    );
  }

  if (selectedPlayers.length < 4) {
    return null;
  }

  final match = MatchRecord(
    id: id,
    createdById: item['createdById'] as String? ?? '',
    clubName: item['clubName'] as String? ?? 'Club no definido',
    playedAt: playedAt,
    matchType: item['matchType'] as String? ?? 'RANKED',
    status: item['status'] as String? ?? 'COMPLETED',
    description: item['description'] as String?,
    winnerTeam: (item['winnerTeam'] as num?)?.toInt(),
    games: ((item['games'] as List?) ?? const [])
        .whereType<Map>()
        .map((game) => Map<String, dynamic>.from(game))
        .toList(),
    createdAt: playedAt,
    updatedAt: playedAt,
    photoUrl: item['photoUrl'] as String?,
    participants: matchParticipants,
  );

  return _MatchSummaryData(
    match: match,
    players: selectedPlayers,
  );
}

String _formatHistoryDate(DateTime date) {
  const weekdays = [
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
    'Domingo',
  ];
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day} de ${months[date.month - 1]}';
}

class HistoryItemData {
  const HistoryItemData({
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.isWin,
    required this.raw,
  });

  final String title;
  final String subtitle;
  final int xp;
  final bool isWin;
  final Map<String, dynamic> raw;
}

class FriendsCard extends StatelessWidget {
  const FriendsCard({
    super.key,
    required this.profile,
    required this.onOpenFriends,
  });

  final ProfileSummary profile;
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          InkWell(
            onTap: onOpenFriends,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Amigos ${profile.friendsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FriendsAvatarCarousel(
            currentUserId: profile.id,
            friendsCount: profile.friendsCount,
            onOpenFriends: onOpenFriends,
          ),
        ],
      ),
    );
  }
}

class _FriendsAvatarCarousel extends StatefulWidget {
  const _FriendsAvatarCarousel({
    required this.currentUserId,
    required this.friendsCount,
    required this.onOpenFriends,
  });

  final String currentUserId;
  final int friendsCount;
  final VoidCallback onOpenFriends;

  @override
  State<_FriendsAvatarCarousel> createState() => _FriendsAvatarCarouselState();
}

class _FriendsAvatarCarouselState extends State<_FriendsAvatarCarousel> {
  late final Future<List<CommunityUser>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = ProfileService().getMyFriends();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CommunityUser>>(
      future: _friendsFuture,
      builder: (context, snapshot) {
        final users = (snapshot.data ?? const <CommunityUser>[])
            .where((user) => user.id != widget.currentUserId)
            .toList();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 58,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (users.isEmpty) {
          return InkWell(
            onTap: widget.onOpenFriends,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  widget.friendsCount > 0
                      ? 'Tus amigos aparecerán aquí al sincronizar la lista'
                      : 'Aún no tienes amigos agregados',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return _FriendAvatarBubble(
                user: user,
                onTap: widget.onOpenFriends,
              );
            },
          ),
        );
      },
    );
  }
}

class _FriendAvatarBubble extends StatelessWidget {
  const _FriendAvatarBubble({
    required this.user,
    required this.onTap,
  });

  final CommunityUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoUrl != null &&
        user.photoUrl!.startsWith('http') &&
        user.photoUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFD7FF59),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE8EAEE),
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: AppColors.SecondBlue,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _firstName(user.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.68),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Jugador';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _FriendSearchSheet extends StatefulWidget {
  const _FriendSearchSheet({
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  State<_FriendSearchSheet> createState() => _FriendSearchSheetState();
}

class _FriendSearchSheetState extends State<_FriendSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final SocialService _socialService = SocialService();
  List<CommunityUser> _users = const [];
  FriendRequestsResponse? _requests;
  final Set<String> _busyUserIds = <String>{};
  final Set<String> _busyRequestIds = <String>{};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await _communityService.getSuggestions();
      if (!mounted) return;
      setState(() {
        _users = suggestions
            .where((user) => user.id != widget.profile.id)
            .take(8)
            .toList();
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

  Future<void> _loadRequests() async {
    try {
      final requests = await _socialService.getFriendRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requests = const FriendRequestsResponse(
          incoming: [],
          outgoing: [],
        );
      });
    }
  }

  Future<void> _search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      _loadSuggestions();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _communityService.searchCommunity(normalized);
      if (!mounted) return;
      setState(() {
        _users = results
            .where((user) => user.id != widget.profile.id)
            .take(12)
            .toList();
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

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (code == null || code.trim().isEmpty || !mounted) return;
    final query = _extractQrQuery(code);
    _searchController.text = query;
    _search(query);
  }

  String _extractQrQuery(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return (decoded['email'] as String?) ??
            (decoded['name'] as String?) ??
            (decoded['id'] as String?) ??
            value;
      }
    } catch (_) {
      return value;
    }
    return value;
  }

  void _openProfile(CommunityUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfilePublicPreviewScreen(
          profile: ProfileSummary(
            id: user.id,
            name: user.name,
            email: user.email ?? '',
            photoUrl: user.photoUrl,
            experiencePoints: 0,
            category: user.category,
            preferredClub: user.preferredClub,
            preferredSide: null,
            racketModel: null,
            experienceLevel: null,
            rankingPosition: user.rankingPosition,
            matchesPlayed: 0,
            wins: 0,
            winRate: 0,
            weeklyStreak: 0,
            friendsCount: 0,
            followersCount: 0,
            followingCount: 0,
            socialNotificationsCount: 0,
            matchHistory: const [],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFriendAction(CommunityUser user) async {
    if (_busyUserIds.contains(user.id)) return;

    setState(() {
      _busyUserIds.add(user.id);
    });

    try {
      final status = user.friendshipStatus?.toUpperCase();
      if (status == 'ACCEPTED') {
        await _socialService.removeFriend(user.id);
        _showSnack('Amigo eliminado');
      } else {
        final connection = await _socialService.requestFriend(user.id);
        _showSnack(
          connection.status.toUpperCase() == 'ACCEPTED'
              ? 'Ahora son amigos'
              : 'Solicitud enviada',
        );
      }

      await Future.wait([
        _searchController.text.trim().isEmpty
            ? _loadSuggestions()
            : _search(_searchController.text),
        _loadRequests(),
      ]);
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _busyUserIds.remove(user.id);
        });
      }
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    await _updateRequest(
      request,
      () => _socialService.acceptRequest(request.id),
      'Ahora son amigos',
    );
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    await _updateRequest(
      request,
      () => _socialService.rejectRequest(request.id),
      'Solicitud rechazada',
    );
  }

  Future<void> _updateRequest(
    FriendRequest request,
    Future<FriendRequest> Function() action,
    String successMessage,
  ) async {
    if (_busyRequestIds.contains(request.id)) return;

    setState(() {
      _busyRequestIds.add(request.id);
    });

    try {
      await action();
      _showSnack(successMessage);
      await Future.wait([
        _loadRequests(),
        _searchController.text.trim().isEmpty
            ? _loadSuggestions()
            : _search(_searchController.text),
      ]);
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _busyRequestIds.remove(request.id);
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F7),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8CED8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Amigos',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.profile.friendsCount} amigos registrados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Buscar perfil',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _scanQr,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.SecondBlue,
                      fixedSize: const Size(50, 50),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _search(_searchController.text),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('BUSCAR JUGADOR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(23),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if ((_requests?.incoming.isNotEmpty ?? false)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Solicitudes pendientes',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ..._requests!.incoming.map(
                  (request) => _FriendRequestTile(
                    request: request,
                    isBusy: _busyRequestIds.contains(request.id),
                    onAccept: () => _acceptRequest(request),
                    onReject: () => _rejectRequest(request),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _SocialEmptyState(message: _error!)
              else if (_users.isEmpty)
                const _SocialEmptyState(
                  message: 'No encontramos jugadores con esa búsqueda.',
                )
              else
                ..._users.map(
                  (user) => _FriendUserTile(
                    user: user,
                    onProfileTap: () => _openProfile(user),
                    onInviteTap: () => _showSnack('Invitacion en preparacion'),
                    onFollowTap: () => _handleFriendAction(user),
                    isBusy: _busyUserIds.contains(user.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SocialEmptyState extends StatelessWidget {
  const _SocialEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.62),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FriendUserTile extends StatelessWidget {
  const _FriendUserTile({
    required this.user,
    required this.onProfileTap,
    required this.onInviteTap,
    required this.onFollowTap,
    required this.isBusy,
  });

  final CommunityUser user;
  final VoidCallback onProfileTap;
  final VoidCallback onInviteTap;
  final VoidCallback onFollowTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoUrl != null &&
        user.photoUrl!.startsWith('http') &&
        user.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8EAEE),
              backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
              child: hasPhoto
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.SecondBlue,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.category ?? user.preferredClub ?? 'Jugador PGO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.54),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isBusy ? null : onFollowTap,
            icon: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _friendActionIcon(user.friendshipStatus),
                    size: 16,
                  ),
            label: Text(_friendActionLabel(user.friendshipStatus)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.SecondBlue,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onInviteTap,
            icon: const Icon(Icons.sports_tennis_rounded),
            color: AppColors.SecondBlue,
            tooltip: 'Invitar a jugar',
          ),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequest request;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final user = request.user;
    final hasPhoto = user.photoUrl != null &&
        user.photoUrl!.startsWith('http') &&
        user.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8EAEE),
            backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(
                    Icons.person_rounded,
                    color: AppColors.SecondBlue,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Quiere agregarte',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.52),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFFFF334B),
              tooltip: 'Rechazar',
            ),
            IconButton(
              onPressed: onAccept,
              icon: const Icon(Icons.check_rounded),
              color: AppColors.PrimaryGreen,
              tooltip: 'Aceptar',
            ),
          ],
        ],
      ),
    );
  }
}

String _friendActionLabel(String? status) {
  switch (status?.toUpperCase()) {
    case 'ACCEPTED':
      return 'Quitar';
    case 'PENDING':
      return 'Pendiente';
    case 'BLOCKED':
      return 'Bloqueado';
    default:
      return 'Agregar';
  }
}

IconData _friendActionIcon(String? status) {
  switch (status?.toUpperCase()) {
    case 'ACCEPTED':
      return Icons.person_remove_alt_1_rounded;
    case 'PENDING':
      return Icons.schedule_rounded;
    case 'BLOCKED':
      return Icons.block_rounded;
    default:
      return Icons.person_add_alt_1_rounded;
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.radius,
    this.experienceLevel,
  });

  final String? photoUrl;
  final double radius;
  final String? experienceLevel;

  @override
  Widget build(BuildContext context) {
    final hasRemotePhoto = photoUrl != null &&
        photoUrl!.startsWith('http') &&
        photoUrl!.isNotEmpty;
    final bytes = tryDecodeDataUrl(photoUrl);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: avatarBorderColors(experienceLevel),
        ),
        boxShadow: [
          BoxShadow(
            color: avatarBorderColors(experienceLevel).last.withValues(
                  alpha: 0.26,
                ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        key: ValueKey(photoUrl ?? 'empty-photo'),
        radius: radius,
        backgroundColor: const Color(0xFFE8EAEE),
        backgroundImage: hasRemotePhoto ? NetworkImage(photoUrl!) : null,
        child: hasRemotePhoto
            ? null
            : bytes != null
                ? ClipOval(
                    child: Image.memory(
                      bytes,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: radius,
                    color: AppColors.SecondBlue.withValues(alpha: 0.75),
                  ),
      ),
    );
  }
}

class PillInfo extends StatelessWidget {
  const PillInfo({
    super.key,
    required this.leading,
    required this.text,
    required this.accent,
  });

  final String? leading;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            Text(leading!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
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
              Icons.person_off_rounded,
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

List<HistoryItemData> buildHistoryItems(ProfileSummary profile) {
  if (profile.matchHistory.isEmpty) {
    return const [];
  }

  return profile.matchHistory.take(3).toList().asMap().entries.map((entry) {
    final item = entry.value;
    final title = item['title'] as String? ?? 'Partido reciente';
    final subtitle =
        item['subtitle'] as String? ?? item['clubName'] as String? ?? '';
    final xp = (item['xpDelta'] as num?)?.toInt() ?? 0;
    final result = (item['result'] as String? ?? 'PENDING').toUpperCase();
    final isWin = result == 'WIN';

    return HistoryItemData(
      title: title,
      subtitle: subtitle,
      xp: xp.abs(),
      isWin: isWin,
      raw: item,
    );
  }).toList();
}

double buildXpProgress(ProfileSummary profile) {
  if (profile.experiencePoints <= 0) {
    return 0.22;
  }

  final normalized = profile.experiencePoints / 1200;
  return normalized.clamp(0.18, 0.96);
}

({int current, int next}) xpLevelRange(int xp) {
  if (xp < 300) {
    return (current: 0, next: 300);
  }
  if (xp < 700) {
    return (current: 300, next: 700);
  }
  if (xp < 1200) {
    return (current: 700, next: 1200);
  }
  if (xp < 2000) {
    return (current: 1200, next: 2000);
  }
  return (current: 2000, next: 3200);
}

double xpLevelProgress(ProfileSummary profile) {
  final range = xpLevelRange(profile.experiencePoints);
  final span = range.next - range.current;
  if (span <= 0) return 1;
  return ((profile.experiencePoints - range.current) / span).clamp(0.08, 1);
}

String formatExperienceLevel(String? value) {
  switch (value?.toUpperCase()) {
    case 'BEGINNER':
      return 'Inicial';
    case 'INTERMEDIATE':
      return 'Intermedio';
    case 'ADVANCED':
      return 'Avanzado';
    case 'PRO':
      return 'Pro';
    default:
      return 'PGO';
  }
}

List<Color> avatarBorderColors(String? experienceLevel) {
  switch (experienceLevel?.toUpperCase()) {
    case 'PRO':
      return const [Color(0xFFFFE066), Color(0xFFFF7A1A)];
    case 'ADVANCED':
      return const [Color(0xFF85F0FF), Color(0xFF315FA6)];
    case 'INTERMEDIATE':
      return const [Color(0xFFD7FF59), Color(0xFF3F6EA5)];
    case 'BEGINNER':
      return const [Color(0xFFD7FF59), Color(0xFFA8C6D8)];
    default:
      return const [Color(0xFFD4F34E), Color(0xFFD4F34E)];
  }
}

String mapPreferredSide(String? experienceLevel) {
  switch (experienceLevel?.toUpperCase()) {
    case 'ADVANCED':
      return 'Revés';
    case 'BEGINNER':
      return 'Drive';
    default:
      return 'Drive';
  }
}

String mapSchedule(String? experienceLevel) {
  switch (experienceLevel?.toUpperCase()) {
    case 'ADVANCED':
      return 'Mixto';
    case 'BEGINNER':
      return 'Tarde';
    default:
      return 'Noche';
  }
}

IconData iconForFriendHint(String text) {
  if (text.contains('comun')) {
    return Icons.group;
  }
  if (text.contains('jugado')) {
    return Icons.sports_tennis;
  }
  return Icons.emoji_events;
}

BoxDecoration profileCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
