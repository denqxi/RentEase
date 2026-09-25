## AUTH:GET_STARTED
- [AUTH:GET_STARTED] `lib/features/auth/presentation/screens/splash_screen.dart` | App splash / initial launch screen
- [AUTH:GET_STARTED] `lib/features/onboarding/view/onboarding_screen.dart` | Welcome onboarding flow for new users
- [AUTH:GET_STARTED] `lib/features/onboarding/view/matching_transition_screen.dart` | Transition screen used during onboarding matching

## AUTH:SIGN_IN
- [AUTH:SIGN_IN] `lib/features/auth/presentation/screens/auth_screen.dart` | Primary sign‑in screen (login UI)
- [AUTH:SIGN_IN] `lib/features/auth/view/sign_in_entry.dart` | Login form with email & password fields
- [AUTH:SIGN_IN] `lib/features/admin/view/admin_login_screen.dart` | Admin credentials entry screen

## AUTH:REGISTER
- [AUTH:REGISTER] `lib/features/auth/presentation/screens/signup_screen.dart` | User registration / account creation UI

- [AUTH:REGISTER] `lib/features/auth/presentation/screens/role_selection_screen.dart` | Role selection (tenant vs. landlord) during registration
- [AUTH:REGISTER] `lib/features/auth/presentation/screens/terms_and_conditions_screen.dart` | Terms & conditions acceptance screen

## FLOW:OWNER
- [FLOW:OWNER] `lib/features/owner/view/edit_owner_topsis_screen.dart` | Owner TOPSIS editing screen
- [FLOW:OWNER] `lib/features/owner/view/edit_property_screen.dart` | Edit existing property details
- [FLOW:OWNER] `lib/features/owner/view/find_tenants_screen.dart` | Search & filter potential tenants
- [FLOW:OWNER] `lib/features/owner/view/owner_inquiries_screen.dart` | Owner‑side inquiry management
- [FLOW:OWNER] `lib/features/owner/view/owner_properties_screen.dart` | List of owner‑managed properties
- [FLOW:OWNER] `lib/features/owner/view/phase1_owner_screen.dart` | First‑phase onboarding for owners
- [FLOW:OWNER] `lib/features/owner/view/phase2_chat_owner_screen.dart` | Owner chat interface (phase 2)
- [FLOW:OWNER] `lib/features/owner_onboarding/view/add_property_screen.dart` | Add new property (owner onboarding)
- [FLOW:OWNER] `lib/features/owner_onboarding/view/document_upload_screen.dart` | Upload property documents
- [FLOW:OWNER] `lib/features/owner_onboarding/view/owner_topsis_screen.dart` | Owner TOPSIS configuration screen
- [FLOW:OWNER] `lib/features/owner_onboarding/view/pricing_amenities_screen.dart` | Set pricing & amenities for a property
- [FLOW:OWNER] `lib/features/owner_onboarding/view/property_rules_screen.dart` | Define house rules & policies
- [FLOW:OWNER] `lib/features/owner_onboarding/view/verification_pending_screen.dart` | Verification‑pending status UI
- [FLOW:OWNER] `lib/features/landlord_home/view/landlord_home_screen.dart` | Landlord dashboard/home screen
- [FLOW:OWNER] `lib/features/landlord_home/view/tenant_detail_screen.dart` | Detailed view of a tenant profile
- [FLOW:OWNER] `lib/features/landlord_matches/view/landlord_matches_screen.dart` | Matching UI for landlord‑tenant fits
- [FLOW:OWNER] `lib/features/properties/presentation/screens/properties_screen.dart` | Owner’s property list overview
- [FLOW:OWNER] `lib/features/leases/presentation/screens/leases_screen.dart` | Lease management screen for owners
- [FLOW:OWNER] `lib/features/maintenance/presentation/screens/maintenance_screen.dart` | Property maintenance request UI

## FLOW:TENANT
- [FLOW:TENANT] `lib/features/inquiry/view/tenant_inquiries_screen.dart` | Tenant’s list of sent inquiries
- [FLOW:TENANT] `lib/features/inquiry/view/phase1_tenant_screen.dart` | First‑phase tenant inquiry screen
- [FLOW:TENANT] `lib/features/inquiry/view/phase2_tenant_screen.dart` | Second‑phase tenant inquiry screen
- [FLOW:TENANT] `lib/features/matches/view/matches_screen.dart` | Tenant‑side match results screen
- [FLOW:TENANT] `lib/features/home/view/home_screen.dart` | Main tenant home/dashboard with listings
- [FLOW:TENANT] `lib/features/home/view/listing_detail_screen.dart` | Detailed view of a selected listing
- [FLOW:TENANT] `lib/features/home/view/map_view_screen.dart` | Map view for discovering units
- [FLOW:TENANT] `lib/features/home/view/property_detail_screen.dart` | Property detail page for tenants
- [FLOW:TENANT] `lib/features/home/view/search_screen.dart` | Search UI for finding rental units

