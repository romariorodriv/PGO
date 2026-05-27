import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class PgoTextStyles {
  // =========================
  // Pantallas principales
  // =========================

  static TextStyle display({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 34, color: color, weight: weight, height: 0.98);
  }

  static TextStyle screenTitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 32, color: color, weight: weight, height: 1.05);
  }

  static TextStyle screenSubtitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w500,
  }) {
    return _base(size: 15, color: color, weight: weight, height: 1.25);
  }

  static TextStyle sectionTitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 18, color: color, weight: weight, height: 1.15);
  }

  // =========================
  // Textos generales
  // =========================

  static TextStyle title({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 16, color: color, weight: weight, height: 1.15);
  }

  static TextStyle body({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w500,
    double height = 1.25,
  }) {
    return _base(size: 14, color: color, weight: weight, height: height);
  }

  static TextStyle bodyLarge({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w500,
    double height = 1.25,
  }) {
    return _base(size: 16, color: color, weight: weight, height: height);
  }

  static TextStyle bodySecondary({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w500,
  }) {
    return _base(size: 13, color: color, weight: weight, height: 1.25);
  }

  static TextStyle caption({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w600,
  }) {
    return _base(size: 12, color: color, weight: weight, height: 1.2);
  }

  static TextStyle small({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 11, color: color, weight: weight, height: 1.1);
  }

  // =========================
  // Cards
  // =========================

  static TextStyle cardTitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 22, color: color, weight: weight, height: 1.05);
  }

  static TextStyle cardSubtitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w600,
  }) {
    return _base(size: 14, color: color, weight: weight, height: 1.2);
  }

  static TextStyle cardMeta({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w600,
  }) {
    return _base(size: 13, color: color, weight: weight, height: 1.15);
  }

  static TextStyle cardDetail({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w600,
  }) {
    return _base(size: 12, color: color, weight: weight, height: 1.15);
  }

  static TextStyle cardButton({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 14, color: color, weight: weight, height: 1.1);
  }

  // =========================
  // Botones
  // =========================

  static TextStyle button({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 16, color: color, weight: weight, height: 1.1);
  }

  static TextStyle buttonLarge({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 18, color: color, weight: weight, height: 1.1);
  }

  static TextStyle buttonSecondary({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 14, color: color, weight: weight, height: 1.1);
  }

  // =========================
  // Chips / tabs / filtros
  // =========================

  static TextStyle chip({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 11, color: color, weight: weight, height: 1.05);
  }

  static TextStyle tabLabel({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 13, color: color, weight: weight, height: 1.1);
  }

  static TextStyle filterLabel({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 12, color: color, weight: weight, height: 1.1);
  }

  // =========================
  // Menú / ajustes
  // =========================

  static TextStyle menuTitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w900,
  }) {
    return _base(size: 36, color: color, weight: weight, height: 1.0);
  }

  static TextStyle menuOptionTitle({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 15, color: color, weight: weight, height: 1.15);
  }

  static TextStyle menuOptionDescription({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w500,
  }) {
    return _base(size: 13, color: color, weight: weight, height: 1.25);
  }

  // =========================
  // Navegación inferior
  // =========================

  static TextStyle navLabel({
    Color color = AppColors.SecondBlue,
    FontWeight weight = FontWeight.w800,
  }) {
    return _base(size: 10, color: color, weight: weight, height: 1.1);
  }

  // =========================
  // Base
  // =========================

  static TextStyle _base({
    required double size,
    required Color color,
    required FontWeight weight,
    double? height,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
    );
  }
}
