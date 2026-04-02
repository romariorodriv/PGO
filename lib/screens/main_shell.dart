import 'package:flutter/material.dart';

import '../widgets/pgo_bottom_nav.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'tournaments_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = PgoNavTab.home,
  });

  final PgoNavTab initialTab;

  static Route<void> route({PgoNavTab initialTab = PgoNavTab.home}) {
    return MaterialPageRoute(
      builder: (_) => MainShell(initialTab: initialTab),
    );
  }

  static void openReplacement(
    BuildContext context, {
    PgoNavTab initialTab = PgoNavTab.home,
  }) {
    Navigator.of(context).pushAndRemoveUntil(
      route(initialTab: initialTab),
      (route) => false,
    );
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late PgoNavTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _setTab(PgoNavTab tab) {
    if (_currentTab == tab) {
      return;
    }

    setState(() {
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: IndexedStack(
        index: PgoNavTab.values.indexOf(_currentTab),
        children: [
          HomeScreen(
            showBottomNav: false,
            onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
            onProfileTap: () => _setTab(PgoNavTab.profile),
          ),
          TournamentsScreen(
            showBottomNav: false,
            onBackTap: () => _setTab(PgoNavTab.home),
            onHomeTap: () => _setTab(PgoNavTab.home),
            onProfileTap: () => _setTab(PgoNavTab.profile),
          ),
          ProfileScreen(
            showBottomNav: false,
            onBackTap: () => _setTab(PgoNavTab.home),
            onHomeTap: () => _setTab(PgoNavTab.home),
            onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
          ),
        ],
      ),
      bottomNavigationBar: PgoBottomNav(
        currentTab: _currentTab,
        onHomeTap: () => _setTab(PgoNavTab.home),
        onTournamentsTap: () => _setTab(PgoNavTab.tournaments),
        onProfileTap: () => _setTab(PgoNavTab.profile),
      ),
    );
  }
}
