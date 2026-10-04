import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import 'preference_dropdown.dart';

/// The account holder's own gender — feeds the bilateral filter's Layer 1
/// GenderMatch (`FilteringService.computePropertySideScore`). Distinct from
/// a tenant's gender-*policy* requirement of a property, which is collected
/// later in onboarding.
///
/// Presented as a dropdown ([PreferenceDropdown]) to match the rest of the
/// registration form.
class GenderSelectField extends StatelessWidget {
  const GenderSelectField({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  static const _options = <String>['Female', 'Male'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PreferenceDropdown(
          label: 'Gender',
          value: value.isEmpty ? null : value,
          hint: 'Select gender',
          items: _options,
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}
