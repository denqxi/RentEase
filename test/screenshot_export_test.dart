// Ad-hoc screenshot harness — not part of the regular test suite.
// Renders every reachable screen with representative mock data and captures
// a real pixel screenshot via RepaintBoundary, since no browser/emulator
// driver is available in this environment. Run with:
//   flutter test test/screenshot_export_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentease/core/constants/mock_data.dart';
import 'package:rentease/core/theme/app_theme.dart';

import 'package:rentease/features/activity/cubit/activity_cubit.dart';
import 'package:rentease/features/activity/model/activity_item.dart';
import 'package:rentease/features/activity/view/activity_screen.dart';
import 'package:rentease/debug/preview_admin_repository.dart';
import 'package:rentease/features/admin/view/admin_login_screen.dart';
import 'package:rentease/features/admin/widgets/admin_providers.dart';
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
import 'package:rentease/features/home/data/repositories/home_repository_impl.dart';
import 'package:rentease/features/home/model/listing_detail.dart';
import 'package:rentease/features/home/view/home_screen.dart';
import 'package:rentease/features/home/view/listing_detail_screen.dart';
import 'package:rentease/features/home/view/property_detail_screen.dart';
import 'package:rentease/features/home/view/search_screen.dart';
import 'package:rentease/features/matching/data/repositories/filtering_repository_impl.dart';
import 'package:rentease/features/matching/data/repositories/topsis_repository_impl.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';
import 'package:rentease/features/matching/domain/services/topsis_service.dart';
import 'package:rentease/features/inquiry/view/tenant_inquiries_screen.dart';
import 'package:rentease/features/landlord_home/cubit/landlord_home_cubit.dart';
import 'package:rentease/features/owner/model/compatible_tenant.dart';
import 'package:rentease/features/landlord_home/view/landlord_home_screen.dart';
import 'package:rentease/features/landlord_home/view/tenant_detail_screen.dart';
import 'package:rentease/features/landlord_matches/view/landlord_matches_screen.dart';
import 'package:rentease/features/onboarding/view/onboarding_screen.dart';
import 'package:rentease/features/owner/view/find_tenants_screen.dart';
import 'package:rentease/features/owner/view/owner_inquiries_screen.dart';
import 'package:rentease/features/owner/view/owner_properties_screen.dart';
import 'package:rentease/features/owner_onboarding/view/add_property_screen.dart';
import 'package:rentease/features/owner_onboarding/view/document_upload_screen.dart';
import 'package:rentease/features/owner_onboarding/view/pricing_amenities_screen.dart';
import 'package:rentease/features/owner_onboarding/view/property_rules_screen.dart';
import 'package:rentease/features/owner_onboarding/view/verification_pending_screen.dart';
import 'package:rentease/features/profile/cubit/profile_cubit.dart';
import 'package:rentease/features/profile/view/edit_constraints_screen.dart';
import 'package:rentease/features/profile/view/edit_topsis_screen.dart';
import 'package:rentease/features/profile/view/owner_profile_screen.dart';
import 'package:rentease/features/profile/view/profile_screen.dart';
import 'package:rentease/features/profile/view/saved_screen.dart';
import 'package:rentease/features/registration/model/user_role.dart';
import 'package:rentease/features/registration/view/registration_flow_screen.dart';
import 'package:rentease/features/resolution/view/rating_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/distance_preference_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/hard_constraints_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/poi_setup_screen.dart';
import 'package:rentease/features/tenant_onboarding/view/topsis_weight_screen.dart';

final Directory _outDir = Directory('screenshots');
final List<String> _failures = <String>[];

/// Screenshot capture only renders the widget tree offline — there's no
/// Firebase app initialized in this test, so `HomeCubit.refresh()`'s
/// Firestore calls fail harmlessly (caught internally, surfaces as an error
/// state) rather than actually fetching anything. A real tenantId/backend
/// isn't needed for a static visual capture.
HomeCubit _previewHomeCubit() => HomeCubit(
      tenantId: 'preview',
      repository: HomeRepositoryImpl(),
      filteringService: FilteringService(repository: FilteringRepositoryImpl()),
      topsisService: TopsisService(repository: TopsisRepositoryImpl()),
    );

