import 'package:flutter/material.dart';

/// Color ramp ported 1:1 from the Sterling design system tokens
/// (`_ds/.../tokens/colors.css`) that the original prototype was styled with.
abstract final class AppColors {
  // Ink / canvas ramp
  static const ink900 = Color(0xFF08090B);
  static const ink800 = Color(0xFF0B0C0F);
  static const ink700 = Color(0xFF101216);
  static const ink600 = Color(0xFF16181E);
  static const ink500 = Color(0xFF1D2027);
  static const ink400 = Color(0xFF262A33);
  static const ink300 = Color(0xFF333844);
  static const ink200 = Color(0xFF454B59);

  static const white = Color(0xFFFFFFFF);
  static const paper = Color(0xFFF8F8F8);
  static const paperDim = Color(0xFFC6C9D1);
  static const paperMute = Color(0xFF8A8F9C);
  static const paperFaint = Color(0xFF5B606D);

  // Mint — the money / growth / go accent
  static const mint50 = Color(0xFFE6FFF6);
  static const mint300 = Color(0xFF5FF3C0);
  static const mint400 = Color(0xFF22E6A4);
  static const mint500 = Color(0xFF00D492);
  static const mint600 = Color(0xFF04B57C);
  static const mint700 = Color(0xFF027757);
  static const mintGlow = Color(0x7322E6A4);

  // Gold — premium / rewards
  static const gold200 = Color(0xFFF7E6B8);
  static const gold400 = Color(0xFFE8C87E);
  static const gold500 = Color(0xFFD4AF58);
  static const gold600 = Color(0xFFA9843A);
  static const goldGlow = Color(0x66E8C87E);

  static const blue400 = Color(0xFF4D86F0);
  static const blue500 = Color(0xFF1A61E9);
  static const linkBlue = Color(0xFF7EA2EC);
  static const purple500 = Color(0xFF5A1ECB);
  static const violet400 = Color(0xFF8B6BF2);

  // Finance semantics
  static const gain = mint400;
  static const gainDim = Color(0xFF0F5F45);
  static const loss = Color(0xFFEE2F4C);
  static const lossDim = Color(0xFF5E1622);
  static const warn = Color(0xFFF5A524);
  static const warnDim = Color(0xFF5A3D0C);
  static const info = blue400;

  // Surfaces
  static const bgApp = ink800;
  static const bgRaised = ink700;
  static const surfaceCard = ink600;
  static const surfaceElev = ink500;
  static const surfaceHover = ink400;
  static const surfaceInput = ink400;

  // Text
  static const textPrimary = paper;
  static const textSecondary = paperDim;
  static const textTertiary = paperMute;
  static const textDisabled = paperFaint;
  static const textInverse = ink900;
  static const textLink = linkBlue;

  // Accent
  static const accent = mint400;
  static const accentStrong = mint500;
  static const accentDeep = mint700;
  static const onAccent = ink900;

  // Borders
  static const borderSubtle = Color(0x0FFFFFFF);
  static const borderSoft = Color(0x1AFFFFFF);
  static const borderStrong = Color(0x29FFFFFF);
  static const borderAccent = mint500;

  static const glassFill = Color(0x8C1C2028);
  static const glassBorder = Color(0x1FFFFFFF);
}
