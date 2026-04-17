import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/colors.dart';
import '../models/match_record.dart';
import '../models/selected_player.dart';
import '../services/match_service.dart';
import '../widgets/pgo_header_scaffold.dart';
import '../widgets/pgo_options_menu.dart';
import 'match_summary_screen.dart';

class FinishMatchScreen extends StatefulWidget {
  const FinishMatchScreen({
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

  @override
  State<FinishMatchScreen> createState() => _FinishMatchScreenState();
}

class _FinishMatchScreenState extends State<FinishMatchScreen> {
  static const _winnerXp = 30;
  static const _maxMatchPhotoBytes = 850 * 1024;

  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedPhotoBytes;
  String? _encodedPhoto;
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<SelectedPlayer> get _winnerPlayers {
    if (widget.winnerTeam == 1) {
      return widget.players.take(2).toList();
    }
    return widget.players.skip(2).take(2).toList();
  }

  String get _winnerCategory {
    final category = _winnerPlayers
        .map((player) => player.category)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '4ta categoria');
    return category.toLowerCase().contains('categoria')
        ? category
        : '$category categoria';
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 960,
      maxHeight: 960,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (bytes.length > _maxMatchPhotoBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La imagen sigue siendo muy grande. Prueba con una foto mas ligera o recortada.',
          ),
        ),
      );
      return;
    }
    final mimeType =
        image.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    setState(() {
      _selectedPhotoBytes = bytes;
      _encodedPhoto = 'data:$mimeType;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _finishMatch() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final finalizedMatch = await MatchService().finalizeMatch(
        matchId: widget.match.id,
        winnerPlayerIds: _winnerPlayers.map((player) => player.id).toList(),
        description: _descriptionController.text,
        photoUrl: _encodedPhoto,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MatchSummaryScreen(
            matchDate: widget.matchDate,
            match: finalizedMatch,
            players: widget.players,
            winnerTeam: widget.winnerTeam,
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
        primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
      child: PgoHeaderScaffold(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Actividad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
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
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.matchDate,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildXpCard(),
                const SizedBox(height: 14),
                _buildClubChip(),
                const SizedBox(height: 18),
                const Text(
                  'Añade tu foto del match',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPhotoCard(),
                const SizedBox(height: 18),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDescriptionField(),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _finishMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'FINALIZAR',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
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
    );
  }

  Widget _buildXpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '+$_winnerXp XP',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 58,
              height: 1,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            '+10 puntos para subir de nivel',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _winnerCategory,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 17,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              color: const Color(0xFFE0E3E9),
              child: const FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: ColoredBox(color: Color(0xFFA7A087)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '+14 PCM',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '+2 ranking',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClubChip() {
    return Container(
      width: double.infinity,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        widget.match.clubName,
        style: const TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 152,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFCDD4DE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedPhotoBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(
                  _selectedPhotoBytes!,
                  fit: BoxFit.cover,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera,
                    size: 50,
                    color: Color(0xFFA6B0C1),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Subir foto',
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _descriptionController,
        minLines: 1,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: 'Descripción opcional',
          hintStyle: TextStyle(
            color: AppColors.SecondBlue.withValues(alpha: 0.42),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
