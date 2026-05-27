import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

enum PgoNavTab {
  home,
  tournaments,
  alerts,
  profile,
}

class PgoBottomNav extends StatelessWidget {
  const PgoBottomNav({
    super.key,
    required this.currentTab,
    this.onHomeTap,
    this.onTournamentsTap,
    this.onAlertsTap,
    this.onProfileTap,
  });

  final PgoNavTab currentTab;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTournamentsTap;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                label: 'Inicio',
                selected: currentTab == PgoNavTab.home,
                onTap: onHomeTap,
              ),
              _NavIcon(
                icon: Icons.emoji_events,
                label: 'Torneos',
                selected: currentTab == PgoNavTab.tournaments,
                onTap: onTournamentsTap,
              ),
              _NavIcon(
                icon: Icons.sports_tennis_rounded,
                label: 'Partidos',
                selected: currentTab == PgoNavTab.alerts,
                onTap: onAlertsTap,
              ),
              _NavIcon(
                icon: Icons.person_rounded,
                label: 'Perfil',
                selected: currentTab == PgoNavTab.profile,
                onTap: onProfileTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.SecondBlue : const Color(0xFF8A93A1),
              size: 28,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                color:
                    selected ? AppColors.SecondBlue : const Color(0xFF6F7784),
                fontSize: 8,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 22 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.PrimaryGreen,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
