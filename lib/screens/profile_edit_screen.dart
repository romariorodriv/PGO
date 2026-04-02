import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/profile_summary.dart';
import '../widgets/pgo_options_menu.dart';
import '../services/profile_service.dart';
import '../widgets/pgo_bottom_nav.dart';
import '../widgets/pgo_header_scaffold.dart';
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
  late final TextEditingController _photoUrlController;
  late final TextEditingController _categoryController;
  late final TextEditingController _preferredClubController;
  late final TextEditingController _preferredSideController;
  late final TextEditingController _racketModelController;
  String? _experienceLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _photoUrlController =
        TextEditingController(text: widget.profile.photoUrl ?? '');
    _categoryController =
        TextEditingController(text: widget.profile.category ?? '');
    _preferredClubController =
        TextEditingController(text: widget.profile.preferredClub ?? '');
    _preferredSideController =
        TextEditingController(text: widget.profile.preferredSide ?? '');
    _racketModelController =
        TextEditingController(text: widget.profile.racketModel ?? '');
    _experienceLevel = widget.profile.experienceLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _categoryController.dispose();
    _preferredClubController.dispose();
    _preferredSideController.dispose();
    _racketModelController.dispose();
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
        photoUrl: _photoUrlController.text,
        category: _categoryController.text,
        preferredClub: _preferredClubController.text,
        preferredSide: _preferredSideController.text,
        racketModel: _racketModelController.text,
        experienceLevel: _experienceLevel,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
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
    return PgoHeaderScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Editar perfil',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        const PgoOptionsMenuButton(),
      ],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F4F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _AvatarPreview(photoUrl: _photoUrlController.text),
                    const SizedBox(height: 18),
                    _ProfileField(
                      label: 'Nombre',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Foto de perfil (URL)',
                      controller: _photoUrlController,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Categoria',
                      controller: _categoryController,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Club preferido',
                      controller: _preferredClubController,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Lado de juego preferido',
                      controller: _preferredSideController,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      label: 'Pala que utilizas',
                      controller: _racketModelController,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _experienceLevel,
                      decoration: _inputDecoration('Nivel de experiencia'),
                      items: const [
                        DropdownMenuItem(
                          value: 'BEGINNER',
                          child: Text('Beginner'),
                        ),
                        DropdownMenuItem(
                          value: 'INTERMEDIATE',
                          child: Text('Intermediate'),
                        ),
                        DropdownMenuItem(
                          value: 'ADVANCED',
                          child: Text('Advanced'),
                        ),
                        DropdownMenuItem(
                          value: 'PRO',
                          child: Text('Pro'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _experienceLevel = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7FF59),
                    foregroundColor: AppColors.SecondBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
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
      bottomNavigationBar: PgoBottomNav(
        currentTab: PgoNavTab.profile,
        onHomeTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.home);
        },
        onTournamentsTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.tournaments);
        },
        onProfileTap: () {
          MainShell.openReplacement(context, initialTab: PgoNavTab.profile);
        },
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.photoUrl,
  });

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = photoUrl.trim();
    final hasRemotePhoto = trimmed.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFD4F34E),
      ),
      child: CircleAvatar(
        radius: 42,
        backgroundColor: const Color(0xFFE8EAEE),
        backgroundImage: hasRemotePhoto ? NetworkImage(trimmed) : null,
        child: hasRemotePhoto
            ? null
            : Icon(
                Icons.person,
                size: 42,
                color: AppColors.SecondBlue.withValues(alpha: 0.7),
              ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: AppColors.SecondBlue,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: const Color(0xFFF4F5F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}
