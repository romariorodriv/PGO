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
                      builder: (context) => const ActivityMatchSetupScreen(
                        isCompetitive: true,
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
                      builder: (context) => const LiveMatchPlayersScreen(
                        isCompetitive: true,
                      ),
                    ),
                  );
                },
              ),
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
