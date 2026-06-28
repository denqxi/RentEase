import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../owner_onboarding/view/owner_topsis_screen.dart';

class EditOwnerTopsisScreen extends StatelessWidget {
  const EditOwnerTopsisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      appBar: AppBar(
        backgroundColor: context.appColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.appColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit tenant ranking',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: OwnerTopsisScreen(
          initialStay: 0.50,
          initialCredibility: 0.30,
          initialProfile: 0.20,
          onSave: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
