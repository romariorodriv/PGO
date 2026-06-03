import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../services/profile_service.dart';
import '../utils/data_url_image.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'main_shell.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.profile,
  });

  final ProfileSummary profile;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _preferredClubController;
  String? _preferredSide;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _categoryController =
        TextEditingController(text: widget.profile.category ?? '');
    _preferredClubController =
        TextEditingController(text: widget.profile.preferredClub ?? '');
    _preferredSide = _normalizeSide(widget.profile.preferredSide);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _preferredClubController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre valido.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await ProfileService().updateMyProfile(
        name: _nameController.text,
        photoUrl: widget.profile.photoUrl,
        category: _categoryController.text,
        preferredClub: _preferredClubController.text,
        preferredSide: _preferredSide,
        racketModel: widget.profile.racketModel,
        experienceLevel: widget.profile.experienceLevel,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updated);
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        primaryTextTheme:
            GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Editar perfil',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: const [
          PgoOptionsMenuButton(),
        ],
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
            child: Column(
              children: [
                _EditProfileHeroCard(
                  profile: widget.profile,
                  nameController: _nameController,
                  categoryController: _categoryController,
                ),
                const SizedBox(height: 16),
                _PersonalDataCard(
                  preferredClubController: _preferredClubController,
                  preferredSide: _preferredSide,
                  onSideChanged: (value) {
                    setState(() {
                      _preferredSide = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: PgoBottomNav(
          currentTab: PgoNavTab.profile,
          onHomeTap: () {
            MainShell.openReplacement(context, initialTab: PgoNavTab.home);
          },
          onTournamentsTap: () {
            MainShell.openReplacement(
              context,
              initialTab: PgoNavTab.tournaments,
            );
          },
          onProfileTap: () {
            MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
          },
        ),
      ),
    );
  }

  String? _normalizeSide(String? side) {
    final normalized = side?.trim();
    if (normalized == null || normalized.isEmpty) return 'Drive';
    if (normalized.toLowerCase().contains('reves')) return 'Revés';
    if (normalized.toLowerCase().contains('amb')) return 'Ambos';
    return 'Drive';
  }
}

class _EditProfileHeroCard extends StatelessWidget {
  const _EditProfileHeroCard({
    required this.profile,
    required this.nameController,
    required this.categoryController,
  });

  final ProfileSummary profile;
  final TextEditingController nameController;
  final TextEditingController categoryController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _AvatarPreview(photoUrl: profile.photoUrl),
          const SizedBox(height: 16),
          _InlineEditField(
            label: 'Nombre',
            controller: nameController,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _InlineEditField(
            label: 'Categoría',
            controller: categoryController,
            icon: Icons.workspace_premium_outlined,
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: const Color(0xFFE0E4EB),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: '${profile.experiencePoints} XP',
                  caption: 'Experiencia',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoPill(
                  label: '${profile.weeklyStreak}',
                  caption: 'Racha Semanal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard({
    required this.preferredClubController,
    required this.preferredSide,
    required this.onSideChanged,
  });

  final TextEditingController preferredClubController;
  final String? preferredSide;
  final ValueChanged<String?> onSideChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos personales',
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Edita solo la información básica visible en tu perfil.',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.52),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _InlineEditField(
            label: 'Club preferido',
            controller: preferredClubController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: preferredSide,
            decoration: _inputDecoration(
              label: 'Lado de juego',
              icon: Icons.sports_tennis_rounded,
            ),
            items: const [
              DropdownMenuItem(value: 'Drive', child: Text('Drive')),
              DropdownMenuItem(value: 'Revés', child: Text('Revés')),
              DropdownMenuItem(value: 'Ambos', child: Text('Ambos')),
            ],
            onChanged: onSideChanged,
          ),
        ],
      ),
    );
  }
}

class _InlineEditField extends StatelessWidget {
  const _InlineEditField({
    required this.label,
    required this.controller,
    required this.icon,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.photoUrl,
  });

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl?.trim() ?? '';
    final hasRemotePhoto = trimmed.startsWith('http');
    final bytes = tryDecodeDataUrl(trimmed);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFD7FF59), Color(0xFF3F6EA5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: const Color(0xFFE8EAEE),
        backgroundImage: hasRemotePhoto ? NetworkImage(trimmed) : null,
        child: hasRemotePhoto
            ? null
            : bytes != null
                ? ClipOval(
                    child: Image.memory(
                      bytes,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 42,
                    color: AppColors.SecondBlue.withValues(alpha: 0.7),
                  ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.caption,
  });

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.54),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18, color: AppColors.SecondBlue),
    labelStyle: TextStyle(
      color: AppColors.SecondBlue.withValues(alpha: 0.7),
      fontWeight: FontWeight.w800,
      fontSize: 12,
    ),
    filled: true,
    fillColor: const Color(0xFFF0F3F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
