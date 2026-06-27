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
}
