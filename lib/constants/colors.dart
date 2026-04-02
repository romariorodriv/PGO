import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - white oscuro (como en el diseño PGO)
  static const Color primary = Color(0xFFf7f8fa);
  static const Color primaryDark = Color(0xFFf1f3f6);
  static const Color primaryLight = Color(0xFFe5e7eb);

  static const Color gray = Color(0xFF6b7280);

  // Secondary colors - Verde lima (como en el diseño PGO)
  static const Color PrimaryGreen = Color(0xFFa9c93e); // Verde lima
  static const Color secondaryGreen = Color(0xFF9fbe2e); //verde oscuro
  static const Color primaryOrange = Color(0xFFf49705); //naranja

  // Neutral colors
  static const Color brown = Color(0xFF898675);
  static const Color brownLight = Color(0xFF999682);
  static const Color brownDark = Color(0xFFdbd8b9);

  // Header colors
  static const Color headerBlueStart = Color(0xFF3D659A);
  static const Color headerBlueEnd = Color(0xFF1C2A3A);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0, 0.45, 1],
    colors: [
      headerBlueStart,
      Color(0xFF314F78),
      headerBlueEnd,
    ],
  );

  static const BoxDecoration headerGradientDecoration = BoxDecoration(
    gradient: headerGradient,
  );

  static const double headerToolbarHeight = 88;

  // Status colors
  static const Color blue = headerBlueStart;
  static const Color SecondBlue = headerBlueEnd;
}
