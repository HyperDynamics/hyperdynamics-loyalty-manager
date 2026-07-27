/// Spacing / radius scale ported from `_ds/.../tokens/spacing.css`.
abstract final class AppSpacing {
  static const s0 = 0.0;
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
  static const s12 = 48.0;
  static const s16 = 64.0;
  static const s20 = 80.0;
  static const s24 = 96.0;
  static const s32 = 128.0;

  static const containerMax = 1200.0;
  static const gutter = 24.0;
  static const sectionPadY = 120.0;

  /// Breakpoint used by the prototype to switch sidebar (wide) vs bottom tab bar (narrow).
  static const wideBreakpoint = 860.0;
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xl2 = 36.0;
  static const pill = 999.0;
  static const cardFace = 18.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 120);
  static const quick = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}
