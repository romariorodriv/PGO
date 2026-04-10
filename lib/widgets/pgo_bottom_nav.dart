import 'package:flutter/material.dart';

import '../constants/colors.dart';

enum PgoNavTab {
  home,
  tournaments,
  profile,
}

class PgoBottomNav extends StatelessWidget {
  const PgoBottomNav({
    super.key,
    required this.currentTab,
    this.onHomeTap,
    this.onTournamentsTap,
    this.onProfileTap,
  });

  final PgoNavTab currentTab;
  final VoidCallback? onHomeTap;
  final VoidCallback? onTournamentsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 18, 34, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                selected: currentTab == PgoNavTab.home,
                onTap: onHomeTap,
              ),
              _NavIcon(
                icon: Icons.workspace_premium_rounded,
                selected: currentTab == PgoNavTab.tournaments,
                onTap: onTournamentsTap,
              ),
              _NavIcon(
                icon: Icons.person_rounded,
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
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: selected ? AppColors.SecondBlue : const Color(0xFF8A93A1),
        size: 34,
      ),
    );
  }
}
