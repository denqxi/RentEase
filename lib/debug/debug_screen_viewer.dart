// Temporary dev tool — not part of the app's real navigation. Lists every
// screen so you can jump straight to one instead of walking the real flow
// (sign in, onboard, etc.) each time. Delete this file and its splash-screen
// hook (see app.dart) once it's no longer needed.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/mock_data.dart';
import '../features/activity/cubit/activity_cubit.dart';
import '../features/activity/model/activity_item.dart';
import '../features/activity/view/activity_screen.dart';
import '../features/admin/view/admin_login_screen.dart';
import '../features/admin/view/analytics_screen.dart';
import '../features/admin/view/pending_verifications_screen.dart';
import '../features/admin/view/property_management_screen.dart';
import '../features/admin/view/user_management_screen.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/home/model/listing_detail.dart';
import '../features/home/view/home_screen.dart';
import '../features/home/view/listing_detail_screen.dart';
import '../features/home/view/property_detail_screen.dart';
import '../features/home/view/search_screen.dart';
import '../features/inquiry/view/tenant_inquiries_screen.dart';
import '../features/landlord_home/cubit/landlord_home_cubit.dart';
import '../features/landlord_home/model/tenant_detail.dart';
import '../features/landlord_home/view/landlord_home_screen.dart';
import '../features/landlord_home/view/tenant_detail_screen.dart';
import '../features/landlord_matches/view/landlord_matches_screen.dart';
import '../features/matching/data/repositories/filtering_repository_impl.dart';
import '../features/matching/data/repositories/topsis_repository_impl.dart';
import '../features/matching/domain/services/filtering_service.dart';
import '../features/matching/domain/services/topsis_service.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/owner/view/find_tenants_screen.dart';
import '../features/owner/view/owner_inquiries_screen.dart';
import '../features/owner/view/owner_properties_screen.dart';
import '../features/owner_onboarding/view/add_property_screen.dart';
import '../features/owner_onboarding/view/document_upload_screen.dart';
import '../features/owner_onboarding/view/pricing_amenities_screen.dart';
import '../features/owner_onboarding/view/property_rules_screen.dart';
import '../features/owner_onboarding/view/verification_pending_screen.dart';
import '../features/profile/cubit/profile_cubit.dart';
import '../features/profile/view/edit_constraints_screen.dart';
import '../features/profile/view/edit_topsis_screen.dart';
import '../features/profile/view/owner_profile_screen.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/profile/view/saved_screen.dart';
import '../features/registration/model/user_role.dart';
import '../features/resolution/view/rating_screen.dart';
import '../features/tenant_onboarding/view/distance_preference_screen.dart';
import '../features/tenant_onboarding/view/hard_constraints_screen.dart';
import '../features/tenant_onboarding/view/poi_setup_screen.dart';
import '../features/tenant_onboarding/view/topsis_weight_screen.dart';

HomeCubit _previewHomeCubit() => HomeCubit(
  tenantId: 'preview',
  repository: HomeRepositoryImpl(),
  filteringService: FilteringService(repository: FilteringRepositoryImpl()),
  topsisService: TopsisService(repository: TopsisRepositoryImpl()),
);

class _Entry {
  const _Entry(this.label, this.builder);
  final String label;
  final WidgetBuilder builder;
}

class _Section {
  const _Section(this.title, this.entries);
  final String title;
  final List<_Entry> entries;
}

/// Reachable in debug builds only — see [SplashScreen]'s long-press hook.
class DebugScreenViewer extends StatelessWidget {
  const DebugScreenViewer({super.key});

