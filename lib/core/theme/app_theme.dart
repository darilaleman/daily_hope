import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.cardBackground,
        ),
        textTheme: GoogleFonts.playfairDisplayTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              color: AppColors.textDark,
              fontStyle: FontStyle.italic,
            ),
            bodyLarge: TextStyle(
              fontSize: 18,
              color: AppColors.textDark,
              height: 1.6,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primary),
          titleTextStyle: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 24,
            color: AppColors.textDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