## SHARED:WIDGETS
- [SHARED:WIDGETS] `lib/shared/widgets/app_button.dart` | Standardised button component
- [SHARED:WIDGETS] `lib/shared/widgets/app_chip.dart` | Re‑usable chip widget
- [SHARED:WIDGETS] `lib/shared/widgets/app_text_field.dart` | Consistent styled text field
- [SHARED:WIDGETS] `lib/shared/widgets/app_toggle.dart` | Toggle switch component
- [SHARED:WIDGETS] `lib/shared/widgets/card_over_hero_layout.dart` | Card overlay layout for hero images
- [SHARED:WIDGETS] `lib/shared/widgets/ci_score_pill.dart` | Pill widget displaying CI score
- [SHARED:WIDGETS] `lib/shared/widgets/compatible_badge.dart` | Badge indicating compatibility
- [SHARED:WIDGETS] `lib/shared/widgets/constraint_check_row.dart` | Row UI for constraint checks
- [SHARED:WIDGETS] `lib/shared/widgets/error_widget.dart` | Generic error placeholder widget
- [SHARED:WIDGETS] `lib/shared/widgets/guest_access_sheet.dart` | Bottom sheet for guest access flow
- [SHARED:WIDGETS] `lib/shared/widgets/listing_card_row.dart` | Compact listing card row layout
- [SHARED:WIDGETS] `lib/shared/widgets/listing_image_placeholder.dart` | Placeholder image for listings
- [SHARED:WIDGETS] `lib/shared/widgets/loading_indicator.dart` | Centralised loading spinner
- [SHARED:WIDGETS] `lib/shared/widgets/map_zoom_controls.dart` | Zoom controls for map views
- [SHARED:WIDGETS] `lib/shared/widgets/match_badge.dart` | Badge for successful matches
- [SHARED:WIDGETS] `lib/shared/widgets/match_score_card.dart` | Card showing match score details
- [SHARED:WIDGETS] `lib/shared/widgets/phase_badge.dart` | Badge for inquiry phase steps
- [SHARED:WIDGETS] `lib/shared/widgets/qualified_badge.dart` | Badge for qualified tenants
- [SHARED:WIDGETS] `lib/shared/widgets/topsis_weight_bar.dart` | Bar visualising TOPSIS weight
- [SHARED:WIDGETS] `lib/shared/widgets/vacancy_status_pill.dart` | Pill indicating vacancy status
- [SHARED:WIDGETS] `lib/shared/widgets/verified_badge.dart` | Verified user badge

## SHARED:THEME
- [SHARED:THEME] `lib/core/theme/app_theme.dart` | Central ThemeData (colors, typography, shapes)
- [SHARED:THEME] `lib/core/theme/app_text_styles.dart` | Global TextStyle definitions
## REGISTRATION FLOW: TENANT
1. [FLOW:TENANT_REG] `lib/features/registration/view/role_selection_view.dart` | Role Selection
2. [FLOW:TENANT_REG] `lib/features/registration/view/account_step_view.dart` | Account Input (Name, Email, Password, etc.)
3. [FLOW:TENANT_REG] `lib/features/registration/view/check_email_view.dart` | Email Verification
4. [FLOW:TENANT_REG] `lib/features/registration/view/about_step_view.dart` | Background Info (About)
5. [FLOW:TENANT_REG] `lib/features/registration/view/preferences_step_view.dart` | Rental Preferences
6. [FLOW:TENANT_REG] `lib/features/registration/view/success_view.dart` | Success Screen

## REGISTRATION FLOW: OWNER
1. [FLOW:OWNER_REG] `lib/features/registration/view/role_selection_view.dart` | Role Selection
2. [FLOW:OWNER_REG] `lib/features/registration/view/landlord_account_step_view.dart` | Landlord Account Input (Name, Email, Password)
3. [FLOW:OWNER_REG] `lib/features/registration/view/check_email_view.dart` | Email Verification
4. [FLOW:OWNER_REG] `lib/features/registration/view/business_step_view.dart` | Business Profile
5. [FLOW:OWNER_REG] `lib/features/registration/view/property_step_view.dart` | Property Details
6. [FLOW:OWNER_REG] `lib/features/registration/view/ideal_tenant_step_view.dart` | Ideal Tenant Criteria
7. [FLOW:OWNER_REG] `lib/features/registration/view/success_view.dart` | Success Screen

