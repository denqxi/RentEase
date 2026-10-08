import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../firestore/firestore_collections.dart';
import '../../features/admin/view/admin_login_screen.dart';
import '../../features/admin/widgets/admin_only_gate.dart';
import '../../features/admin/widgets/admin_providers.dart';
import '../../features/admin/view/analytics_screen.dart';
import '../../features/admin/view/admin_shell.dart';
import '../../features/admin/view/pending_verifications_screen.dart';
import '../../features/admin/view/property_management_screen.dart';
import '../../features/admin/view/user_management_screen.dart';
import '../../features/auth/domain/entities/auth.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';

import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/inquiry/view/tenant_inquiries_screen.dart';
import '../../features/owner/view/find_tenants_screen.dart';
import '../../features/owner/view/owner_inquiries_screen.dart';
import '../../features/owner/view/owner_properties_screen.dart';
import '../../features/owner_onboarding/view/add_property_screen.dart';
import '../../features/owner_onboarding/view/document_upload_screen.dart';
import '../../features/profile/view/saved_screen.dart';
import '../../features/shell/view/landlord_shell.dart';
import '../../features/owner_onboarding/view/pricing_amenities_screen.dart';
import '../../features/owner_onboarding/view/property_rules_screen.dart';
import '../../features/owner_onboarding/view/verification_pending_screen.dart';
import '../../features/profile/view/owner_profile_screen.dart';
import '../../features/registration/model/user_role.dart';
import '../../features/registration/view/registration_flow_screen.dart';
import '../../features/onboarding/view/matching_transition_screen.dart';
import '../../features/shell/view/main_shell.dart';
import '../../features/tenant_onboarding/view/distance_preference_screen.dart';
import '../../features/tenant_onboarding/view/hard_constraints_screen.dart';
import '../../features/tenant_onboarding/view/poi_setup_screen.dart';
import '../../features/tenant_onboarding/view/topsis_weight_screen.dart';

class AppRouter {
  AppRouter._();

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  static const splash = '/';
  static const signIn = '/sign-in';
  static const roleSelection = '/role';
  static const signup = '/signup';

  static const hardConstraints = '/onboarding/hard-constraints';
  static const poiSetup = '/onboarding/poi';
  static const distancePreference = '/onboarding/distance';
  static const topsisWeight = '/onboarding/topsis';
  static const matchingTransition = '/onboarding/matching';

  static const tenantHome = '/tenant/home';
  static const tenantInquiries = '/tenant/inquiries';
  static const saved = '/saved';
  static const landlordHome = '/landlord/home';

  static const documentUpload = '/owner-onboarding/docs';
  static const verificationPending = '/owner-onboarding/pending';
  static const addProperty = '/owner-onboarding/add-property';
  static const propertyRules = '/owner-onboarding/rules';
  static const pricingAmenities = '/owner-onboarding/pricing';

  static const ownerProperties = '/owner/properties';
  static const findTenants = '/owner/find-tenants';
  static const ownerInquiries = '/owner/inquiries';
  static const ownerProfile = '/owner/profile';

  static const adminHome = '/admin/home';
  static const adminLogin = '/admin/login';
  static const adminVerifications = '/admin/verifications';
  static const adminUsers = '/admin/users';
  static const adminProperties = '/admin/properties';
  static const adminAnalytics = '/admin/analytics';

  /// Where a signed-in user lands: admins must never fall through to the
  /// tenant home.
  static String homeRouteFor({required bool isAdmin, required bool isOwner}) =>
      isAdmin ? adminHome : (isOwner ? landlordHome : tenantHome);

  /// Resolves the destination route for an authenticated user based on role,
  /// verification, and onboarding completion.
  static Future<String> postAuthRouteFor(AppUser user) async {
    if (user.isAdmin) return adminHome;
    if (!user.emailVerified) {
      return user.isOwner ? documentUpload : hardConstraints;
    }
    try {
      final firestore = FirebaseFirestore.instance;
      if (user.isOwner) {
        final snap = await firestore
            .collection(FirestoreCollections.ownerProfiles)
            .doc(user.uid)
            .get();
        if (!snap.exists) return documentUpload;
        return landlordHome;
      } else {
        final snap = await firestore
            .collection(FirestoreCollections.tenantProfiles)
            .doc(user.uid)
            .get();
        if (!snap.exists) return hardConstraints;
        return tenantHome;
      }
    } catch (_) {
      return homeRouteFor(isAdmin: user.isAdmin, isOwner: user.isOwner);
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case signIn:
        page = Builder(
          builder: (ctx) => SignInScreen(
            onSignIn: (user) async {
              final route = await postAuthRouteFor(user);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pushNamedAndRemoveUntil(route, (_) => false);
            },
            onCreateAccount: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => RegistrationFlowScreen(
                  // A fresh account is unverified: go through email
                  // verification first (it then routes into onboarding),
                  // exactly like the _SignInEntry flow in app.dart.
                  onComplete: (role) => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EmailVerificationScreen(
                        isOwner: role == UserRole.landlord,
                      ),
                    ),
                  ),
                  onSignIn: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
        );
      case roleSelection:
        page = const RoleSelectionScreen();
      case signup:
        page = const SignupScreen();

      case hardConstraints:
        page = const HardConstraintsScreen();
      case poiSetup:
        page = const PoiSetupScreen();
      case distancePreference:
        final poiName = (settings.arguments as String?) ?? 'School';
        page = DistancePreferenceScreen(poiName: poiName);
      case topsisWeight:
        page = const TopsisWeightScreen();
      case matchingTransition:
        final isOwner = (settings.arguments as bool?) ?? false;
        page = MatchingTransitionScreen(isOwner: isOwner);

      case tenantHome:
        final sessionRole =
            (settings.arguments as UserRole?) ?? UserRole.tenant;
        page = MainShell(sessionRole: sessionRole);
      case tenantInquiries:
        page = const TenantInquiriesScreen();
      case saved:
        page = const SavedScreen();
      case landlordHome:
        page = const LandlordShell();

      case documentUpload:
        page = const DocumentUploadScreen();
      case verificationPending:
        page = const VerificationPendingScreen();
      case addProperty:
        page = const AddPropertyScreen();
      case propertyRules:
        page = const PropertyRulesScreen();
      case pricingAmenities:
        page = const PricingAmenitiesScreen();

      case ownerProperties:
        page = const OwnerPropertiesScreen();
      case findTenants:
        page = const FindTenantsScreen();
      case ownerInquiries:
        page = const OwnerInquiriesScreen();
      case ownerProfile:
        page = const OwnerProfileScreen();

      case adminHome:
        page = const AdminOnlyGate(child: AdminShell());
      case adminLogin:
        page = const AdminLoginScreen();
      case adminVerifications:
        page = const AdminOnlyGate(
          child: AdminProviders(child: PendingVerificationsScreen()),
        );
      case adminUsers:
        page = const AdminOnlyGate(
          child: AdminProviders(child: UserManagementScreen()),
        );
      case adminProperties:
        page = const AdminOnlyGate(
          child: AdminProviders(child: PropertyManagementScreen()),
        );
      case adminAnalytics:
        page = const AdminOnlyGate(
          child: AdminProviders(child: AnalyticsScreen()),
        );

      default:
        page = const _NotFoundPage();
    }

    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Page not found')),
    );
  }
}