Future<void> _capture(WidgetTester tester, String name, Widget child) async {
  try {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844) * 2.0;
    tester.view.devicePixelRatio = 2.0;
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: RepaintBoundary(key: key, child: child),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${_outDir.path}/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('captured $name');
  } catch (e) {
    _failures.add('$name: $e');
    // ignore: avoid_print
    print('FAILED $name: $e');
  } finally {
    addTearDown(() => tester.view.resetPhysicalSize());
  }
}

void main() {
  setUpAll(() => _outDir.createSync(recursive: true));

  testWidgets('capture all screens', (tester) async {
    final property = MockData.properties[0];

    final bytes = File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytesSync();
    _fontBytes = bytes;

    await HttpOverrides.runZoned(() async {
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
    await _capture(
        tester,
        '07_registration_flow',
        RegistrationFlowScreen(onComplete: (_) {}, onSignIn: () {}));

    // ── Tenant onboarding (4 steps) ──────────────────────────────
    await _capture(
        tester, '10_tenant_onboarding_1_hard_constraints', const HardConstraintsScreen());
    await _capture(
        tester, '11_tenant_onboarding_2_poi_setup', const PoiSetupScreen());
    await _capture(
        tester,
        '12_tenant_onboarding_3_distance_preference',
        const DistancePreferenceScreen(poiName: 'University of Southeastern Philippines'));
    await _capture(
        tester, '13_tenant_onboarding_4_topsis_weight', const TopsisWeightScreen());

    // ── Owner onboarding ─────────────────────────────────────────
    await _capture(
        tester, '20_owner_onboarding_1_document_upload', const DocumentUploadScreen());
    await _capture(tester, '21_owner_onboarding_verification_pending',
        const VerificationPendingScreen());
    await _capture(
        tester, '22_owner_onboarding_2_add_property', const AddPropertyScreen());
    await _capture(
        tester, '23_owner_onboarding_3_property_rules', const PropertyRulesScreen());
    await _capture(tester, '24_owner_onboarding_4_pricing_amenities',
        const PricingAmenitiesScreen());

    // ── Tenant app ───────────────────────────────────────────────
    await _capture(
      tester,
      '30_tenant_home',
      BlocProvider<HomeCubit>(create: (_) => _previewHomeCubit(), child: const HomeScreen()),
    );
    await _capture(
      tester,
      '31_tenant_search',
      BlocProvider<ProfileCubit>(
        create: (_) => ProfileCubit(userRole: UserRole.tenant),
        child: const SearchScreen(),
      ),
    );
    await _capture(
        tester, '32_tenant_property_detail', PropertyDetailScreen(property: property));
    await _capture(tester, '33_tenant_listing_detail',
        const ListingDetailScreen(detail: ListingDetail.sample));
    await _capture(tester, '34_tenant_inquiries', const TenantInquiriesScreen());
    await _capture(
      tester,
      '37_tenant_activity_alerts',
      BlocProvider<ActivityCubit>(
        create: (_) => ActivityCubit(initialItems: ActivityItem.samples),
        child: const ActivityScreen(),
      ),
    );
    await _capture(
      tester,
      '38_tenant_profile',
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeCubit>(create: (_) => _previewHomeCubit()),
          BlocProvider<ProfileCubit>(
              create: (_) => ProfileCubit(userRole: UserRole.tenant)),
        ],
        child: const ProfileScreen(),
      ),
    );
    await _capture(
      tester,
      '39_tenant_saved',
      BlocProvider<HomeCubit>(create: (_) => _previewHomeCubit(), child: const SavedScreen()),
    );
    await _capture(tester, '40_tenant_edit_constraints', const EditConstraintsScreen());
    await _capture(tester, '41_tenant_edit_topsis', const EditTopsisScreen());
    await _capture(tester, '42_rating_screen', const RatingScreen());

    // ── Owner app ────────────────────────────────────────────────
    await _capture(
      tester,
      '50_owner_home',
      BlocProvider<LandlordHomeCubit>(
          create: (_) => LandlordHomeCubit(), child: const LandlordHomeScreen()),
    );
    await _capture(
      tester,
      '51_owner_matches',
      BlocProvider<LandlordHomeCubit>(
          create: (_) => LandlordHomeCubit(), child: const LandlordMatchesScreen()),
    );
    await _capture(
      tester,
      '52_owner_add_property',
      const AddPropertyScreen(),
    );
    await _capture(
        tester, '53_owner_tenant_detail', const TenantDetailScreen(tenant: CompatibleTenant(matchId: 'm1', tenantId: 't1', name: 'Preview Tenant', gender: 'Female', maxBudget: 4500, bScore: 1)));
    await _capture(tester, '54_owner_find_tenants', const FindTenantsScreen());
    await _capture(tester, '55_owner_properties', const OwnerPropertiesScreen());
    await _capture(tester, '56_owner_inquiries', const OwnerInquiriesScreen());
    await _capture(
      tester,
      '59_owner_activity_alerts',
      BlocProvider<ActivityCubit>(
        create: (_) => ActivityCubit(initialItems: ActivityItem.landlordSamples),
        child: const ActivityScreen(),
      ),
    );
    await _capture(tester, '60_owner_profile', const OwnerProfileScreen());

    // ── Admin ────────────────────────────────────────────────────
    await _capture(tester, '70_admin_login', const AdminLoginScreen(repository: PreviewAdminRepository()));
    await _capture(tester, '71_admin_analytics', const AdminProviders(repository: PreviewAdminRepository(), child: AnalyticsScreen()));
    await _capture(
        tester, '72_admin_pending_verifications', const AdminProviders(repository: PreviewAdminRepository(), child: PendingVerificationsScreen()));
    await _capture(tester, '73_admin_user_management', const AdminProviders(repository: PreviewAdminRepository(), child: UserManagementScreen()));
    await _capture(
        tester, '74_admin_property_management', const AdminProviders(repository: PreviewAdminRepository(), child: PropertyManagementScreen()));

    // ignore: avoid_print
    print('\n=== DONE: ${_failures.length} failures ===');
    for (final f in _failures) {
      // ignore: avoid_print
      print(f);
    }
    }, createHttpClient: (context) => _MockHttpClient());
  });
}

