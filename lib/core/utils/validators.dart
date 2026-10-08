/// Shared field validators for forms across the app (currently the
/// registration account steps). Each function returns `null` when the value
/// is valid, or a user-facing error message otherwise — the shape
/// `TextFormField.validator` expects, though these are also called directly
/// wherever a screen manages its own error text.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');


  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required.';
    final digitsOnly = trimmed.replaceAll(RegExp(r'[\s-]'), '');
    String national = digitsOnly;
    if (national.startsWith('+63')) {
      national = national.substring(3);
    } else if (national.startsWith('63')) {
      national = national.substring(2);
    } else if (national.startsWith('0')) {
      national = national.substring(1);
    }
    if (national.isEmpty || !national.startsWith('9') || national.length != 10) {
      return 'Invalid number (e.g., 9XX XXX XXXX)';
    }
    return null;
  }

  /// Mirrors [PasswordRequirements]'s checklist so the same rule set backs
  /// both the live UI hints and the actual submit-time gate.
  static String? password(String? value) {
    final p = value ?? '';
    if (p.isEmpty) return 'Password is required.';
    if (p.length < 12 || p.length > 16) {
      return 'Password must be 12–16 characters.';
    }
    if (!p.contains(RegExp(r'[A-Z]'))) {
      return 'Add at least one uppercase letter.';
    }
    if (!p.contains(RegExp(r'[a-z]'))) {
      return 'Add at least one lowercase letter.';
    }
    if (!p.contains(RegExp(r'[0-9]'))) {
      return 'Add at least one number.';
    }
    if (!p.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Add at least one special character.';
    }
    return null;
  }
}
