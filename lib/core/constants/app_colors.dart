import 'package:flutter/material.dart';

/// App-wide color tokens.
///
/// Never hardcode colors inline in widgets — reference these tokens instead.
abstract final class AppColors {
  /// Brand teal, used for accents and the active page indicator.
  static const Color primary = Color(0xFF1ABCCE);

  /// Near-black ink used for primary buttons and headings.
  static const Color ink = Color(0xFF1A1A2E);

  /// Default surface / card background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary body text.
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Muted secondary text (subtitles, hints).
  static const Color textSecondary = Color(0xFF7A7A8C);

  /// Inactive page-indicator dots and subtle dividers.
  static const Color indicatorInactive = Color(0xFFD9D9E0);

  /// On-dark text (e.g. label inside the ink button).
  static const Color onInk = Color(0xFFFFFFFF);

  /// Selected / active teal used for chips, toggles, slider and progress.
  static const Color accent = Color(0xFF19A2C1);

  /// Soft teal-grey background (success ring, match card).
  static const Color accentSoft = Color(0xFFEAF1F2);

  /// Fill color for input fields and unselected segmented controls.
  static const Color fieldFill = Color(0xFFF2F3F5);

  /// Hairline border for fields, cards and chips.
  static const Color fieldBorder = Color(0xFFE3E5E9);

  /// Placeholder / hint text inside fields.
  static const Color hint = Color(0xFFA0A3AD);

  /// Green dot for high match scores (≥ 80%).
  static const Color matchHigh = Color(0xFF22C55E);

  /// Amber dot for medium match scores (< 80%).
  static const Color matchMedium = Color(0xFFF59E0B);

  /// Red used for destructive actions (log out, delete).
  static const Color destructive = Color(0xFFEF4444);

  /// Blue dot marking unread activity items.
  static const Color unread = Color(0xFF3B82F6);

  // ── Convenience aliases used by new screens ──────────────────────────────
  /// Alias for [fieldBorder] — hairline borders on cards and chips.
  static const Color border = Color(0xFFE3E5E9);

  /// Alias for [hint] — placeholder / hint text inside fields.
  static const Color textHint = Color(0xFFA0A3AD);

  /// Alias for [fieldFill] — fill color for input fields and unselected controls.
  static const Color fieldBg = Color(0xFFF2F3F5);

  /// Muted gray for disabled buttons and inactive elements.
  static const Color disabled = Color(0xFFBDBDBD);

  // ── Primary blue family — extracted from RentEase logo gradient ──────────
  static const Color primaryDeep = Color(0xFF1B5FA8);
  static const Color primaryMid  = Color(0xFF1A7BBF);
  static const Color primaryCyan = Color(0xFF19B4C4);
  static const Color primaryTeal = Color(0xFF1DB89A);

  // ── Tenant light fills ───────────────────────────────────────────────────
  static const Color tenantFillBlue = Color(0xFFE6F4FB);
  static const Color tenantFillCyan = Color(0xFFE0F7F6);
  static const Color tenantFillTeal = Color(0xFFEBF8F5);

  // ── Tenant dark text on light fills ─────────────────────────────────────
  static const Color tenantTextDeep = Color(0xFF0C3D6E);
  static const Color tenantTextCyan = Color(0xFF085A5E);
  static const Color tenantTextTeal = Color(0xFF085041);

  // ── Owner purple ─────────────────────────────────────────────────────────
  static const Color ownerPrimary = Color(0xFF534AB7);
  static const Color ownerDark    = Color(0xFF3C3489);
  static const Color ownerFill    = Color(0xFFEEEDFE);
  static const Color ownerText    = Color(0xFF26215C);

  // ── Amber — session overrides and warnings only ──────────────────────────
  static const Color amberPrimary = Color(0xFFBA7517);
  static const Color amberBorder  = Color(0xFFEF9F27);
  static const Color amberFill    = Color(0xFFFAEEDA);
  static const Color amberText    = Color(0xFF412402);

