import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CompetitorCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String level;
  final BoxFit imageFit;
  final Alignment imageAlignment;

  const CompetitorCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.level,
    this.imageFit = BoxFit.cover,
    this.imageAlignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: _buildImageProvider(imageUrl),
              fit: imageFit,
              alignment: imageAlignment,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.PrimaryGreen);
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.SecondBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    level,
                    style: TextStyle(
                      color: AppColors.PrimaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
