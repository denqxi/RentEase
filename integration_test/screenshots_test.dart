// On-device screenshot harness — pumps every reachable screen with
// representative mock data on the emulator and captures real device
// screenshots (real fonts, real OSM map tiles). Run with:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d emulator-5554
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rentease/core/constants/mock_data.dart';
import 'package:rentease/core/theme/app_theme.dart';

import 'package:rentease/features/activity/cubit/activity_cubit.dart';
import 'package:rentease/features/activity/model/activity_item.dart';
import 'package:rentease/features/activity/view/activity_screen.dart';
import 'package:rentease/features/admin/view/admin_login_screen.dart';
import 'package:rentease/features/admin/view/analytics_screen.dart';
import 'package:rentease/features/admin/view/pending_verifications_screen.dart';
import 'package:rentease/features/admin/view/property_management_screen.dart';
import 'package:rentease/features/admin/view/user_management_screen.dart';
import 'package:rentease/features/auth/presentation/screens/auth_screen.dart';
import 'package:rentease/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:rentease/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:rentease/features/auth/presentation/screens/signup_screen.dart';
import 'package:rentease/features/auth/presentation/screens/splash_screen.dart';
import 'package:rentease/features/home/cubit/home_cubit.dart';
import 'package:rentease/features/home/model/listing_detail.dart';
import 'package:rentease/features/home/view/home_screen.dart';
import 'package:rentease/features/home/view/listing_detail_screen.dart';
import 'package:rentease/features/home/view/map_view_screen.dart';
import 'package:rentease/features/home/view/property_detail_screen.dart';
import 'package:rentease/features/home/view/search_screen.dart';
import 'package:rentease/features/inquiry/view/phase1_tenant_screen.dart';
import 'package:rentease/features/inquiry/view/phase2_tenant_screen.dart';
import 'package:rentease/features/inquiry/view/tenant_inquiries_screen.dart';
import 'package:rentease/features/landlord_home/cubit/landlord_home_cubit.dart';
import 'package:rentease/features/landlord_home/model/tenant_detail.dart';
import 'package:rentease/features/landlord_home/view/landlord_home_screen.dart';
import 'package:rentease/features/landlord_home/view/tenant_detail_screen.dart';
import 'package:rentease/features/landlord_matches/view/landlord_matches_screen.dart';
import 'package:rentease/features/landlord_saved/view/landlord_saved_screen.dart';
import 'package:rentease/features/onboarding/view/onboarding_screen.dart';
import 'package:rentease/features/owner/view/edit_owner_topsis_screen.dart';
import 'package:rentease/features/owner/view/edit_property_screen.dart';
import 'package:rentease/features/owner/view/find_tenants_screen.dart';
import 'package:rentease/features/owner/view/owner_inquiries_screen.dart';
import 'package:rentease/features/owner/view/owner_properties_screen.dart';
import 'package:rentease/features/owner/view/phase1_owner_screen.dart';
import 'package:rentease/features/owner/view/phase2_chat_owner_screen.dart';
import 'package:rentease/features/owner_onboarding/view/add_property_screen.dart';
import 'package:rentease/features/owner_onboarding/view/document_upload_screen.dart';
import 'package:rentease/features/owner_onboarding/view/owner_topsis_screen.dart';
import 'package:rentease/features/owner_onboarding/view/pricing_amenities_screen.dart';
import 'package:rentease/features/owner_onboarding/view/property_rules_screen.dart';
import 'package:rentease/features/owner_onboarding/view/verification_pending_screen.dart';
import 'package:rentease/features/profile/cubit/profile_cubit.dart';
import 'package:rentease/features/profile/view/edit_constraints_screen.dart';
import 'package:rentease/features/profile/view/edit_topsis_screen.dart';
import 'package:rentease/features/profile/view/owner_profile_screen.dart';
import 'package:rentease/features/profile/view/profile_screen.dart';
import 'package:rentease/features/profile/view/saved_screen.dart';
import 'package:rentease/features/profile/view/soft_preferences_screen.dart';
import 'package:rentease/features/registration/model/user_role.dart';
import 'package:rentease/features/registration/view/registration_flow_screen.dart';
import 'package:rentease/features/resolution/view/rating_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/distance_preference_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/hard_constraints_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/poi_setup_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/soft_preferences_step_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/topsis_weight_screen.dart';

