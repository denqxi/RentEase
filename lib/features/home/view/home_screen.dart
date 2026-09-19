import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../registration/model/user_role.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_section.dart';
import '../widgets/recommended_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<ProfileCubit, bool>(
      (c) => c.state.userRole == UserRole.guest,
    );

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: HomeHeader(
                userName:
                    isGuest ? MockData.guestDisplayName : MockData.tenantName,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.sm),
            ),
            const SliverToBoxAdapter(child: RecommendedSection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: NearbySection()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}
