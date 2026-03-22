import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'tournament_description_screen.dart';
import 'tournament_live_screen.dart';
import 'tournament_profile_screen.dart';

class TournamentBracketScreen extends StatelessWidget {
  const TournamentBracketScreen({Key? key}) : super(key: key);

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
                            _buildTopTabs(context),
                            const SizedBox(height: 10),
                            _buildStageTabs(),
                            const SizedBox(height: 14),
                            const _BracketMatchCard(
                              teamA1: 'Romario',
                              teamA2: 'Arom',
                              rankA: '#120',
                              scoreA: '#111',
                              teamB1: 'Tom',
                              teamB2: 'Migue',
                              rankB: '#110',
                              scoreB: '#115',
                              court: 'CANCHA 1',
                              time: '20:30',
                            ),
                            const SizedBox(height: 14),
                            const _BracketMatchCard(
                              teamA1: 'Karo',
                              teamA2: 'Teffi',
                              rankA: '#105',
                              scoreA: '#101',
                              teamB1: 'Mafe',
                              teamB2: 'Paula',
                              rankB: '#97',
                              scoreB: '#90',
                              court: 'CANCHA 4',
                              time: '21:30',
                            ),
                            const SizedBox(height: 14),
                            const _BracketMatchCard(
                              teamA1: 'Logan',
                              teamA2: 'Yupi',
                              rankA: '#12',
                              scoreA: '#80',
                              teamB1: 'Brisa',
                              teamB2: 'Pj',
                              rankB: '#92',
                              scoreB: '#8',
                              court: 'CANCHA 2',
                              time: '19:00',
                            ),
                            const SizedBox(height: 14),
                            const _BracketMatchCard(
                              teamA1: 'Axl',
                              teamA2: 'Lucho',
                              rankA: '#103',
                              scoreA: '#104',
                              teamB1: 'Nico',
                              teamB2: 'Renzo',
                              rankB: '#95',
                              scoreB: '#87',
                              court: 'CANCHA 3',
                              time: '18:30',
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

  Widget _buildTopTabs(BuildContext context) {
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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Bracket',
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

  Widget _buildStageTabs() {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF0),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _StageTab(label: 'Octavos', selected: true),
          ),
          Expanded(
            child: _StageTab(label: 'Cuartos'),
          ),
          Expanded(
            child: _StageTab(label: 'Semis'),
          ),
          Expanded(
            child: _StageTab(label: 'Final'),
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

class _StageTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _StageTab({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.SecondBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.SecondBlue,
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final String teamA1;
  final String teamA2;
  final String rankA;
  final String scoreA;
  final String teamB1;
  final String teamB2;
  final String rankB;
  final String scoreB;
  final String court;
  final String time;

  const _BracketMatchCard({
    required this.teamA1,
    required this.teamA2,
    required this.rankA,
    required this.scoreA,
    required this.teamB1,
    required this.teamB2,
    required this.rankB,
    required this.scoreB,
    required this.court,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              children: [
                _BracketTeamRow(
                  player1: teamA1,
                  player2: teamA2,
                  rank: rankA,
                  score: scoreA,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFE3E7ED),
                ),
                const SizedBox(height: 10),
                _BracketTeamRow(
                  player1: teamB1,
                  player2: teamB2,
                  rank: rankB,
                  score: scoreB,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF8893A7),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Lunes 19 Dic',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  court,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '- $time',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 10,
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
}

class _BracketTeamRow extends StatelessWidget {
  final String player1;
  final String player2;
  final String rank;
  final String score;

  const _BracketTeamRow({
    required this.player1,
    required this.player2,
    required this.rank,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _MiniPlayer(),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            player1,
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          width: 1,
          height: 16,
          color: const Color(0xFFE3E7ED),
        ),
        const SizedBox(width: 10),
        const _MiniPlayer(),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            player2,
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(
          Icons.emoji_events,
          size: 14,
          color: Color(0xFF9A9787),
        ),
        const SizedBox(width: 4),
        Text(
          rank,
          style: TextStyle(
            color: AppColors.SecondBlue.withOpacity(0.6),
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
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.PrimaryGreen,
          width: 1,
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
