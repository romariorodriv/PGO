import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/selected_player.dart';
import 'main_shell.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';

class MatchSummaryScreen extends StatelessWidget {
  const MatchSummaryScreen({
    super.key,
    required this.matchDate,
    required this.match,
    required this.players,
    required this.winnerTeam,
  });

  final String matchDate;
  final MatchRecord match;
  final List<SelectedPlayer> players;
  final int winnerTeam;

  int get _team1Games => match.games.fold<int>(
      0, (total, game) => total + ((game['team1'] as num?)?.toInt() ?? 0));

  int get _team2Games => match.games.fold<int>(
      0, (total, game) => total + ((game['team2'] as num?)?.toInt() ?? 0));

  List<SelectedPlayer> get _winnerPlayers => winnerTeam == 1
      ? players.take(2).toList()
      : players.skip(2).take(2).toList();

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
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
      actions: const [PgoOptionsMenuButton()],
      body: Container(
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
                      if (match.description != null &&
                          match.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Descripcion',
                          style: TextStyle(
                            color: AppColors.SecondBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDescriptionCard(),
                      ],
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
                            MainShell.openReplacement(
                              context,
                              initialTab: PgoNavTab.home,
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
    );
  }

  Widget _buildHeroCard() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: SizedBox(
            width: double.infinity,
            height: 330,
            child: _buildHeroImage(),
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
                Colors.black.withValues(alpha: 0.42),
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
              Text(
                match.matchType == 'RANKED'
                    ? 'Match competitivo'
                    : 'Match amistoso',
                style: const TextStyle(
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

  Widget _buildHeroImage() {
    final photoUrl = match.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return Image.asset(
        'assets/images/trigal_onepadel.png',
        fit: BoxFit.cover,
      );
    }

    final memoryBytes = _tryDecodeDataUrl(photoUrl);
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/trigal_onepadel.png',
        fit: BoxFit.cover,
      ),
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
            color: Colors.black.withValues(alpha: 0.09),
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
          Center(
            child: Text(
              '$_team1Games - $_team2Games',
              style: const TextStyle(
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: match.games
                .map(
                  (game) => _GamePill(
                    score:
                        '${(game['team1'] as num?)?.toInt() ?? 0} - ${(game['team2'] as num?)?.toInt() ?? 0}',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final winnerReference =
        _winnerPlayers.isNotEmpty ? _winnerPlayers.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                  winnerReference?.category ?? 'Sin categoria',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
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
                  '#${winnerReference?.rankingPosition ?? 0}',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.48),
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
                  match.clubName,
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
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

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        match.description!.trim(),
        style: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlayersRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: players
          .map(
            (player) => _SummaryPlayer(
              label: player.name,
              imageUrl: player.photoUrl,
              selected: _winnerPlayers.any((winner) => winner.id == player.id),
            ),
          )
          .toList(),
    );
  }

  Uint8List? _tryDecodeDataUrl(String value) {
    if (!value.startsWith('data:image/')) {
      return null;
    }

    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) {
      return null;
    }

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
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
  final String? imageUrl;
  final bool selected;

  const _SummaryPlayer({
    required this.label,
    this.imageUrl,
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
              child: imageUrl == null || imageUrl!.isEmpty
                  ? null
                  : ClipOval(
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
