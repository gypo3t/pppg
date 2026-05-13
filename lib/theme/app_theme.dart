import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.black87,
          error: AppColors.error,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navBar,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shadowColor: AppColors.cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.cardDivider,
          space: 1,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primaryBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primaryBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.12),
          inactiveTrackColor: AppColors.primaryBorder.withValues(alpha: 0.4),
        ),
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) => states
                  .contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grey300),
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.grey),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(
                color: AppColors.primaryBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.cardBorder,
        ),
        textTheme: const TextTheme(
          // Grandes valeurs (stats)
          displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.black87,
          ),
          // Titre d'écran / section importante
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black87,
          ),
          // Titre de carte / widget
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black87,
          ),
          // Sous-titre / label secondaire
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.black54,
          ),
          // Corps principal
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.black87),
          bodySmall: TextStyle(fontSize: 13, color: AppColors.black87),
          // Chips, badges, petits labels
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black87,
          ),
          labelMedium: TextStyle(fontSize: 12, color: AppColors.black87),
          // En-têtes colonnes, mentions légales
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.primary,
          ),
        ),
      );
}
