import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../models/selected_player.dart';
import '../services/match_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'live_match_screen.dart';
import 'main_shell.dart';

class LiveMatchSetupScreen extends StatefulWidget {
  const LiveMatchSetupScreen({
    super.key,
    required this.isCompetitive,
    required this.profile,
    required this.players,
    this.clubName,
  });

  final bool isCompetitive;
  final ProfileSummary profile;
  final List<SelectedPlayer> players;
  final String? clubName;

  @override
  State<LiveMatchSetupScreen> createState() => _LiveMatchSetupScreenState();
}

class _LiveMatchSetupScreenState extends State<LiveMatchSetupScreen> {
  static const _fallbackClubName = 'One Padel Olguin';

  bool _isSubmitting = false;
  int? _servingTeam;

  void _handleDrawServingTeam() {
    setState(() {
      _servingTeam = Random().nextBool() ? 1 : 2;
    });
  }

  Future<void> _handleStartMatch() async {
    if (_servingTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el equipo que empieza sacando'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final match = await MatchService().createMatch(
        clubName: widget.clubName ??
            widget.profile.preferredClub ??
            _fallbackClubName,
        playedAt: DateTime.now(),
        matchType: widget.isCompetitive ? 'RANKED' : 'FRIENDLY',
        participantIds: widget.players.map((player) => player.id).toList(),
        photoUrl: widget.profile.photoUrl,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveMatchScreen(
            match: match,
            players: widget.players,
            initialServingTeam: _servingTeam!,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Theme(
      data: currentTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(currentTheme.textTheme),
        primaryTextTheme:
            GoogleFonts.interTextTheme(currentTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Registro en vivo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: const [
          PgoOptionsMenuButton(),
        ],
        bottomNavigationBar: PgoBottomNav(
          currentTab: PgoNavTab.tournaments,
          onHomeTap: () {
            MainShell.openReplacement(context, initialTab: PgoNavTab.home);
          },
          onTournamentsTap: () {
            MainShell.openReplacement(context,
                initialTab: PgoNavTab.tournaments);
          },
          onProfileTap: () {
            MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
          },
        ),
        body: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F5F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFB7D56A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sports_tennis,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cancha 2 - Semifinal',
                              style: TextStyle(
                                color: AppColors.SecondBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Equipo 1',
                                      style: TextStyle(
                                        color: AppColors.SecondBlue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _LiveSetupPlayer(
                                            player: widget.players[0]),
                                        _LiveSetupPlayer(
                                            player: widget.players[1]),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const VerticalDivider(
                                width: 22,
                                thickness: 1,
                                color: Color(0xFFCBD2DE),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Equipo 2',
                                      style: TextStyle(
                                        color: AppColors.SecondBlue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _LiveSetupPlayer(
                                            player: widget.players[2]),
                                        _LiveSetupPlayer(
                                            player: widget.players[3]),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: const Color(0xFFD8DEE8),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            '¿Quién empieza sacando?',
                            style: TextStyle(
                              color: AppColors.SecondBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleDrawServingTeam,
                              borderRadius: BorderRadius.circular(15),
                              child: Ink(
                                width: 138,
                                height: 30,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 22),
                                decoration: BoxDecoration(
                                  gradient: AppColors.secondaryGradient,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Center(
                                  child: Text(
                                    'SORTEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _ServeOptionCard(
                          active: _servingTeam == 1,
                          players: widget.players.take(2).toList(),
                          showBall: _servingTeam == 1,
                          onTap: () {
                            setState(() {
                              _servingTeam = 1;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _ServeOptionCard(
                          active: _servingTeam == 2,
                          players: widget.players.skip(2).take(2).toList(),
                          showBall: _servingTeam == 2,
                          onTap: () {
                            setState(() {
                              _servingTeam = 2;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleStartMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7FF59),
                        disabledBackgroundColor:
                            const Color(0xFFD7FF59).withValues(alpha: 0.45),
                        foregroundColor: AppColors.SecondBlue,
                        disabledForegroundColor:
                            AppColors.SecondBlue.withValues(alpha: 0.55),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'EMPEZAR PARTIDO',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.SecondBlue,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveSetupPlayer extends StatelessWidget {
  const _LiveSetupPlayer({
    required this.player,
  });

  final SelectedPlayer player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.PrimaryGreen,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                  ? Image.network(
                      player.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFABB8CC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }
}

class _ServeOptionCard extends StatelessWidget {
  const _ServeOptionCard({
    required this.active,
    required this.players,
    required this.onTap,
    this.showBall = false,
  });

  final bool active;
  final List<SelectedPlayer> players;
  final VoidCallback onTap;
  final bool showBall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.PrimaryGreen : const Color(0xFFE2E6ED),
            width: active ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: players
                    .map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _ServePlayerMini(player: player),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 38,
              color: const Color(0xFFD8DEE8),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              child: showBall
                  ? const Icon(
                      Icons.sports_tennis,
                      color: Color(0xFFB7D56A),
                      size: 24,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServePlayerMini extends StatelessWidget {
  const _ServePlayerMini({
    required this.player,
  });

  final SelectedPlayer player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFD4DEED),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.PrimaryGreen,
                width: 1.2,
              ),
            ),
            child: ClipOval(
              child: player.photoUrl != null && player.photoUrl!.isNotEmpty
                  ? Image.network(
                      player.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFABB8CC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