  static List<_Section> _sections() {
    final property = MockData.properties[0];

    return [
      _Section('Auth / onboarding (shared)', [
        _Entry('Onboarding intro', (_) => OnboardingScreen(onComplete: () {})),
        _Entry('Sign in', (_) => const SignInScreen()),
        _Entry('Role selection', (_) => const RoleSelectionScreen()),
        _Entry('Sign up (tenant)', (_) => const SignupScreen(isOwner: false)),
        _Entry('Sign up (owner)', (_) => const SignupScreen(isOwner: true)),
        _Entry(
          'Email verification',
          (_) => const EmailVerificationScreen(isOwner: false),
        ),
        _Entry('Admin login', (_) => const AdminLoginScreen()),
      ]),
      _Section('Tenant onboarding', [
        _Entry('1. Hard constraints', (_) => const HardConstraintsScreen()),
        _Entry('2. POI setup', (_) => const PoiSetupScreen()),
        _Entry(
          '3. Distance preference',
          (_) => const DistancePreferenceScreen(
            poiName: 'University of Southeastern Philippines',
          ),
        ),
        _Entry('4. TOPSIS weight', (_) => const TopsisWeightScreen()),
      ]),
      _Section('Owner onboarding', [
        _Entry('1. Document upload', (_) => const DocumentUploadScreen()),
        _Entry(
          '   Verification pending',
          (_) => const VerificationPendingScreen(),
        ),
        _Entry('2. Add property', (_) => const AddPropertyScreen()),
        _Entry('3. Property rules', (_) => const PropertyRulesScreen()),
        _Entry(
          '4. Pricing & amenities (final step)',
          (_) => const PricingAmenitiesScreen(),
        ),
      ]),
      _Section('Tenant app', [
        _Entry(
          'Home',
          (_) => BlocProvider<HomeCubit>(
            create: (_) => _previewHomeCubit(),
            child: const HomeScreen(),
          ),
        ),
        _Entry(
          'Search',
          (_) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>(create: (_) => _previewHomeCubit()),
              BlocProvider<ProfileCubit>(
                create: (_) => ProfileCubit(userRole: UserRole.tenant),
              ),
            ],
            child: const SearchScreen(),
          ),
        ),
        _Entry(
          'Property detail',
          (_) => PropertyDetailScreen(property: property),
        ),
        _Entry(
          'Listing detail',
          (_) => const ListingDetailScreen(detail: ListingDetail.sample),
        ),
        _Entry('Inquiries', (_) => const TenantInquiriesScreen()),
        _Entry(
          'Activity / alerts',
          (_) => BlocProvider<ActivityCubit>(
            create: (_) => ActivityCubit(initialItems: ActivityItem.samples),
            child: const ActivityScreen(),
          ),
        ),
        _Entry(
          'Profile',
          (_) => MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>(create: (_) => _previewHomeCubit()),
              BlocProvider<ProfileCubit>(
                create: (_) => ProfileCubit(userRole: UserRole.tenant),
              ),
            ],
            child: const ProfileScreen(),
          ),
        ),
        _Entry(
          'Saved',
          (_) => BlocProvider<HomeCubit>(
            create: (_) => _previewHomeCubit(),
            child: const SavedScreen(),
          ),
        ),
        _Entry('Edit constraints', (_) => const EditConstraintsScreen()),
        _Entry('Edit TOPSIS weights', (_) => const EditTopsisScreen()),
        _Entry('Rating', (_) => const RatingScreen()),
      ]),
      _Section('Owner app', [
        _Entry(
          'Home',
          (_) => BlocProvider<LandlordHomeCubit>(
            create: (_) => LandlordHomeCubit(),
            child: const LandlordHomeScreen(),
          ),
        ),
        _Entry(
          'Matches',
          (_) => BlocProvider<LandlordHomeCubit>(
            create: (_) => LandlordHomeCubit(),
            child: const LandlordMatchesScreen(),
          ),
        ),
        _Entry(
          'Tenant detail',
          (_) => const TenantDetailScreen(detail: TenantDetail.sample),
        ),
        _Entry('Find tenants', (_) => const FindTenantsScreen()),
        _Entry('Properties', (_) => const OwnerPropertiesScreen()),
        _Entry('Inquiries', (_) => const OwnerInquiriesScreen()),
        _Entry(
          'Activity / alerts',
          (_) => BlocProvider<ActivityCubit>(
            create: (_) =>
                ActivityCubit(initialItems: ActivityItem.landlordSamples),
            child: const ActivityScreen(),
          ),
        ),
        _Entry(
          'Profile',
          (_) => MultiBlocProvider(
            providers: [
              BlocProvider<LandlordHomeCubit>(
                create: (_) => LandlordHomeCubit(),
              ),
              BlocProvider<ProfileCubit>(
                create: (_) => ProfileCubit(userRole: UserRole.landlord),
              ),
            ],
            child: const OwnerProfileScreen(),
          ),
        ),
      ]),
      _Section('Admin', [
        _Entry(
          'Pending verifications',
          (_) => const PendingVerificationsScreen(),
        ),
        _Entry('User management', (_) => const UserManagementScreen()),
        _Entry('Property management', (_) => const PropertyManagementScreen()),
        _Entry('Analytics', (_) => const AnalyticsScreen()),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        title: const Text('Debug: screen viewer'),
      ),
      body: ListView(
        children: [
          for (final section in sections) ...[
            Container(
              width: double.infinity,
              color: AppColors.accentSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                section.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            for (final entry in section.entries)
              ListTile(
                title: Text(entry.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: entry.builder)),
              ),
          ],
        ],
      ),
    );
  }
}
