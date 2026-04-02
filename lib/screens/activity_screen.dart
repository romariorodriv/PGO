import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_options_menu.dart';
import '../widgets/pgo_header_scaffold.dart';
import 'activity_match_setup_screen.dart';
import 'live_match_setup_screen.dart';

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
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                '${_buildFirstName()},',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¿Listo para un nuevo partido?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.62),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 44),
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LiveMatchSetupScreen(
                        isCompetitive: _isCompetitive,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 56),
              Row(
                children: [
                  const Text(
                    'Competitivo',
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.96,
                    child: Switch(
                      value: _isCompetitive,
                      onChanged: (value) {
                        setState(() {
                          _isCompetitive = value;
                        });
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.SecondBlue,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFF7F889B),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              if (_isCompetitive) _CategoryCard(profile: _profile),
              const Spacer(flex: 2),
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
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFFD7FF59) : Colors.white,
          foregroundColor: AppColors.SecondBlue,
          elevation: filled ? 0 : 3,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile?.category ?? '4ta categoria',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '#${profile?.rankingPosition ?? 0}',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: 58,
                    child: ColoredBox(color: Color(0xFFD2C9A4)),
                  ),
                  Expanded(
                    flex: 42,
                    child: ColoredBox(color: Color(0xFFEBEDF1)),
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
