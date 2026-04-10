import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF7F8FA);
  static const Color primaryDark = Color(0xFFF1F3F6);
  static const Color primaryLight = Color(0xFFE5E7EB);

  static const Color gray = Color(0xFF6B7280);

  static const Color PrimaryGreen = Color(0xFFD8FF59);
  static const Color secondaryGreen = Color(0xFFB6D735);
  static const Color homeGreen = Color(0xFFD8FF59);
  static const Color loginGreen = Color(0xFFC3E23A);
  static const Color primaryOrange = Color(0xFFF49705);

  static const Color brown = Color(0xFF898675);
  static const Color brownLight = Color(0xFF999682);
  static const Color brownDark = Color(0xFFDBD8B9);

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

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF4972A8),
      headerBlueEnd,
    ],
  );

  static const BoxDecoration headerGradientDecoration = BoxDecoration(
    gradient: headerGradient,
  );

  static const BoxDecoration secondaryGradientDecoration = BoxDecoration(
    gradient: secondaryGradient,
  );

  static const double headerToolbarHeight = 88;

  static const Color blue = headerBlueStart;
  static const Color SecondBlue = headerBlueEnd;
}
