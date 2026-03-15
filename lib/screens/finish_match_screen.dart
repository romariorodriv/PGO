import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'match_summary_screen.dart';

class FinishMatchScreen extends StatefulWidget {
  final String matchDate;

  const FinishMatchScreen({
    Key? key,
    required this.matchDate,
  }) : super(key: key);

  @override
  State<FinishMatchScreen> createState() => _FinishMatchScreenState();
}

class _FinishMatchScreenState extends State<FinishMatchScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _photoAdded = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _togglePhotoState() {
    setState(() {
      _photoAdded = !_photoAdded;
    });
  }

  void _finishMatch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchSummaryScreen(
          matchDate: widget.matchDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SecondBlue,
      appBar: AppBar(
        backgroundColor: AppColors.SecondBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.matchDate,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withOpacity(0.82),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildXpCard(),
                const SizedBox(height: 16),
                _buildClubChip(),
                const SizedBox(height: 24),
                const Text(
                  'Añade tu foto del match',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _buildPhotoCard(),
                const SizedBox(height: 24),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    color: AppColors.SecondBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _buildDescriptionField(),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4FF63),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Finalizar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '+30 XP',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 56,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+10 puntos para subir de nivel',
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '4ta categoría',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: const [
                  Expanded(
                    flex: 52,
                    child: ColoredBox(color: Color(0xFFA79F85)),
                  ),
                  Expanded(
                    flex: 24,
                    child: ColoredBox(color: Color(0xFFD3D1B2)),
                  ),
                  Expanded(
                    flex: 24,
                    child: ColoredBox(color: Color(0xFFE4E6EB)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '+14 PCM',
                style: TextStyle(
                  color: AppColors.SecondBlue.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '+2 ranking',
                style: TextStyle(
                  color: AppColors.SecondBlue.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'One Padel Olguín',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return InkWell(
      onTap: _togglePhotoState,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 182,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _photoAdded ? Icons.check_circle : Icons.photo_camera,
              size: 52,
              color: _photoAdded
                  ? AppColors.PrimaryGreen
                  : const Color(0xFF99A5BA),
            ),
            const SizedBox(height: 10),
            Text(
              _photoAdded ? 'Foto agregada' : 'Subir foto',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Descripción opcional',
          hintStyle: TextStyle(
            color: AppColors.SecondBlue.withOpacity(0.45),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