  // ── Green — compatible and qualified states only ─────────────────────────
  static const Color greenPrimary = Color(0xFF3B6D11);
  static const Color greenFill    = Color(0xFFEAF3DE);
  static const Color greenText    = Color(0xFF27500A);

  // ── Red — danger and decline only ───────────────────────────────────────
  static const Color redPrimary = Color(0xFFA32D2D);
  static const Color redFill    = Color(0xFFFCEBEB);
  static const Color redText    = Color(0xFF791F1F);

  // ── Admin ────────────────────────────────────────────────────────────────
  static const Color adminNavy = Color(0xFF1A1A2E);
<<<<<<< Updated upstream
=======
}

/// Theme-adaptive color tokens that flip between light and dark values.
///
/// Access via [BuildContext.appColors] inside any widget build method.
/// Light values exactly match the corresponding [AppColors] constants so
/// existing light-mode appearance is unchanged.
class AppAdaptiveColors extends ThemeExtension<AppAdaptiveColors> {
  const AppAdaptiveColors({
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.fieldBorder,
    required this.fieldFill,
    required this.hint,
    required this.ink,
    required this.indicatorInactive,
  });

  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color fieldBorder;
  final Color fieldFill;
  final Color hint;
  final Color ink;
  final Color indicatorInactive;

  static const light = AppAdaptiveColors(
    surface:           Color(0xFFFFFFFF),
    textPrimary:       Color(0xFF1A1A2E),
    textSecondary:     Color(0xFF7A7A8C),
    fieldBorder:       Color(0xFFE3E5E9),
    fieldFill:         Color(0xFFF2F3F5),
    hint:              Color(0xFFA0A3AD),
    ink:               Color(0xFF1A1A2E),
    indicatorInactive: Color(0xFFD9D9E0),
  );

  static const dark = AppAdaptiveColors(
    surface:           Color(0xFF1E1E24),
    textPrimary:       Color(0xFFE4E4EF),
    textSecondary:     Color(0xFFA8A8B8),
    fieldBorder:       Color(0xFF404050),
    fieldFill:         Color(0xFF2A2A36),
    hint:              Color(0xFF7A7A8C),
    ink:               Color(0xFFE4E4EF),
    indicatorInactive: Color(0xFF404050),
  );

  @override
  AppAdaptiveColors copyWith({
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? fieldBorder,
    Color? fieldFill,
    Color? hint,
    Color? ink,
    Color? indicatorInactive,
  }) => AppAdaptiveColors(
    surface:           surface           ?? this.surface,
    textPrimary:       textPrimary       ?? this.textPrimary,
    textSecondary:     textSecondary     ?? this.textSecondary,
    fieldBorder:       fieldBorder       ?? this.fieldBorder,
    fieldFill:         fieldFill         ?? this.fieldFill,
    hint:              hint              ?? this.hint,
    ink:               ink               ?? this.ink,
    indicatorInactive: indicatorInactive ?? this.indicatorInactive,
  );

  @override
  AppAdaptiveColors lerp(ThemeExtension<AppAdaptiveColors>? other, double t) {
    if (other is! AppAdaptiveColors) return this;
    return AppAdaptiveColors(
      surface:           Color.lerp(surface,           other.surface,           t)!,
      textPrimary:       Color.lerp(textPrimary,       other.textPrimary,       t)!,
      textSecondary:     Color.lerp(textSecondary,     other.textSecondary,     t)!,
      fieldBorder:       Color.lerp(fieldBorder,       other.fieldBorder,       t)!,
      fieldFill:         Color.lerp(fieldFill,         other.fieldFill,         t)!,
      hint:              Color.lerp(hint,              other.hint,              t)!,
      ink:               Color.lerp(ink,               other.ink,               t)!,
      indicatorInactive: Color.lerp(indicatorInactive, other.indicatorInactive, t)!,
    );
  }
}

extension AppAdaptiveColorsX on BuildContext {
  AppAdaptiveColors get appColors =>
      Theme.of(this).extension<AppAdaptiveColors>()!;
>>>>>>> Stashed changes
}