late IntegrationTestWidgetsFlutterBinding _binding;
final List<String> _failures = <String>[];

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child, {
  // Map screens need real time for OSM tiles to download and paint.
  int settleSeconds = 1,
}) async {
  try {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: child,
      ),
    );
    final deadline = DateTime.now().add(Duration(seconds: settleSeconds));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await _binding.takeScreenshot(name);
    // ignore: avoid_print
    print('captured $name');
  } catch (e) {
    _failures.add('$name: $e');
    // ignore: avoid_print
    print('FAILED $name: $e');
  }
}

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture all screens on device', (tester) async {
    final property = MockData.properties[0];
    final ownerInquiry = MockData.ownerInquiries[0];

    // Required once on Android before takeScreenshot can work.
    if (Platform.isAndroid) {
      await _binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }

    // ── Auth / onboarding (shared) ──────────────────────────────
    await _capture(tester, '00_splash', SplashScreen(onComplete: () {}));
    await _capture(
        tester, '01_onboarding', OnboardingScreen(onComplete: () {}));
    await _capture(tester, '02_sign_in', const SignInScreen());
    await _capture(tester, '03_role_selection', const RoleSelectionScreen());
    await _capture(
        tester, '04_signup_tenant', const SignupScreen(isOwner: false));
    await _capture(
        tester, '05_signup_owner', const SignupScreen(isOwner: true));
    await _capture(tester, '06_email_verification',
        const EmailVerificationScreen(isOwner: false));
    await _capture(tester, '07_registration_flow',
        RegistrationFlowScreen(onComplete: (_) {}, onSignIn: () {}));

    // ── Tenant onboarding (5 steps) ──────────────────────────────
    await _capture(tester, '10_tenant_onboarding_1_hard_constraints',
        const HardConstraintsScreen());
    await _capture(tester, '11_tenant_onboarding_2_soft_preferences',
        const SoftPreferencesStepScreen());
    await _capture(tester, '12_tenant_onboarding_3_poi_setup',
        const PoiSetupScreen(), settleSeconds: 6);
    await _capture(
        tester,
        '13_tenant_onboarding_4_distance_preference',
        const DistancePreferenceScreen(
            poiName: 'University of Southeastern Philippines'));
    await _capture(tester, '14_tenant_onboarding_5_topsis_weight',
        const TopsisWeightScreen());

    // ── Owner onboarding ─────────────────────────────────────────
    await _capture(tester, '20_owner_onboarding_1_document_upload',
        const DocumentUploadScreen());
    await _capture(tester, '21_owner_onboarding_verification_pending',
        const VerificationPendingScreen());
    await _capture(tester, '22_owner_onboarding_2_add_property',
        const AddPropertyScreen(), settleSeconds: 6);
    await _capture(tester, '23_owner_onboarding_3_property_rules',
        const PropertyRulesScreen());
    await _capture(tester, '24_owner_onboarding_4_pricing_amenities',
        const PricingAmenitiesScreen());
    await _capture(tester, '25_owner_onboarding_5_topsis_weight',
        const OwnerTopsisScreen());

    // ── Tenant app ───────────────────────────────────────────────
    await _capture(
      tester,
      '30_tenant_home',
      BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(), child: const HomeScreen()),
    );
    await _capture(tester, '31_tenant_search', const SearchScreen());
    await _capture(
        tester,
        '32_tenant_map_view',
        MapViewScreen(
          properties:
              MockData.properties.where((p) => p['bScore'] == 1).toList(),
        ),
        settleSeconds: 6);
    await _capture(tester, '33_tenant_property_detail',
        PropertyDetailScreen(property: property));
    await _capture(tester, '34_tenant_listing_detail',
        const ListingDetailScreen(detail: ListingDetail.sample));
    await _capture(
        tester, '35_tenant_inquiries', const TenantInquiriesScreen());
    await _capture(tester, '36_tenant_phase1_inquiry',
        Phase1TenantScreen(property: property));
    await _capture(tester, '37_tenant_phase2_chat',
        Phase2TenantScreen(property: property));
    await _capture(
      tester,
      '38_tenant_activity_alerts',
      BlocProvider<ActivityCubit>(
        create: (_) => ActivityCubit(initialItems: ActivityItem.samples),
        child: const ActivityScreen(),
      ),
    );
    await _capture(
      tester,
      '39_tenant_profile',
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
          BlocProvider<ProfileCubit>(
              create: (_) => ProfileCubit(userRole: UserRole.tenant)),
        ],
        child: const ProfileScreen(),
      ),
    );
    await _capture(
      tester,
      '40_tenant_saved',
      BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(), child: const SavedScreen()),
    );
    await _capture(
        tester, '41_tenant_edit_constraints', const EditConstraintsScreen());
    await _capture(
        tester, '42_tenant_soft_preferences', const SoftPreferencesScreen());
    await _capture(tester, '43_tenant_edit_topsis', const EditTopsisScreen());
    await _capture(tester, '44_rating_screen', const RatingScreen());

    // ── Owner app ────────────────────────────────────────────────
    await _capture(
      tester,
      '50_owner_home',
      BlocProvider<LandlordHomeCubit>(
          create: (_) => LandlordHomeCubit(),
          child: const LandlordHomeScreen()),
    );
    await _capture(
      tester,
      '51_owner_matches',
      BlocProvider<LandlordHomeCubit>(
          create: (_) => LandlordHomeCubit(),
          child: const LandlordMatchesScreen()),
    );
    await _capture(
      tester,
      '52_owner_saved',
      BlocProvider<LandlordHomeCubit>(
          create: (_) => LandlordHomeCubit(),
          child: const LandlordSavedScreen()),
    );
    await _capture(tester, '53_owner_tenant_detail',
        const TenantDetailScreen(detail: TenantDetail.sample));
    await _capture(tester, '54_owner_find_tenants', const FindTenantsScreen());
    await _capture(
        tester, '55_owner_properties', const OwnerPropertiesScreen());
    await _capture(tester, '56_owner_edit_property',
        EditPropertyScreen(property: property));
    await _capture(tester, '57_owner_inquiries', const OwnerInquiriesScreen());
    await _capture(tester, '58_owner_phase1_inquiry',
        Phase1OwnerScreen(inquiry: ownerInquiry));
    await _capture(tester, '59_owner_phase2_chat',
        Phase2ChatOwnerScreen(inquiry: ownerInquiry));
    await _capture(
      tester,
      '60_owner_activity_alerts',
      BlocProvider<ActivityCubit>(
        create: (_) =>
            ActivityCubit(initialItems: ActivityItem.landlordSamples),
        child: const ActivityScreen(),
      ),
    );
    await _capture(tester, '61_owner_profile', const OwnerProfileScreen());
    await _capture(
        tester, '62_owner_edit_topsis', const EditOwnerTopsisScreen());

    // ── Admin ────────────────────────────────────────────────────
    await _capture(tester, '70_admin_login', const AdminLoginScreen());
    await _capture(tester, '71_admin_analytics', const AnalyticsScreen());
    await _capture(tester, '72_admin_pending_verifications',
        const PendingVerificationsScreen());
    await _capture(
        tester, '73_admin_user_management', const UserManagementScreen());
    await _capture(tester, '74_admin_property_management',
        const PropertyManagementScreen());

    // ignore: avoid_print
    print('\n=== DONE: ${_failures.length} failures ===');
    for (final f in _failures) {
      // ignore: avoid_print
      print(f);
    }
    expect(_failures, isEmpty);
  });
}
