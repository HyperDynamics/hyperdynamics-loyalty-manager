import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type scale ported from `_ds/.../tokens/typography.css`.
/// Display sizes are heavy weight + tight tracking; body/UI text is lighter.
abstract final class AppTypography {
  static const fontFamily = 'Gilroy';

  static const _tight = -0.03;
  static const _snug = -0.015;

  static TextStyle _s({
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
    double? height,
    Color color = AppColors.textPrimary,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing * size,
    height: height,
    color: color,
  );

  // Marketing display scale
  static TextStyle hero = _s(size: 88, weight: FontWeight.w900, letterSpacing: _tight, height: 1.0);
  static TextStyle display = _s(size: 64, weight: FontWeight.w900, letterSpacing: _tight, height: 1.02);
  static TextStyle title1 = _s(size: 48, weight: FontWeight.w900, letterSpacing: _tight, height: 1.04);
  static TextStyle title2 = _s(size: 36, weight: FontWeight.w900, letterSpacing: _tight, height: 1.06);
  static TextStyle title3 = _s(size: 30, weight: FontWeight.w800, letterSpacing: _snug, height: 1.08);

  // In-app product scale
  static TextStyle h1 = _s(size: 28, weight: FontWeight.w900, letterSpacing: _tight, height: 1.1);
  static TextStyle h2 = _s(size: 24, weight: FontWeight.w800, letterSpacing: _snug, height: 1.15);
  static TextStyle h3 = _s(size: 20, weight: FontWeight.w800, letterSpacing: _snug, height: 1.2);
  static TextStyle lg = _s(size: 18, weight: FontWeight.w600, height: 1.35);
  static TextStyle body = _s(size: 16, weight: FontWeight.w500, height: 1.4);
  static TextStyle sm = _s(size: 14, weight: FontWeight.w500, height: 1.4, color: AppColors.textSecondary);
  static TextStyle xs = _s(size: 13, weight: FontWeight.w600, height: 1.35, color: AppColors.textTertiary);
  static TextStyle xs2 = _s(size: 11, weight: FontWeight.w700, height: 1.3, color: AppColors.textTertiary);

  static TextStyle overline = _s(
    size: 12,
    weight: FontWeight.w700,
    letterSpacing: 0.18,
    color: AppColors.mint400,
  );

  // Financial figures — tabular numerals
  static TextStyle figureXl = _s(size: 56, weight: FontWeight.w900, letterSpacing: _tight).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle figureLg = _s(size: 40, weight: FontWeight.w900, letterSpacing: _tight).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static TextStyle figureMd = _s(size: 28, weight: FontWeight.w800, letterSpacing: _snug).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle tabular(TextStyle base) =>
      base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
