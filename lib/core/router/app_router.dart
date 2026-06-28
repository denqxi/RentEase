import 'package:flutter/material.dart';

import '../../features/admin/view/admin_login_screen.dart';
import '../../features/admin/view/analytics_screen.dart';
import '../../features/admin/view/pending_verifications_screen.dart';
import '../../features/admin/view/property_management_screen.dart';
import '../../features/admin/view/user_management_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/owner/view/edit_owner_topsis_screen.dart';
import '../../features/owner/view/find_tenants_screen.dart';
import '../../features/owner/view/owner_inquiries_screen.dart';
import '../../features/owner/view/owner_profile_screen.dart';
import '../../features/owner/view/owner_properties_screen.dart';
import '../../features/owner/view/phase1_owner_screen.dart';
import '../../features/owner/view/phase2_chat_owner_screen.dart';
import '../../features/owner_onboarding/view/add_property_screen.dart';
import '../../features/owner_onboarding/view/document_upload_screen.dart';
import '../../features/owner_onboarding/view/owner_topsis_screen.dart';
import '../../features/owner_onboarding/view/pricing_amenities_screen.dart';
import '../../features/owner_onboarding/view/property_rules_screen.dart';
import '../../features/owner_onboarding/view/verification_pending_screen.dart';
import '../../features/registration/model/user_role.dart';
import '../../features/registration/view/registration_flow_screen.dart';
import '../../features/shell/view/main_shell.dart';
import '../../features/tenant_onboarding/view/distance_preference_screen.dart';
import '../../features/tenant_onboarding/view/hard_constraints_screen.dart';
import '../../features/tenant_onboarding/view/poi_setup_screen.dart';
import '../../features/tenant_onboarding/view/topsis_weight_screen.dart';

class AppRouter {
  AppRouter._();

  static const splash = '/';
  static const signIn = '/sign-in';
  static const welcome = '/welcome';
  static const roleSelection = '/role';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';

  static const hardConstraints = '/onboarding/hard-constraints';
  static const poiSetup = '/onboarding/poi';
  static const distancePreference = '/onboarding/distance';
  static const topsisWeight = '/onboarding/topsis';

  static const tenantHome = '/tenant/home';

  static const documentUpload = '/owner-onboarding/docs';
  static const verificationPending = '/owner-onboarding/pending';
  static const addProperty = '/owner-onboarding/add-property';
  static const propertyRules = '/owner-onboarding/rules';
  static const pricingAmenities = '/owner-onboarding/pricing';
  static const ownerTopsis = '/owner-onboarding/topsis';

  static const ownerProperties = '/owner/properties';
  static const findTenants = '/owner/find-tenants';
  static const ownerPhase1 = '/owner/inquiry/phase1';
  static const ownerPhase2 = '/owner/inquiry/phase2';
  static const ownerInquiries = '/owner/inquiries';
  static const ownerProfile = '/owner/profile';
  static const editOwnerTopsis = '/owner/profile/edit-topsis';

  static const adminLogin = '/admin/login';
  static const adminVerifications = '/admin/verifications';
  static const adminUsers = '/admin/users';
  static const adminProperties = '/admin/properties';
  static const adminAnalytics = '/admin/analytics';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case splash:
        page = const SplashScreen();
      case signIn:
        page = Builder(
          builder: (ctx) => SignInScreen(
            onCreateAccount: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => RegistrationFlowScreen(
                  onComplete: (role) => Navigator.of(ctx).pushNamedAndRemoveUntil(
                    verifyEmail,
                    (_) => false,
                    arguments: role == UserRole.landlord,
                  ),
                  onSignIn: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
        );
      case welcome:
        page = const WelcomeScreen();
      case roleSelection:
        page = const RoleSelectionScreen();
      case signup:
        page = const SignupScreen();
      case verifyEmail:
        final isOwner = (settings.arguments as bool?) ?? false;
        page = EmailVerificationScreen(isOwner: isOwner);

      case hardConstraints:
        page = const HardConstraintsScreen();
      case poiSetup:
        page = const PoiSetupScreen();
      case distancePreference:
        final poiName = (settings.arguments as String?) ?? 'School';
        page = DistancePreferenceScreen(poiName: poiName);
      case topsisWeight:
        page = TopsisWeightScreen(onSave: () {});

      case tenantHome:
        page = const MainShell();

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
      case ownerTopsis:
        page = OwnerTopsisScreen(onSave: () {});

      case ownerProperties:
        page = const OwnerPropertiesScreen();
      case findTenants:
        page = const FindTenantsScreen();
      case ownerPhase1:
        final inquiry = settings.arguments as Map<String, dynamic>;
        page = Phase1OwnerScreen(inquiry: inquiry);
      case ownerPhase2:
        final inquiry = settings.arguments as Map<String, dynamic>;
        page = Phase2ChatOwnerScreen(inquiry: inquiry);
      case ownerInquiries:
        page = const OwnerInquiriesScreen();
      case ownerProfile:
        page = const OwnerProfileScreen();
      case editOwnerTopsis:
        page = const EditOwnerTopsisScreen();

      case adminLogin:
        page = const AdminLoginScreen();
      case adminVerifications:
        page = const PendingVerificationsScreen();
      case adminUsers:
        page = const UserManagementScreen();
      case adminProperties:
        page = const PropertyManagementScreen();
      case adminAnalytics:
        page = const AnalyticsScreen();

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
