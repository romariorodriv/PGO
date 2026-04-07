import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'activity_match_setup_screen.dart';
import 'live_match_players_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isCompetitive = true;
  ProfileSummary? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService().getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (_) {}
  }

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
      actions: const [
        PgoOptionsMenuButton(),
      ],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 30),
          child: Column(
            children: [
              const SizedBox(height: 88),
              Text(
                '${_buildFirstName()},',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¿listo para un nuevo partido?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 48),
              _ActionButton(
                label: 'Registrar actividad',
                filled: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ActivityMatchSetupScreen(
                        isCompetitive: _isCompetitive,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: 'Registrar en vivo',
                enabled: _isCompetitive,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LiveMatchPlayersScreen(
                        isCompetitive: _isCompetitive,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 54),
              Row(
                children: [
                  const Text(
                    'Competitivo',
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _CompetitiveToggle(
                    value: _isCompetitive,
                    onChanged: (value) {
                      setState(() {
                        _isCompetitive = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_isCompetitive) _CategoryCard(profile: _profile),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFirstName() {
    final fullName = (_profile?.name ?? 'Romario').trim();
    if (fullName.isEmpty) {
      return 'Romario';
    }
    return fullName.split(RegExp(r'\s+')).first;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.enabled = true,
  });

  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? (filled ? const Color(0xFFD7FF59) : Colors.white)
              : const Color(0xFFE6E9EF),
          foregroundColor: enabled
              ? AppColors.SecondBlue
              : AppColors.SecondBlue.withValues(alpha: 0.45),
          disabledBackgroundColor: const Color(0xFFE6E9EF),
          disabledForegroundColor: AppColors.SecondBlue.withValues(alpha: 0.45),
          elevation: enabled ? 5 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: enabled
                ? AppColors.SecondBlue
                : AppColors.SecondBlue.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _CompetitiveToggle extends StatelessWidget {
  const _CompetitiveToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.SecondBlue : const Color(0xFFB7BECA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.profile,
  });

  final ProfileSummary? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile?.category ?? '4ta categoría',
                  style: const TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '#${profile?.rankingPosition ?? 120}',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEDF1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progressFactor(profile),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2C9A4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progressFactor(ProfileSummary? profile) {
    final ranking = profile?.rankingPosition ?? 120;
    if (ranking <= 0) {
      return 0.56;
    }
    final normalized = 1 - (ranking / 250);
    return normalized.clamp(0.22, 0.9);
  }
}
