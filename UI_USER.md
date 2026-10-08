# RentEase - Logged-In User Interface & Screen Flow Index (UI_USER.md)

This index maps the navigation flows, views, child screens, and components for **authenticated/logged-in users** (Tenants and Landlords/Owners). Use this file to quickly locate any screen or sub-screen in the post-login application lifecycle.

---

## 1. TENANT LOGGED-IN FLOW

### Root Shell & Tab Navigation
- [SHELL:TENANT] `lib/features/shell/view/main_shell.dart` | Root logged-in shell for tenants; hosts `IndexedStack` with 5 bottom navigation tabs and sets up core BLoCs (`HomeCubit`, `ActivityCubit`, `ProfileCubit`, `ShellCubit`)
- [SHELL:TENANT] `lib/features/shell/widgets/floating_nav_bar.dart` | Floating bottom navigation bar with pill active indicator, unread badges, and role gating
- [SHELL:TENANT] `lib/features/shell/cubit/shell_cubit.dart` | Tab selection controller managing active `ShellTab` index

---

### Tab 1: Home Dashboard (`ShellTab.home` / Index 0)
- [FLOW:TENANT_HOME] `lib/features/home/view/home_screen.dart` | Main dashboard displaying personalized rental recommendations, Ci-ranked compatible properties, and other listings
- [FLOW:TENANT_HOME] `lib/features/home/widgets/home_header.dart` | Greeting header showing tenant's name and quick status
- [FLOW:TENANT_HOME] `lib/features/home/widgets/recommended_section.dart` | "Recommended for you" horizontal carousel for top-scoring properties
- [FLOW:TENANT_HOME] `lib/features/home/widgets/listing_card_large.dart` | Large featured property card (image hero, price, location, TOPSIS match badge, heart save button)
- [FLOW:TENANT_HOME] `lib/features/home/widgets/nearby_section.dart` | "Compatible properties" vertical list ranked strictly by TOPSIS score
- [FLOW:TENANT_HOME] `lib/features/home/widgets/listing_card_compact.dart` | Compact horizontal-row listing card
- [FLOW:TENANT_HOME] `lib/features/home/widgets/other_listings_section.dart` | Non-matching or below-threshold listings section with clear mismatch indicators

#### Sub-Screens & Actions from Home:
1. [FLOW:TENANT_HOME] `lib/features/home/view/property_detail_screen.dart` | Full property details (photo carousel, rent, rules check, landlord info, contact consent, send inquiry CTA)
2. [FLOW:TENANT_HOME] `lib/features/home/view/listing_detail_screen.dart` | Detailed listing view alternative with breakdown card and breakdown metrics
3. [FLOW:TENANT_HOME] `lib/features/home/view/map_view_screen.dart` | Interactive OpenStreetMap showing property markers and POI radius
4. [FLOW:TENANT_HOME] `lib/features/inquiry/view/start_inquiry.dart` | Direct action handler to send an inquiry with tenant consent prompt

---

### Tab 2: Search & Filter (`ShellTab.search` / Index 1)
- [FLOW:TENANT_SEARCH] `lib/features/home/view/search_screen.dart` | Search interface with keyword search, real-time filtering, map toggle, and TOPSIS Ci results
- [FLOW:TENANT_SEARCH] `lib/features/tenant/view/session_filter_sheet.dart` | Modal bottom sheet for temporary session filters (budget range, distance, room types, pet/smoking rules)
- [FLOW:TENANT_SEARCH] `lib/features/home/view/map_view_screen.dart` | Map mode toggled directly from search to view location pins
- [FLOW:TENANT_SEARCH] `lib/features/home/view/property_detail_screen.dart` | Tapping any search result navigates to this detail view

---

### Tab 3: Inquiries & Messaging (`ShellTab.inquiries` / Index 2)
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/view/tenant_inquiries_screen.dart` | Tenant inbox displaying Active and Resolved inquiries sent to landlords
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/view/start_inquiry.dart` | Consent modal and inquiry initialization flow

