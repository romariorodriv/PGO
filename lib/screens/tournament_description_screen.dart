import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'tournament_bracket_screen.dart';
import 'tournament_live_screen.dart';
import 'tournament_profile_screen.dart';
import 'tournament_register_screen.dart';

class TournamentDescriptionScreen extends StatelessWidget {
  final bool isPaid;

  const TournamentDescriptionScreen({
    Key? key,
    this.isPaid = false,
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
                            const SizedBox(height: 22),
                            _buildLocationRow(),
                            const SizedBox(height: 14),
                            _buildDivider(),
                            const SizedBox(height: 16),
                            _buildPlayersProgress(),
                            const SizedBox(height: 18),
                            _buildSimpleRow(
                              icon: Icons.emoji_events_outlined,
                              text: 'S/ 250 en premios',
                            ),
                            const SizedBox(height: 12),
                            _buildSimpleRow(
                              icon: Icons.monetization_on_outlined,
                              text: 'S/.60',
                            ),
                            const SizedBox(height: 22),
                            _buildPlayersPreview(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isPaid) {
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TournamentRegisterScreen(),
                                    ),
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
                                child: Text(
                                  isPaid ? 'IR AL PARTIDO' : 'UNIRME',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                  '4TA categoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _HeroChip(text: '1 buscando dupla'),
                    SizedBox(width: 10),
                    _HeroChip(text: '3 amigos inscritos'),
                  ],
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
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SecondBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Descripcion',
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
                Navigator.of(context).push(
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

  Widget _buildLocationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Icon(
          Icons.location_on_outlined,
          size: 22,
          color: Color(0xFFA8B1C1),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'One Padel Trigal',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lunes 19 Dic',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersProgress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.groups_2_outlined,
          size: 22,
          color: Color(0xFFA8B1C1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '8 de 16 jugadores',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 8,
                        child: ColoredBox(color: Color(0xFFD7FF59)),
                      ),
                      Expanded(
                        flex: 8,
                        child: ColoredBox(color: Color(0xFFAAB5CB)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFA8B1C1),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.SecondBlue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayersPreview() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _PreviewPlayer(label: 'Romario', image: true),
          SizedBox(width: 8),
          _PreviewPlayer(label: 'Jugador 2'),
          SizedBox(width: 8),
          _PreviewPlayer(label: 'Jugador 3'),
          SizedBox(width: 8),
          _PreviewPlayer(label: 'Jugador 4'),
          SizedBox(width: 8),
          _PreviewPlayer(label: 'Jugador 3'),
          SizedBox(width: 8),
          _PreviewMore(text: '+8 mas'),
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

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: const Color(0xFFD3DAE3),
    );
  }
}

class _PreviewPlayer extends StatelessWidget {
  final String label;
  final bool image;

  const _PreviewPlayer({
    required this.label,
    this.image = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.PrimaryGreen,
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: image
                  ? Image.asset(
                      'assets/images/Logo_Icono.png',
                      fit: BoxFit.cover,
                    )
                  : Container(color: const Color(0xFFAAB5CB)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMore extends StatelessWidget {
  final String text;

  const _PreviewMore({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 11,
          fontWeight: FontWeight.w500,
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
