import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'success_view.dart';

/// Standalone route that hosts [SuccessView] after the matching transition.
///
/// "Explore RentEase" clears the onboarding stack and lands the user on
/// their home shell.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({this.isOwner = false, super.key});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: SuccessView(
          isOwner: isOwner,
          onExplore: () => Navigator.of(context).pushNamedAndRemoveUntil(
            isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
            (_) => false,
          ),
        ),
      ),
    );
  }
}
