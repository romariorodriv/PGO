import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MatchCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final BoxFit imageFit;
  final Alignment imageAlignment;
  final bool isLastMatch;

  const MatchCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.imageFit = BoxFit.cover,
    this.imageAlignment = Alignment.center,
    this.isLastMatch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: imageUrl != null
            ? DecorationImage(
                image: _buildImageProvider(imageUrl!),
                fit: imageFit,
                alignment: imageAlignment,
              )
            : null,
        color: imageUrl == null ? AppColors.SecondBlue : AppColors.PrimaryGreen,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.SecondBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) SizedBox(height: 4),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.SecondBlue.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _buildImageProvider(String urlOrAsset) {
    if (urlOrAsset.startsWith('assets/')) {
      return AssetImage(urlOrAsset);
    }
    return NetworkImage(urlOrAsset);
  }
}
