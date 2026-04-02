import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'main_shell.dart';
import 'profile_history_screen.dart';

class ProfilePublicPreviewScreen extends StatelessWidget {
  const ProfilePublicPreviewScreen({
    super.key,
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final history = _buildHistoryItems(profile);

    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Perfil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: const [PgoOptionsMenuButton()],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Column(
            children: [
              _PreviewHeroCard(profile: profile),
              const SizedBox(height: 16),
              _PreviewHistoryCard(history: history),
              const SizedBox(height: 16),
              _ProfileMetaCard(profile: profile),
              const SizedBox(height: 16),
              _PreviewFriendsCard(profile: profile),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PgoBottomNav(
        currentTab: PgoNavTab.profile,
        onHomeTap: () =>
            MainShell.openReplacement(context, initialTab: PgoNavTab.home),
        onTournamentsTap: () =>
            MainShell.openReplacement(context, initialTab: PgoNavTab.tournaments),
        onProfileTap: () {},
      ),
    );
  }
}

class _PreviewHeroCard extends StatelessWidget {
  const _PreviewHeroCard({
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _PreviewAvatar(photoUrl: profile.photoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.category ?? 'Sin categoria',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      profile.preferredClub ?? 'Sin club favorito',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.45),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Invitar a jugar',
                  filled: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Seguir',
                  filled: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatsStrip(profile: profile),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 24,
                      color: AppColors.SecondBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${profile.rankingPosition}',
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  profile.category ?? 'Sin categoria',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.56),
                    fontSize: 10,
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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

class _PreviewHistoryCard extends StatelessWidget {
  const _PreviewHistoryCard({
    required this.history,
  });

  final List<_PreviewHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    final hasHistory = history.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 8),
          if (hasHistory)
            ...history.take(3).map(
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
                              const SizedBox(height: 1),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: AppColors.SecondBlue.withValues(
                                    alpha: 0.48,
                                  ),
                                  fontSize: 9,
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
                )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Aun no hay partidos registrados para mostrar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.58),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileHistoryScreen(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7FF59),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver historial completo',
                      style: TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.SecondBlue,
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

class _ProfileMetaCard extends StatelessWidget {
  const _ProfileMetaCard({
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Lado: ${profile.preferredSide ?? 'Sin definir'}', Icons.sports_tennis),
      ('Pala: ${profile.racketModel ?? 'Sin definir'}', Icons.album_rounded),
      ('Club: ${profile.preferredClub ?? 'Sin club'}', Icons.location_on),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: items.asMap().entries.expand((entry) sync* {
          yield Expanded(
            child: Column(
              children: [
                Text(
                  entry.value.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  entry.value.$2,
                  size: 30,
                  color: AppColors.SecondBlue,
                ),
              ],
            ),
          );
          if (entry.key != items.length - 1) {
            yield Container(
              width: 1,
              height: 54,
              color: const Color(0xFFD6DAE2),
            );
          }
        }).toList(),
      ),
    );
  }
}

class _PreviewFriendsCard extends StatelessWidget {
  const _PreviewFriendsCard({
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
      decoration: _cardDecoration(),
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
                      _iconForFriendHint(text),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filled ? const Color(0xFFD7FF59) : const Color(0xFFE9EBEF),
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({
    required this.photoUrl,
  });

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasRemotePhoto = photoUrl != null &&
        photoUrl!.startsWith('http') &&
        photoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD4F34E),
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: const Color(0xFFE8EAEE),
        backgroundImage: hasRemotePhoto ? NetworkImage(photoUrl!) : null,
        child: hasRemotePhoto
            ? null
            : Icon(
                Icons.person,
                size: 30,
                color: AppColors.SecondBlue.withValues(alpha: 0.72),
              ),
      ),
    );
  }
}

class _PreviewHistoryItem {
  const _PreviewHistoryItem({
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

List<_PreviewHistoryItem> _buildHistoryItems(ProfileSummary profile) {
  if (profile.matchHistory.isEmpty) {
    return const [];
  }

  return profile.matchHistory.take(3).map((item) {
    final title = item['title'] as String? ?? 'Partido reciente';
    final subtitle =
        item['subtitle'] as String? ?? item['clubName'] as String? ?? '';
    final xp = (item['xpDelta'] as num?)?.toInt() ?? 0;
    final result = item['result'] as String? ?? 'PENDING';

    return _PreviewHistoryItem(
      title: title,
      subtitle: subtitle,
      xp: xp.abs(),
      isWin: result == 'WIN',
    );
  }).toList();
}

IconData _iconForFriendHint(String text) {
  if (text.contains('comun')) {
    return Icons.group;
  }
  if (text.contains('jugado')) {
    return Icons.sports_tennis;
  }
  return Icons.emoji_events;
}

BoxDecoration _cardDecoration() {
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
