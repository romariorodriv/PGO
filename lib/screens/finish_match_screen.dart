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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F3F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.matchDate,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withOpacity(0.8),
                      fontSize: 14,
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
                    fontSize: 16,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDescriptionField(),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF59),
                      foregroundColor: AppColors.SecondBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'FINALIZAR',
                      style: TextStyle(
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
      ),
    );
  }

  Widget _buildXpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '+30 XP',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 58,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '+10 puntos para subir de nivel',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '4ta categoría',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: const [
                  Expanded(
                    flex: 50,
                    child: ColoredBox(color: Color(0xFFA7A087)),
                  ),
                  Expanded(
                    flex: 18,
                    child: ColoredBox(color: Color(0xFFC6C0A4)),
                  ),
                  Expanded(
                    flex: 32,
                    child: ColoredBox(color: Color(0xFFDADDE3)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text(
                '+14 PCM',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '+2 ranking',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 14,
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
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        'One Padel Olguín',
        style: TextStyle(
          color: AppColors.SecondBlue,
          fontSize: 15,
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
        height: 152,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFCDD4DE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _photoAdded ? Icons.check_circle : Icons.photo_camera,
              size: 50,
              color: _photoAdded
                  ? AppColors.PrimaryGreen
                  : const Color(0xFFA6B0C1),
            ),
            const SizedBox(height: 10),
            Text(
              _photoAdded ? 'Foto agregada' : 'Subir foto',
              style: const TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 16,
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
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: 'Descripción opcional',
          hintStyle: TextStyle(
            color: AppColors.SecondBlue.withOpacity(0.42),
            fontSize: 15,
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
