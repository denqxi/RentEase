import 'package:flutter/services.dart';

/// Auto-formats names to Title Case on every keystroke and strictly rejects
/// any numeric inputs (0–9).
///
/// Example:
/// - "ivan" -> "Ivan"
/// - "ivan josh" -> "Ivan Josh"
/// - "ivan JOSH" -> "Ivan Josh"
/// - "ivan123" -> "Ivan" (numbers rejected)
class TitleCaseNameFormatter extends TextInputFormatter {
  const TitleCaseNameFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final rawText = newValue.text;
    final buffer = StringBuffer();
    int newSelectionIndex = newValue.selection.baseOffset;

    for (int i = 0; i < rawText.length; i++) {
      final char = rawText[i];
      if (char.contains(RegExp(r'[0-9]'))) {
        if (i < newValue.selection.baseOffset) {
          newSelectionIndex--;
        }
      } else {
        buffer.write(char);
      }
    }

    final strippedText = buffer.toString();
    final capitalizedText = strippedText.splitMapJoin(
      RegExp(r'[a-zA-Z]+'),
      onMatch: (m) {
        final word = m.group(0)!;
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      },
      onNonMatch: (n) => n,
    );

    newSelectionIndex = newSelectionIndex.clamp(0, capitalizedText.length);

    return TextEditingValue(
      text: capitalizedText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
  }
}

/// Auto-formats Philippine mobile numbers into the format "9XX XXX XXXX".
///
/// Strips leading "0" or country code "63" so user only needs to type the
/// 10 digits starting with 9.
///
/// Example:
/// - Typing "09347346347" becomes "934 734 6347"
/// - Accompanied by "+63 " prefix, displays as "+63 934 734 6347"
class PhilippinePhoneInputFormatter extends TextInputFormatter {
  const PhilippinePhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Strip country code if pasted (63)
    if (digits.startsWith('63') && digits.length > 2) {
      digits = digits.substring(2);
    }
    // Strip leading 0 if typed/pasted (e.g., 09xx)
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Limit to 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    // Calculate cursor position
    int digitsBeforeCursor = 0;
    for (int i = 0;
        i < newValue.selection.baseOffset && i < newValue.text.length;
        i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (rawDigits.startsWith('63') && rawDigits.length > 2) {
      digitsBeforeCursor = (digitsBeforeCursor - 2).clamp(0, digits.length);
    } else if (rawDigits.startsWith('0')) {
      digitsBeforeCursor = (digitsBeforeCursor - 1).clamp(0, digits.length);
    }

    int newOffset = 0;
    int countedDigits = 0;
    while (newOffset < formatted.length && countedDigits < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[newOffset])) {
        countedDigits++;
      }
      newOffset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
