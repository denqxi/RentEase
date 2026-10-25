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
  static const Color accent = Color(0xFF1F7D8C);

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

  // ── Primary blue family — extracted from RentEase logo gradient ──────────
  static const Color primaryDeep = Color(0xFF1B5FA8);
  static const Color primaryMid  = Color(0xFF1A7BBF);
  static const Color primaryCyan = Color(0xFF19B4C4);
  static const Color primaryTeal = Color(0xFF1DB89A);

  // ── Tenant light fills ───────────────────────────────────────────────────
  static const Color tenantFillBlue = Color(0xFFE6F4FB);
  static const Color tenantFillCyan = Color(0xFFE0F7F6);

  // ── Owner purple ─────────────────────────────────────────────────────────
  static const Color ownerPrimary = Color(0xFF534AB7);
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

  // ── Admin ────────────────────────────────────────────────────────────────
  static const Color scrim = Color(0xFF000000);
  static const Color warningFill = Color(0xFFFEF3C7);
  static const Color guestWarnFill = Color(0xFFFFF5E6);
  static const Color guestWarnIcon = Color(0xFFDD6B20);
  static const Color placeholderSandA = Color(0xFFDBC59C);
  static const Color placeholderSandB = Color(0xFF8B6914);
  static const Color placeholderNavyA = Color(0xFF2C3E6B);
  static const Color placeholderNavyB = Color(0xFF0D1B3A);
  static const Color placeholderSkyA = Color(0xFFB0D4E0);
  static const Color placeholderSkyB = Color(0xFF5A9AB0);
  static const Color placeholderClayA = Color(0xFFCDAA8C);
  static const Color placeholderClayB = Color(0xFF8B6250);
  static const Color placeholderBlueA = Color(0xFF4AA8D8);
  static const Color placeholderBlueB = Color(0xFF1E5C8A);
  static const Color darkScaffold = Color(0xFF121212);
  static const Color darkAppBar = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF1E1E24);
  static const Color darkDivider = Color(0xFF404050);
  static const Color darkField = Color(0xFF2A2A36);
  static const Color darkSwitchTrack = Color(0xFF444444);
  static const Color accentOverlay = Color(0x201F7D8C);
  // ── Slate / utility tokens (used by shared widgets) ──────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color amber700 = Color(0xFFB45309);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color rose300 = Color(0xFFFDA4AF);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color skyFill = Color(0xFFE0F2FE);
  static const Color redFill50 = Color(0xFFFEF2F2);
  static const Color redFill100 = Color(0xFFFEE2E2);
  static const Color redBorder200 = Color(0xFFFECACA);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color amberFill50 = Color(0xFFFFFDF5);
  static const Color amberBorder200 = Color(0xFFFDE68A);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // Google "G" logo brand colors (sign-in button glyph only).
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color onboardingSky = Color(0xFFBDE8F5);
  static const Color onboardingDotInactive = Color(0xFFCBDFED);
  static const Color scrimStrong = Color(0xCC000000);
  static const Color scrimFaint = Color(0x16000000);

  // Tailwind-style utility tokens (owner / landlord screens).
  static const Color brandSky = Color(0xFF00A8F0);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald600 = Color(0xFF059669);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky300 = Color(0xFF7DD3FC);
  static const Color sky600 = Color(0xFF0284C7);
  static const Color sky700 = Color(0xFF0369A1);
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
    surface:           AppColors.surface,
    textPrimary:       AppColors.textPrimary,
    textSecondary:     AppColors.textSecondary,
    fieldBorder:       AppColors.fieldBorder,
    fieldFill:         AppColors.fieldFill,
    hint:              AppColors.hint,
    ink:               AppColors.ink,
    indicatorInactive: AppColors.indicatorInactive,
  );

  static const dark = AppAdaptiveColors(
    surface:           AppColors.darkCard,
    textPrimary:       Color(0xFFE4E4EF),
    textSecondary:     Color(0xFFA8A8B8),
    fieldBorder:       AppColors.darkDivider,
    fieldFill:         AppColors.darkField,
    hint:              AppColors.textSecondary,
    ink:               Color(0xFFE4E4EF),
    indicatorInactive: AppColors.darkDivider,
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
}
