import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final heading = GoogleFonts.plusJakartaSansTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);

    return base.copyWith(
      displayLarge: heading.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: heading.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: heading.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: heading.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: heading.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: heading.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: heading.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge,
      bodyMedium: body.bodyMedium,
      bodySmall: body.bodySmall,
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium,
      labelSmall: body.labelSmall,
    );
  }
}
