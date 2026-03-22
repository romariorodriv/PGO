import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'home_screen.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String matchDate;

  const MatchSummaryScreen({
    Key? key,
    required this.matchDate,
  }) : super(key: key);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScoreCard(),
                        const SizedBox(height: 18),
                        _buildInfoCard(),
                        const SizedBox(height: 14),
                        const Text(
                          'Jugadores',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPlayersRow(),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD7FF59),
                              foregroundColor: AppColors.SecondBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'REGRESAR AL INICIO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildHeroCard() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: Image.asset(
            'assets/images/trigal_onepadel.png',
            width: double.infinity,
            height: 330,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 330,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.42),
              ],
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Match competitivo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                matchDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sets',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              '3 - 1',
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFD7DDE5),
          ),
          const SizedBox(height: 10),
          const Text(
            'Games',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GamePill(score: '6 - 2'),
              _GamePill(score: '7 - 5'),
              _GamePill(score: '5 - 7'),
              _GamePill(score: '10 - 3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'Nivel',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '4ta categoría',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Ranking',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '#188 (+2)',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.48),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE3E7ED),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text(
                  'Club',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'One Padel Olguín',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withOpacity(0.72),
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

  Widget _buildPlayersRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SummaryPlayer(
          label: 'Romario',
          imageAsset: 'assets/images/Logo_Icono.png',
          selected: true,
        ),
        _SummaryPlayer(label: 'Jugador 2'),
        _SummaryPlayer(label: 'Jugador 3'),
        _SummaryPlayer(label: 'Jugador 4'),
      ],
    );
  }
}

class _GamePill extends StatelessWidget {
  final String score;

  const _GamePill({
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.SecondBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        score,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryPlayer extends StatelessWidget {
  final String label;
  final String? imageAsset;
  final bool selected;

  const _SummaryPlayer({
    required this.label,
    this.imageAsset,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.PrimaryGreen : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFAAB5CB),
              ),
              child: imageAsset == null
                  ? null
                  : ClipOval(
                      child: Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
