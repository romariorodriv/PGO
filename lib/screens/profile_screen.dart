import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_options_menu.dart';
import '../widgets/pgo_header_scaffold.dart';
import 'profile_edit_screen.dart';
import 'profile_history_screen.dart';
import 'profile_public_preview_screen.dart';
import 'tournaments_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.bottomNavigationBar,
    this.onBackTap,
    this.onHomeTap,
    this.onTournamentsTap,
  });

  final bool showBottomNav;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTournamentsTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileSummary? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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
    final profile = _profile;

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: widget.onBackTap ?? () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Perfil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: const [
        PgoOptionsMenuButton(),
      ],
      body: Container(
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
                        message: 'No se encontro informacion del perfil.',
                        onRetry: _loadProfile,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
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
                                    builder: (context) => ProfileEditScreen(
                                      profile: profile,
                                    ),
                                  ),
                                );

                                if (updatedProfile != null && mounted) {
                                  setState(() {
                                    _profile = updatedProfile;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            StatsStrip(profile: profile),
                            const SizedBox(height: 16),
                            RecentHistoryCard(
                              history: buildHistoryItems(profile),
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
                            FriendsCard(profile: profile),
                          ],
                        ),
                      ),
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
    final progress = buildXpProgress(profile);
    final remainingXp = ((1 - progress) * 365).round().clamp(18, 180);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
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
              const Spacer(),
              GestureDetector(
                onTap: () => _showProfileQr(context),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 10),
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
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: ProfileAvatar(
              photoUrl: profile.photoUrl,
              radius: 40,
            ),
          ),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.category ?? '4ta categoria',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.66),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFD9DDE3)),
          const SizedBox(height: 10),
          Text(
            '${profile.experiencePoints} XP',
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Te faltan $remainingXp pts para subir a 3ra',
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
              Expanded(
                child: PillInfo(
                  leading: '🔥',
                  text: '+${profile.weeklyStreak * 30 + 30} XP esta semana',
                  accent: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillInfo(
                  leading: null,
                  text: 'Ranking: #${profile.rankingPosition}',
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
    final qrValue = profile.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
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
                const Text(
                  'Mi QR de jugador',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compártelo para que te agreguen rápido a un match o torneo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.62),
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
                    size: 220,
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
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $qrValue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.52),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
      ('${profile.weeklyStreak}', 'Racha'),
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

class RecentHistoryCard extends StatelessWidget {
  const RecentHistoryCard({
    super.key,
    required this.history,
    required this.onViewAll,
  });

  final List<HistoryItemData> history;
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
              style: TextStyle(
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
              'Aun no tienes historial reciente.',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Registra partidos para ver tu actividad aqui.',
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
            ...history.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                  ],
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

class FriendsCard extends StatelessWidget {
  const FriendsCard({
    super.key,
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      '${(profile.friendsCount / 3).round().clamp(2, 8)} amigos en comun',
      'Ya han jugado antes',
      '${profile.socialNotificationsCount.clamp(1, 5)} torneos este mes',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: profileCardDecoration(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconForFriendHint(text),
                      size: 14,
                      color: AppColors.SecondBlue.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.58),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.radius,
  });

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasRemotePhoto = photoUrl != null &&
        photoUrl!.startsWith('http') &&
        photoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD4F34E),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE8EAEE),
        backgroundImage: hasRemotePhoto ? NetworkImage(photoUrl!) : null,
        child: hasRemotePhoto
            ? null
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

class HistoryItemData {
  const HistoryItemData({
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.isWin,
  });

  final String title;
  final String subtitle;
  final int xp;
  final bool isWin;
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
    final result = item['result'] as String? ?? 'PENDING';
    final isWin = result == 'WIN';

    return HistoryItemData(
      title: title,
      subtitle: subtitle,
      xp: xp.abs(),
      isWin: isWin,
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

String mapPreferredSide(String? experienceLevel) {
  switch (experienceLevel?.toUpperCase()) {
    case 'ADVANCED':
      return 'Reves';
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
