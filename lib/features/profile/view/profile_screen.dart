import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/model/user_role.dart';
import '../../../features/auth/view/sign_in_entry.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_menu_card.dart';

/// Profile tab — avatar, name, role badge, and settings menu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    final cubit = context.read<ProfileCubit>();

    return Scaffold(
      backgroundColor: AppColors.fieldFill,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              const _ProfileAvatar(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'tes test',
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleBadge(role: state.userRole.label),
              const SizedBox(height: AppSpacing.xl),
              ProfileMenuCard(
                darkMode: state.darkMode,
                onDarkModeToggle: cubit.toggleDarkMode,
                onEditProfile: state.userRole == UserRole.landlord
                    ? () => Navigator.of(context).pushNamed(AppRoutes.ownerProfile)
                    : () => Navigator.of(context).pushNamed(AppRoutes.tenantProfile),
                onEditPreferences: state.userRole == UserRole.landlord
                    ? () => Navigator.of(context).pushNamed(AppRoutes.ownerTopsis)
                    : () => Navigator.of(context).pushNamed(AppRoutes.editConstraints),
                onLogOut: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const SignInEntry()),
                  (route) => false,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'RentEase prototype · v1.0',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person, color: AppColors.onInk, size: 44),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.matchHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            role,
            style: AppTextStyles.label.copyWith(
              color: AppColors.accent,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