#### Inquiry Thread & Lifecycle States:
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/view/inquiry_thread_screen.dart` | Live thread container dynamically switching between Phase 1 and Phase 2
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/widgets/tenant_phase1_view.dart` | Phase 1 view: Inquiry sent, awaiting landlord response (anonymous contact protection)
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/widgets/inquiry_chat_view.dart` | Phase 2 view: Landlord accepted; real-time in-app chat with contact details revealed
- [FLOW:TENANT_INQUIRY] `lib/features/inquiry/widgets/contact_consent_notice.dart` | Privacy notice confirming contact sharing rules

---

### Tab 4: Alerts & Activity Feed (`ShellTab.alerts` / Index 3)
- [FLOW:TENANT_ALERTS] `lib/features/activity/view/activity_screen.dart` | Chronological activity feed showing inquiry updates, new match alerts, and status notifications
- [FLOW:TENANT_ALERTS] `lib/features/activity/widgets/activity_tile.dart` | Notification card with read/unread indicators and deep-link routing

---

### Tab 5: Profile & Preference Management (`ShellTab.profile` / Index 4)
- [FLOW:TENANT_PROFILE] `lib/features/profile/view/profile_screen.dart` | Profile dashboard with avatar, role badge, stats row (Saved, Inquiries, Matches), and settings
- [FLOW:TENANT_PROFILE] `lib/features/profile/widgets/profile_menu_card.dart` | Settings menu card (Preferences, Priorities, Theme, Privacy, Account Deletion, Logout)

#### Profile Sub-Screens & Editors:
1. [FLOW:TENANT_PROFILE] `lib/features/profile/view/saved_screen.dart` | "Saved Listings" bookmarks collection with quick unsave and property view
2. [FLOW:TENANT_PROFILE] `lib/features/profile/view/edit_constraints_screen.dart` | Edit hard constraints / must-haves (Max Budget, Gender Policy, WiFi, Occupancy, Smoking, Pets) — re-runs matching engine on save
3. [FLOW:TENANT_PROFILE] `lib/features/profile/view/soft_preferences_screen.dart` | Edit soft preferences & amenities (Air conditioning, furnished, parking, balcony, private bath)
4. [FLOW:TENANT_PROFILE] `lib/features/profile/view/edit_topsis_screen.dart` | Edit TOPSIS multi-criteria weights (adjust importance of Budget, Distance, and Amenities)
5. [FLOW:TENANT_PROFILE] `lib/features/auth/presentation/screens/privacy_notice_screen.dart` | Privacy policy and data handling notice
6. [FLOW:TENANT_PROFILE] `lib/features/account_deletion/presentation/screens/delete_account_screen.dart` | Account deletion workflow

---
---

## 2. LANDLORD / OWNER LOGGED-IN FLOW

### Root Shell & Tab Navigation
- [SHELL:OWNER] `lib/features/shell/view/landlord_shell.dart` | Root shell for landlords/owners; hosts `IndexedStack` with 5 navigation items and sets up `LandlordHomeCubit` and `ActivityCubit`
- [SHELL:OWNER] `lib/features/shell/widgets/floating_nav_bar.dart` | Floating nav bar with Home, Matches, quick Add (+) button, Alerts, and Profile

---

### Tab 1: Home Dashboard (`ShellTab.home` / Index 0)
- [FLOW:OWNER_HOME] `lib/features/landlord_home/view/landlord_home_screen.dart` | Landlord main dashboard: stats summary (listings, occupied, inquiries, matches), "Your listings" carousel, and "Compatible tenants" preview
- [FLOW:OWNER_HOME] `lib/features/landlord_home/widgets/compatible_tenants_section.dart` | Compatible tenants list showing unranked matching candidates
- [FLOW:OWNER_HOME] `lib/features/landlord_home/widgets/tenant_card.dart` | Summary card for a compatible tenant (name, match badge, requirements overview)
- [FLOW:OWNER_HOME] `lib/shared/widgets/pending_listing_banner.dart` | Verification status banner shown if account is pending admin approval

#### Sub-Screens & Actions from Landlord Home:
1. [FLOW:OWNER_HOME] `lib/features/landlord_home/view/tenant_detail_screen.dart` | Detailed tenant profile view (must-haves, budget, move-in date, invite to apply CTA)
2. [FLOW:OWNER_HOME] `lib/features/owner/view/owner_properties_screen.dart` | "My properties" full list screen (manage active, paused, booked, and unlisted rentals)
3. [FLOW:OWNER_HOME] `lib/features/owner/view/edit_property_screen.dart` | Edit existing property details, rent, photos, and rules

---

### Tab 2: Tenant Matches (`ShellTab.search` / Index 1)
- [FLOW:OWNER_MATCHES] `lib/features/landlord_matches/view/landlord_matches_screen.dart` | Matches tab listing all compatible tenants (bScore = 1) across all owner properties
- [FLOW:OWNER_MATCHES] `lib/features/landlord_home/widgets/compatible_tenants_section.dart` | Tenant list component embedded inside Matches screen
- [FLOW:OWNER_MATCHES] `lib/features/landlord_home/view/tenant_detail_screen.dart` | Tapping any tenant opens the detailed profile view
- [FLOW:OWNER_MATCHES] `lib/features/owner/view/find_tenants_screen.dart` | Dedicated tenant discovery screen with property filter and invite functionality

---

### Center Action: Add Property Flow (Index 2 Shortcut)
*Tapping the center Add button in `FloatingNavBar` triggers the multi-step property onboarding/listing wizard:*

1. [FLOW:ADD_PROPERTY] `lib/features/owner_onboarding/view/add_property_screen.dart` | Step 1: Basic property details (title, address, monthly rent, security deposit, description, photo upload)
2. [FLOW:ADD_PROPERTY] `lib/features/owner_onboarding/view/property_rules_screen.dart` | Step 2: Property rules & constraints (gender policy, pet policy, smoking policy, curfew, visitors)
3. [FLOW:ADD_PROPERTY] `lib/features/owner_onboarding/view/pricing_amenities_screen.dart` | Step 3: Pricing & amenities (utility inclusion, wifi, aircon, furnishing, room type)
4. [FLOW:ADD_PROPERTY] `lib/features/owner_onboarding/view/document_upload_screen.dart` | Step 4: Verification documents (proof of ownership, barangay clearance, government ID)
5. [FLOW:ADD_PROPERTY] `lib/features/owner_onboarding/view/verification_pending_screen.dart` | Step 5: Submission completion & admin review status

---

### Tab 3: Alerts & Activity Feed (`ShellTab.alerts` / Index 3)
- [FLOW:OWNER_ALERTS] `lib/features/activity/view/activity_screen.dart` | Landlord activity feed showing new tenant inquiries, admin document verifications, and chat messages
- [FLOW:OWNER_ALERTS] `lib/features/activity/widgets/activity_tile.dart` | Activity list tile

---

### Tab 4: Owner Profile & Inquiries (`ShellTab.profile` / Index 4)
- [FLOW:OWNER_PROFILE] `lib/features/profile/view/owner_profile_screen.dart` | Landlord profile dashboard with avatar, verification status card, and menu actions
- [FLOW:OWNER_PROFILE] `lib/features/owner/view/owner_properties_screen.dart` | Direct shortcut to "My properties" management
- [FLOW:OWNER_PROFILE] `lib/features/owner/view/owner_inquiries_screen.dart` | Landlord inquiry management center (tabs: Incoming inquiries, Sent invites, History)

#### Landlord Inquiry Handling & Chat:
- [FLOW:OWNER_INQUIRY] `lib/features/inquiry/view/inquiry_thread_screen.dart` | Live thread container for landlord
- [FLOW:OWNER_INQUIRY] `lib/features/inquiry/widgets/owner_phase1_view.dart` | Phase 1 view: Landlord reviews incoming tenant inquiry and decides to Accept or Decline
- [FLOW:OWNER_INQUIRY] `lib/features/inquiry/widgets/owner_invite_view.dart` | Invite view: Tracks sent invites to prospective tenants
- [FLOW:OWNER_INQUIRY] `lib/features/inquiry/widgets/inquiry_chat_view.dart` | Phase 2 view: Direct live chat with tenant after acceptance
- [FLOW:OWNER_PROFILE] `lib/features/auth/presentation/screens/privacy_notice_screen.dart` | Privacy policy
- [FLOW:OWNER_PROFILE] `lib/features/account_deletion/presentation/screens/delete_account_screen.dart` | Landlord account deletion workflow

---
---

## 3. SHARED LOGGED-IN COMPONENTS & SYSTEM CONTROLLERS

- [SHARED:SHELL] `lib/features/shell/cubit/shell_cubit.dart` | Controls active tab and navigation state
- [SHARED:SHELL] `lib/features/shell/widgets/floating_nav_bar.dart` | Custom floating bottom navigation bar
- [SHARED:GUEST] `lib/shared/widgets/guest_access_sheet.dart` | Bottom sheet prompting guest users to sign in when accessing restricted tabs
- [SHARED:BADGES] `lib/shared/widgets/match_badge.dart` | Match compatibility badge (e.g. 95% Match)
- [SHARED:BADGES] `lib/shared/widgets/ci_score_pill.dart` | Visual indicator for TOPSIS Ci score
- [SHARED:BADGES] `lib/shared/widgets/phase_badge.dart` | Inquiry phase indicator badge (Phase 1 vs Phase 2)
- [SHARED:BADGES] `lib/shared/widgets/verified_badge.dart` | Verified owner badge
- [SHARED:CARDS] `lib/shared/widgets/match_score_card.dart` | Detailed score breakdown card
- [SHARED:CARDS] `lib/shared/widgets/constraint_check_row.dart` | Visual checklist for rule/constraint satisfaction
- [SHARED:CAROUSEL] `lib/shared/widgets/property_photo_carousel.dart` | Swipeable full-bleed photo gallery
