import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'tournament_description_screen.dart';

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SecondBlue,
      appBar: AppBar(
        backgroundColor: AppColors.SecondBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/pgoIconoAPP.png',
              height: 42,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Torneos',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSearchField(),
                      const SizedBox(height: 14),
                      _buildTabs(),
                      const SizedBox(height: 16),
                      _TournamentCard(
                        title: 'TORNEO PGO',
                        level: '4TA',
                        date: 'Lunes 19 Dic',
                        club: 'One Padel Trigal',
                        badge: '1 buscando dupla',
                        imageAsset: 'assets/images/trigal_onepadel.png',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TournamentDescriptionScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _TournamentCard(
                        title: 'LOS INKAS',
                        level: '3RA',
                        date: 'Martes 27 Ene',
                        club: 'One Padel Naval',
                        badge: '3 buscando dupla',
                        imageAsset: 'assets/images/trigal_onepadel.png',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TournamentDescriptionScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _TournamentCard(
                        title: 'PRO PADEL',
                        level: '2DA',
                        date: 'Viernes 23 Ene',
                        club: 'Mad Padel Molina',
                        badge: '1 cupo disponible',
                        imageAsset: 'assets/images/trigal_onepadel.png',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TournamentDescriptionScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(context),
            ],
          ),
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
            color: AppColors.SecondBlue.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Nombre del torneo',
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.72),
              fontSize: 15,
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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.SecondBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Disponibles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Mis torneos',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.home,
                  color: Color(0xFF7D8491),
                  size: 34,
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.SecondBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.SecondBlue,
                  size: 34,
                ),
              ),
              const Icon(
                Icons.person,
                color: Color(0xFF7D8491),
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final String title;
  final String level;
  final String date;
  final String club;
  final String badge;
  final String imageAsset;
  final VoidCallback onTap;

  const _TournamentCard({
    required this.title,
    required this.level,
    required this.date,
    required this.club,
    required this.badge,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.SecondBlue.withOpacity(0.78),
                    AppColors.SecondBlue.withOpacity(0.15),
                  ],
                ),
              ),
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
                        color: Colors.white.withOpacity(0.92),
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
                            badge,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7FF59),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        color: AppColors.SecondBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
                    club,
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
