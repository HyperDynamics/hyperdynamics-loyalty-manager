import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Dark-first theme mirroring the Sterling design system used by the
/// original prototype — near-black canvas, mint primary accent.
class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgApp,
      fontFamily: AppTypography.fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgApp,
        primary: AppColors.mint400,
        onPrimary: AppColors.ink900,
        secondary: AppColors.gold400,
        onSecondary: AppColors.ink900,
        error: AppColors.loss,
        onError: AppColors.white,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: AppTypography.fontFamily,
      ),
      dividerColor: AppColors.borderSubtle,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElev,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.ink400),
      ),
    );
  }
}
