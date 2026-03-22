import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_description_screen.dart';
import 'tournament_live_screen.dart';

class TournamentProfileScreen extends StatelessWidget {
  const TournamentProfileScreen({Key? key}) : super(key: key);

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
        title: const Text(
          'Actividad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 14, 30, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabs(context),
                            const SizedBox(height: 16),
                            const Center(
                              child: _HeroChip(text: '3 amigos inscritos'),
                            ),
                            const SizedBox(height: 14),
                            _buildSelectedTeamCard(),
                            const SizedBox(height: 16),
                            const Text(
                              'Jugadores',
                              style: TextStyle(
                                color: AppColors.SecondBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _PlayerListTile(
                              name: 'Tom',
                              subtitle: 'Amigo',
                              score: '#110',
                            ),
                            const _PlayerDivider(),
                            const _PlayerListTile(
                              name: 'Karo',
                              score: '#105',
                              showFollow: true,
                            ),
                            const _PlayerDivider(),
                            const _PlayerListTile(
                              name: 'Mafer',
                              subtitle: 'Amiga',
                              score: '#97',
                            ),
                            const _PlayerDivider(),
                            const _PlayerListTile(
                              name: 'Paula',
                              score: '#90',
                              showFollow: true,
                            ),
                            const _PlayerDivider(),
                            const _PlayerListTile(
                              name: 'Logan',
                              subtitle: 'Amigo',
                              score: '#12',
                            ),
                            const _PlayerDivider(),
                            const _PlayerListTile(
                              name: 'Yupi',
                              score: '#89',
                              showFollow: true,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
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

  Widget _buildHero() {
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            child: Image.asset(
              'assets/images/trigal_onepadel.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.14),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Torneo PGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '4TA categoría',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TournamentDescriptionScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Descripción',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TournamentBracketScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Bracket',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const TournamentLiveScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'En vivo',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Jugadores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTeamCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const _AvatarCircle(selected: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Romario / Arom',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Arom | amigo',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '#120',
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.55),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7FF59),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '#111',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
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

class _PlayerListTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String score;
  final bool showFollow;

  const _PlayerListTile({
    required this.name,
    this.subtitle,
    required this.score,
    this.showFollow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const _AvatarCircle(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (showFollow) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '+ Seguir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD7FF59),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              score,
              style: const TextStyle(
                color: AppColors.SecondBlue,
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

class _PlayerDivider extends StatelessWidget {
  const _PlayerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      width: double.infinity,
      height: 1,
      color: const Color(0xFFD7DDE5),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final bool selected;

  const _AvatarCircle({
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.PrimaryGreen : AppColors.PrimaryGreen,
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/Logo_Icono.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;

  const _HeroChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.whatshot,
            size: 14,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
