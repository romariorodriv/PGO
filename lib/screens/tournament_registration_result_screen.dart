import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/tournament_record.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_header_scaffold.dart';

class TournamentRegistrationResultScreen extends StatelessWidget {
  const TournamentRegistrationResultScreen({
    super.key,
    required this.tournament,
    required this.title,
    required this.message,
    required this.badge,
    required this.primaryLabel,
  });

  final TournamentRecord? tournament;
  final String title;
  final String message;
  final String badge;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Torneo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: AppColors.PrimaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.72),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _TournamentResultCard(
                tournament: tournament,
                badge: badge,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.PrimaryGreen,
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentResultCard extends StatelessWidget {
  const _TournamentResultCard({
    required this.tournament,
    required this.badge,
  });

  final TournamentRecord? tournament;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final photoUrl = tournament?.photoUrl;
    final bytes = tryDecodeDataUrl(photoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    photoUrl.startsWith('http')
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/InkaPadel.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : (bytes != null
                            ? Image.memory(bytes, fit: BoxFit.cover)
                            : Image.asset(
                                'assets/images/InkaPadel.png',
                                fit: BoxFit.cover,
                              ))
                  else
                    Image.asset(
                      'assets/images/InkaPadel.png',
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xD61C2A3A),
                          Color(0x661C2A3A),
                          Color(0x221C2A3A),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
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
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (tournament?.title ?? 'Torneo PGO').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament?.location ?? 'One Padel Olguin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
