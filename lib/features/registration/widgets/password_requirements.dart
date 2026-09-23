import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';

/// Live password-requirements checklist shown under the password field on
/// both the tenant and landlord account steps. Each rule flips to a green
/// check as the typed password satisfies it.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({required this.password, super.key});

  final String password;

  /// Delegates to [Validators.password] so the checklist and the actual
  /// submit-time gate can never drift apart.
  static bool isSatisfied(String password) =>
      Validators.password(password) == null;

  static final List<_Rule> _rules = [
    _Rule('12–16 characters', (p) => p.length >= 12 && p.length <= 16),
    _Rule('At least one uppercase letter (A–Z)',
        (p) => p.contains(RegExp(r'[A-Z]'))),
    _Rule('At least one lowercase letter (a–z)',
        (p) => p.contains(RegExp(r'[a-z]'))),
    _Rule('At least one number (0–9)', (p) => p.contains(RegExp(r'[0-9]'))),
    _Rule('At least one special character (!@#\$%…)',
        (p) => p.contains(RegExp(r'[^A-Za-z0-9]'))),
  ];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in _rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  rule.test(password)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 14,
                  color: rule.test(password)
                      ? AppColors.matchHigh
                      : context.appColors.hint,
                ),
                const SizedBox(width: 6),
                Text(
                  rule.label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: rule.test(password)
                        ? context.appColors.textPrimary
                        : context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Rule {
  const _Rule(this.label, this.test);

  final String label;
  final bool Function(String) test;
}
