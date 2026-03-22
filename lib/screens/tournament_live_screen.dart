import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_description_screen.dart';
import 'tournament_profile_screen.dart';

class TournamentLiveScreen extends StatelessWidget {
  const TournamentLiveScreen({Key? key}) : super(key: key);

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
                            const SizedBox(height: 18),
                            const _LiveMatchCard(
                              court: 'CANCHA 1',
                              elapsed: '25:14',
                              live: true,
                              teamA1: 'Jazmin',
                              teamA2: 'Bruno',
                              teamASets: '6-4',
                              teamB1: 'Pitu',
                              teamB2: 'Lorena',
                              teamBSets: '3-2',
                              footerLeft: '',
                              footerRight: 'Cuartos',
                            ),
                            const SizedBox(height: 14),
                            const _LiveMatchCard(
                              court: 'CANCHA 2',
                              teamA1: 'Romario',
                              teamA2: 'Arom',
                              teamASets: '',
                              teamB1: 'Mafer',
                              teamB2: 'Paula',
                              teamBSets: '3-1',
                              footerLeft: 'terminó hace 3 minutos',
                              footerRight: 'Cuartos',
                              showTrophy: true,
                            ),
                            const SizedBox(height: 14),
                            const _LiveMatchCard(
                              court: 'CANCHA 3',
                              teamA1: 'César',
                              teamA2: 'Andrea',
                              teamASets: '',
                              teamB1: 'Loraine',
                              teamB2: 'Tammy',
                              teamBSets: '',
                              footerLeft: 'empieza en 15 minutos',
                              footerRight: 'Cuartos',
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
                SizedBox(height: 12),
                _HeroChip(text: '3 amigos inscritos'),
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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'En vivo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TournamentProfileScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  'Jugadores',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

class _LiveMatchCard extends StatelessWidget {
  final String court;
  final String elapsed;
  final bool live;
  final String teamA1;
  final String teamA2;
  final String teamASets;
  final String teamB1;
  final String teamB2;
  final String teamBSets;
  final String footerLeft;
  final String footerRight;
  final bool showTrophy;

  const _LiveMatchCard({
    required this.court,
    this.elapsed = '',
    this.live = false,
    required this.teamA1,
    required this.teamA2,
    required this.teamASets,
    required this.teamB1,
    required this.teamB2,
    required this.teamBSets,
    required this.footerLeft,
    required this.footerRight,
    this.showTrophy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF456EA6),
                  AppColors.SecondBlue,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  court,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (elapsed.isNotEmpty)
                  Text(
                    elapsed,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (live) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3737),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              children: [
                _LiveTeamRow(
                  player1: teamA1,
                  player2: teamA2,
                  score: teamASets,
                  showTrophy: showTrophy,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFE0E5EC),
                ),
                const SizedBox(height: 10),
                _LiveTeamRow(
                  player1: teamB1,
                  player2: teamB2,
                  score: teamBSets,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      footerLeft,
                      style: TextStyle(
                        color: AppColors.SecondBlue.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      footerRight,
                      style: TextStyle(
                        color: AppColors.SecondBlue.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTeamRow extends StatelessWidget {
  final String player1;
  final String player2;
  final String score;
  final bool showTrophy;

  const _LiveTeamRow({
    required this.player1,
    required this.player2,
    required this.score,
    this.showTrophy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                player1,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/',
                style: TextStyle(
                  color: AppColors.SecondBlue.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                player2,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showTrophy) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: Color(0xFF9A9787),
                ),
              ],
            ],
          ),
        ),
        if (score.isNotEmpty)
          Text(
            score,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
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
