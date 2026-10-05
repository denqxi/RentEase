# RentEase

A two-way boarding house rental matching platform for tenants and owners in
Davao City, Philippines. Built with Flutter and Firebase. Capstone research
project by Dumadapat, Item, and Samson — University of Mindanao.

The system's core contribution is a **dual-sided constraint-based filtering
engine** combined with **TOPSIS multi-criteria ranking**: a tenant and a
property are matched only when both sides pass the bilateral filter, and the
compatible properties are then ranked for the tenant by a weighted TOPSIS
score. Owner-side discovery ("Find Tenants") uses the same bilateral filter
but is filtering-only — there is no owner-side TOPSIS. Communication between
a tenant and an owner is only enabled once the pair is compatible.

## Stack

- **Frontend:** Flutter (Dart), BLoC/Cubit for state, feature-first Clean
  Architecture (`lib/features/*`).
- **Backend:** Firebase Authentication and Cloud Firestore. There are **no
  Cloud Functions and no FCM push** (both need a paid plan, so they are
  permanently out of scope); in-app `notifications` documents stand in for
  push alerts.
- **Media:** Cloudinary (unsigned upload presets) for property photos and
  owner verification documents — not Firebase Storage.
- **Matching engine:** runs client-side in Dart — `FilteringService`
  (bilateral eligibility) and `TopsisService` (ranking) — and caches results
  in the `matches` collection. `firestore.rules` independently re-derives
  eligibility, so a modified client cannot forge a match (see Security).
- **Maps:** `flutter_map` + OpenStreetMap tiles for pin placement and the
  map view; `latlong2` (Haversine) for the actual distance used in matching,
  not a maps routing/distance API.

See `CLAUDE.md` for the full architecture and the rules this project is held
to (color tokens, the matching engine, the bilateral filter formulas, and
absolute rules such as "role is permanent" and "Send Inquiry is absent,
never disabled").

## Getting started

```bash
flutter pub get
flutterfire configure   # or drop in your own firebase_options.dart
flutter run
```

One-time setup for a new Firebase project:

1. **Deploy the Firestore rules and indexes:**
   `firebase deploy --only firestore:rules,firestore:indexes`.
   Deploy the rules together with the matching app build — the rules require
   a verified email for inquiries, chat, ratings and listings, and the
   current app refreshes the sign-in token after verification.
2. **Configure Cloudinary** in `lib/core/constants/cloudinary_config.dart`
   (cloud name and the two unsigned presets, one for property photos and one
   for verification documents). Presets should restrict formats to
   jpg/png/webp, cap the file size, lock the folder, and not reuse filenames.
   The documents preset must use public `upload` delivery so the admin viewer
   can render the images.
3. **Create the first admin** in the Firebase console: add an Authentication
   user, then create `users/{uid}` with `role: 'admin'` and
   `status: 'active'`. There is no admin sign-up flow.
4. **Set the privacy contact** in `lib/core/constants/app_config.dart`
   (`privacyContactEmail` is a placeholder).

### Tests

```bash
flutter analyze
flutter test                      # unit and widget tests
cd firestore-tests && npm install
firebase emulators:exec --only firestore "cd firestore-tests && npm test"
```

`firestore-tests/` holds the rules suite (`rules.test.js`, plus
`security.test.js` with attacker-persona tests). `parity_cases.json` is
asserted by both the rules tests and `test/features/matching/rules_parity_test.dart`
so the rules and `FilteringService` cannot drift apart.

`test/screenshot_export_test.dart` currently fails: its setup lacks some
providers and downloads Google Fonts at test time. It is a test-harness
problem, not an app bug.

## Where things stand

**Implemented, backed by real Firestore data:**

- **Tenant:** 4-step onboarding (hard constraints, POI pin, distance,
  TOPSIS weights) → bilateral filtering → TOPSIS ranking → Home and Search.
  Home shows ranked "Compatible properties" and, separately, view-only
  "Other listings" that do not match the saved preferences. Search can also
  browse non-matching listings behind a session-only toggle, with the reasons
  each one missed; Send Inquiry is absent for them.
- **Property detail:** photo carousel, owner and verification badge, and a
  persisted save (heart) button. Saved listings are stored per tenant and
  open the full details.
- **Owner:** onboarding with document upload (two required documents plus an
  optional business permit), property listing (live immediately), photo
  editing, Find Tenants, and owner-initiated invitations.
- **Inquiries:** Send Inquiry → owner Accept/Decline → live chat → Mark as
  Booked → ratings. Chat unlocks only after acceptance.
- **Owner verification** is a trust badge only: it gates nothing for
  `none`/`pending`/`verified` owners. A `rejected` status blocks listing,
  inviting and chatting.
- **Admin:** login, pending verifications with a document viewer and a
  NegosyoKonek business-permit lookup, user and property management,
  analytics, and an audit log (`adminLogs`). Routes are guarded to admins.
- **Guests** can browse real available listings without an account; saving,
  inquiring and profile actions are gated.
- **Contact privacy:** email and phone live in a private subdocument; a
  phone number is shared with the other party only after an inquiry is
  accepted, with a consent notice shown first. Emergency contact is never
  shared. A tenant's map pin and ranking weights are private to the tenant.
- **Privacy and deletion:** a Privacy Notice screen, a required 18+
  confirmation at sign-up, and in-app "Delete my account" (re-authenticates,
  removes the user's personal data; chats stay for the other party as
  "Deleted user"; Cloudinary images are removed manually on request).
- **Account safety:** suspended users are blocked from writing and are
  signed out; sign-in errors do not reveal whether an email exists.

**Known limits (by design — no paid server code):**

- No push notifications, custom-designed emails, or automatic deletion of
  Cloudinary images.
- The rules re-derive every eligibility check except **distance** (rules have
  no trigonometry; only a conservative latitude bound is applied) and cannot
  detect a user lying in their own profile.
- No server-side rate limiting beyond one inquiry per match and size limits.
- Verification documents are publicly fetchable behind unguessable
  Cloudinary links; this is a documented, accepted risk for the alpha.
- Rating aggregation into tenant credibility scores is not built.

## Security

- `firestore.rules` never trusts the client-written `bScore`: tenant
  inquiries, owner invites and `matches` writes re-derive the non-distance
  eligibility checks from the stored profiles and property.
- Writes that matter (inquiries, invites, chat, ratings, contact sharing,
  owner listings) require `email_verified`; sign-up and onboarding writes do
  not. Admin actions are exempt.
- Documents have size and format limits (messages, ratings, titles, photo
  counts, Cloudinary-only links); inquiry ids must equal match ids.
- Private subdocuments (contact, tenant prefs, owner documents) are readable
  only by the owner of the data and admins.
- Details, findings and the console checklist (API-key restrictions, App
  Check, Cloudinary preset lockdown) are in `SECURITY_REPORT.md`.

## Before a Play Store release

- Change the application id from `com.example.rentease`, re-register it in
  Firebase and replace `google-services.json`.
- Add a release signing key (currently the debug key is used), and turn on
  shrinking/obfuscation, then test a release build.
- Restrict the Firebase API keys, enable App Check, and review the merged
  Android manifest.
- Replace the placeholder privacy contact and have the Privacy Notice
  reviewed.
- Bundle the fonts instead of downloading them at runtime.

## Project documents

`CLAUDE.md`, `DATA_DICTIONARY.md`, `SPRINTPLAN.md` and `SECURITY_REPORT.md`
are git-ignored working documents kept locally (the data dictionary and
security report describe the schema and the security review). Back them up
separately, or remove them from `.gitignore` if the team should share them.
