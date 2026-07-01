import 'package:flutter/material.dart';


abstract final class AppColors {
  static const Color brandPrimary = Color(0xFF0B6E4F); // emerald
  static const Color brandPrimaryDark = Color(0xFF0A8F63);
  static const Color brandSecondary = Color(0xFF1B4965); // deep blue
  static const Color brandAccent = Color(0xFFE0A338); // gold

  static const Color credit = Color(0xFF1E9E6A); // money in
  static const Color debit = Color(0xFFD64545); // money out
  static const Color warning = Color(0xFFE0A338);
  static const Color info = Color(0xFF2E7DAF);

  static const Color riskLow = Color(0xFF1E9E6A);
  static const Color riskModerate = Color(0xFFE0A338);
  static const Color riskHigh = Color(0xFFD64545);

  static const Color lightBackground = Color(0xFFF6F8F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDF1EF);
  static const Color lightOutline = Color(0xFFD3DAD7);

  static const Color darkBackground = Color(0xFF0E1513);
  static const Color darkSurface = Color(0xFF151E1B);
  static const Color darkSurfaceVariant = Color(0xFF1E2A26);
  static const Color darkOutline = Color(0xFF38453F);

  static Color riskColor(double score) {
    if (score < 34) return riskLow;
    if (score < 67) return riskModerate;
    return riskHigh;
  }
}