late List<int> _fontBytes;

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async {
    return _MockHttpClientRequest(Uri.parse('http://$host:$port$path'));
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async {
    return _MockHttpClientRequest(Uri.parse('http://$host:$port$path'));
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return _MockHttpClientRequest(Uri.parse('http://$host:$port$path'));
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  final Uri url;
  _MockHttpClientRequest(this.url);

  @override
  String get method => "GET";

  @override
  Uri get uri => url;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  bool persistentConnection = true;

  @override
  bool bufferOutput = true;

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse(url);
  }

  @override
  Future<HttpClientResponse> get done => Future.value(_MockHttpClientResponse(url));

  @override
  Future addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future flush() => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri url;
  late final List<int> _responseBytes;

  _MockHttpClientResponse(this.url) {
    final urlStr = url.toString();
    if (urlStr.contains('fonts.gstatic.com') || urlStr.endsWith('.ttf')) {
      _responseBytes = _fontBytes;
    } else {
      try {
        final file = File(r'c:\Users\User\rentease\assets\images\logo.png');
        if (file.existsSync()) {
          _responseBytes = file.readAsBytesSync();
        } else {
          _responseBytes = const <int>[
            137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 167, 9, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
          ];
        }
      } catch (_) {
        _responseBytes = const <int>[
          137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 167, 9, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
        ];
      }
    }
  }

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => "OK";

  @override
  int get contentLength => _responseBytes.length;

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  bool get persistentConnection => true;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_responseBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    final projFile = File('c:\\Users\\User\\rentease\\$key');
    if (projFile.existsSync()) {
      final bytes = await projFile.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    throw FlutterError('Asset not found: $key');
  }
}
