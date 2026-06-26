import 'package:flutter/material.dart';

import '../../features/admin/view/admin_login_screen.dart';
import '../../features/admin/view/analytics_screen.dart';
import '../../features/admin/view/pending_verifications_screen.dart';
import '../../features/admin/view/property_management_screen.dart';
import '../../features/admin/view/user_management_screen.dart';
import '../../features/home/view/property_detail_screen.dart';
import '../../features/home/view/search_screen.dart';
import '../../features/inquiry/view/phase1_owner_screen.dart';
import '../../features/inquiry/view/phase1_tenant_screen.dart';
import '../../features/inquiry/view/phase2_owner_screen.dart';
import '../../features/inquiry/view/phase2_tenant_screen.dart';
import '../../features/inquiry/view/tenant_inquiries_screen.dart';
import '../../features/landlord_home/view/find_tenants_screen.dart';
import '../../features/landlord_home/view/owner_inquiries_screen.dart';
import '../../features/landlord_home/view/owner_properties_screen.dart';
import '../../features/owner_onboarding/view/document_upload_screen.dart';
import '../../features/owner_onboarding/view/owner_topsis_screen.dart';
import '../../features/owner_onboarding/view/pricing_amenities_screen.dart';
import '../../features/owner_onboarding/view/property_rules_screen.dart';
import '../../features/owner_onboarding/view/verification_pending_screen.dart';
import '../../features/profile/view/edit_constraints_screen.dart';
import '../../features/profile/view/edit_topsis_screen.dart';
import '../../features/profile/view/owner_profile_screen.dart';
import '../../features/profile/view/tenant_profile_screen.dart';
import '../../features/resolution/view/rating_screen.dart';
import '../../features/tenant_onboarding/view/hard_constraints_screen.dart';
import '../../features/tenant_onboarding/view/poi_setup_screen.dart';
import '../../features/tenant_onboarding/view/topsis_weight_screen.dart';

/// Named route constants for the entire RentEase app.
abstract final class AppRoutes {
  // Tenant onboarding
  static const String hardConstraints    = '/tenant-onboarding/hard-constraints';
  static const String poiSetup           = '/tenant-onboarding/poi-setup';
  static const String topsisWeight       = '/tenant-onboarding/topsis-weight';

  // Tenant home / search
  static const String search             = '/home/search';
  static const String propertyDetail     = '/home/property-detail';

  // Inquiry — tenant side
  static const String phase1Tenant       = '/inquiry/phase1-tenant';
  static const String phase2Tenant       = '/inquiry/phase2-tenant';
  static const String tenantInquiries    = '/inquiry/tenant-inquiries';

  // Inquiry — owner side
  static const String phase1Owner        = '/inquiry/phase1-owner';
  static const String phase2Owner        = '/inquiry/phase2-owner';

  // Resolution
  static const String rating             = '/resolution/rating';

  // Tenant profile
  static const String tenantProfile      = '/profile/tenant';
  static const String editConstraints    = '/profile/edit-constraints';
  static const String editTopsis         = '/profile/edit-topsis';

  // Owner onboarding
  static const String documentUpload     = '/owner-onboarding/document-upload';
  static const String verificationPending= '/owner-onboarding/verification-pending';
  static const String propertyRules      = '/owner-onboarding/property-rules';
  static const String pricingAmenities   = '/owner-onboarding/pricing-amenities';
  static const String ownerTopsis        = '/owner-onboarding/topsis';

  // Owner main app
  static const String ownerProperties    = '/landlord/properties';
  static const String findTenants        = '/landlord/find-tenants';
  static const String ownerInquiries     = '/landlord/inquiries';
  static const String ownerProfile       = '/profile/owner';

  // Admin
  static const String adminLogin              = '/admin/login';
  static const String adminPendingVerifications = '/admin/pending-verifications';
  static const String adminUsers              = '/admin/users';
  static const String adminProperties         = '/admin/properties';
  static const String adminAnalytics          = '/admin/analytics';
}

/// Route factory registered with [MaterialApp.onGenerateRoute].
///
/// Screens that require data (e.g. [PropertyDetailScreen]) receive it via
/// [RouteSettings.arguments]; fall back to an empty map where data is optional.
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final args = settings.arguments;

  Widget? page;

  switch (settings.name) {
    // ── Tenant onboarding ─────────────────────────────────────────────────
    case AppRoutes.hardConstraints:
      page = const HardConstraintsScreen();
    case AppRoutes.poiSetup:
      page = const PoiSetupScreen();
    case AppRoutes.topsisWeight:
      page = const TopsisWeightScreen();

    // ── Tenant search ──────────────────────────────────────────────────────
    case AppRoutes.search:
      page = const SearchScreen();
    case AppRoutes.propertyDetail:
      final property = args as Map<String, dynamic>? ?? {};
      page = PropertyDetailScreen(property: property);

    // ── Inquiry — tenant ──────────────────────────────────────────────────
    case AppRoutes.phase1Tenant:
      final property = args as Map<String, dynamic>? ?? {};
      page = Phase1TenantScreen(property: property);
    case AppRoutes.phase2Tenant:
      final property = args as Map<String, dynamic>? ?? {};
      page = Phase2TenantScreen(property: property);
    case AppRoutes.tenantInquiries:
      page = const TenantInquiriesScreen();

    // ── Inquiry — owner ───────────────────────────────────────────────────
    case AppRoutes.phase1Owner:
      final inquiry = args as Map<String, dynamic>? ?? {};
      page = Phase1OwnerScreen(inquiry: inquiry);
    case AppRoutes.phase2Owner:
      final inquiry = args as Map<String, dynamic>? ?? {};
      page = Phase2OwnerScreen(inquiry: inquiry);

    // ── Resolution ────────────────────────────────────────────────────────
    case AppRoutes.rating:
      page = const RatingScreen();

    // ── Tenant profile ────────────────────────────────────────────────────
    case AppRoutes.tenantProfile:
      page = const TenantProfileScreen();
    case AppRoutes.editConstraints:
      page = const EditConstraintsScreen();
    case AppRoutes.editTopsis:
      page = const EditTopsisScreen();

    // ── Owner onboarding ──────────────────────────────────────────────────
    case AppRoutes.documentUpload:
      page = const DocumentUploadScreen();
    case AppRoutes.verificationPending:
      page = const VerificationPendingScreen();
    case AppRoutes.propertyRules:
      page = const PropertyRulesScreen();
    case AppRoutes.pricingAmenities:
      page = const PricingAmenitiesScreen();
    case AppRoutes.ownerTopsis:
      page = const OwnerTopsisScreen();

    // ── Owner main app ────────────────────────────────────────────────────
    case AppRoutes.ownerProperties:
      page = const OwnerPropertiesScreen();
    case AppRoutes.findTenants:
      page = const FindTenantsScreen();
    case AppRoutes.ownerInquiries:
      page = const OwnerInquiriesScreen();
    case AppRoutes.ownerProfile:
      page = const OwnerProfileScreen();

    // ── Admin ─────────────────────────────────────────────────────────────
    case AppRoutes.adminLogin:
      page = const AdminLoginScreen();
    case AppRoutes.adminPendingVerifications:
      page = const PendingVerificationsScreen();
    case AppRoutes.adminUsers:
      page = const UserManagementScreen();
    case AppRoutes.adminProperties:
      page = const PropertyManagementScreen();
    case AppRoutes.adminAnalytics:
      page = const AnalyticsScreen();
  }

  if (page == null) return null;

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => page!,
  );
}
