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
- **Fonts:** DM Sans is bundled in `assets/fonts/` (weights 300–900). The app
  does not download fonts at runtime, so text renders offline.
- **Colors:** every color comes from `AppColors`
  (`lib/core/constants/app_colors.dart`); no hardcoded `Color(0x…)` or
  `Colors.*` anywhere else in `lib/`. To check:
  `rg "\bColors\.|Color\(0x|Color\.from" lib` should only match
  `app_colors.dart`.

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
   current app refreshes the sign-in token after verification. The rating
   flow (below) also needs the current rules and the review/notification
   indexes; an app build with the old rules cannot submit ratings.
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
5. **Enable Google sign-in** (Authentication → Sign-in method) and add the
   SHA-1 and SHA-256 fingerprint of every signing key you build with
   (`keytool -list -v -keystore ~/.android/debug.keystore -alias
   androiddebugkey -storepass android`) to the Android app whose package name
   matches `applicationId`, then download `google-services.json` again.
   Without the right fingerprint, Google sign-in fails with a generic error.

### Tests

```bash
flutter analyze
flutter test                      # unit and widget tests
cd firestore-tests && npm install
firebase emulators:exec --only firestore "cd firestore-tests && npm test"
```

The rules suite needs Node.js, the Firebase CLI and **Java (JDK 17+)** for the
emulator. `firestore-tests/` holds the rules suite (`rules.test.js`, plus
`security.test.js` with attacker-persona tests, including the rating-counter
attacks). `parity_cases.json` is asserted by both the rules tests and
`test/features/matching/rules_parity_test.dart` so the rules and
`FilteringService` cannot drift apart.

`/test/` is listed in `.gitignore`, so new test files are not committed
unless added with `git add -f test/`.

`test/screenshot_export_test.dart` exports screenshots of the screens; it
swallows offline asset errors, so it no longer flags layout exceptions on its
own.

## Where things stand

**Implemented, backed by real Firestore data:**

- **First launch:** the splash plays, then the intro carousel is shown once.
  After that, signed-out users go from the splash straight to sign-in
  (stored on the device with `shared_preferences`).
- **Tenant:** onboarding (hard constraints, soft preferences, POI pin with
  distance radius, TOPSIS weights) → bilateral filtering → TOPSIS ranking →
  Home and Search. Home shows ranked "Compatible properties" and, separately,
  view-only "Other listings" that do not match the saved preferences. Search
  can also browse non-matching listings behind a session-only toggle, with
  the reasons each one missed; Send Inquiry is absent for them. Preferences
  are edited in one place ("Rental preferences"), also reachable from the
  property detail screen.
- **Property detail:** photo carousel, owner and verification badge, ratings
  and reviews, and a persisted save (heart) button. Saved listings are stored
  per tenant and open the full details.
- **Owner:** onboarding with document upload (two required documents plus an
  optional business permit), property listing (live immediately) through a
  step-by-step wizard, photo editing, Find Tenants, and owner-initiated
  invitations. The owner home shows compatible-tenant counts per property from
  one owner-wide query.
- **Inquiries:** Send Inquiry → owner Accept/Decline → live chat → Mark as
  Booked → ratings. Chat unlocks only after acceptance.
- **Ratings** (after a booked inquiry, once per person per stay, never
  editable):
  - A tenant rates the **property**; an owner rates the **tenant**.
  - The **owner's rating is a roll-up** of their properties' ratings — the
    owner has no counter of their own.
  - Each rating is saved in one atomic batch together with its counter bumps
    (`totalRatings`, `ratingSum`) on the property (and its parent listing) or
    on the tenant profile. `firestore.rules` accepts a bump only if a real
    rating is created in the same batch (`lastRatingId`) and its stars equal
    the sum change.
  - Screens read the counters already on the documents they load (no extra
    reads). Written reviews are paged 20 at a time, newest first.
  - Ratings created before this design have no counters; a one-time admin
    backfill is needed to show them in the summaries (their review texts
    still list).
- **Owner verification** is a trust badge only: it gates nothing for
  `none`/`pending`/`verified` owners. A `rejected` status blocks listing,
  inviting and chatting.
- **Admin:** login, pending verifications with a document viewer and a
  NegosyoKonek business-permit lookup, user and property management,
  analytics, and an audit log (`adminLogs`). Routes are guarded to admins.
- **Guests** can browse real available listings without an account; saving,
  inquiring and profile actions are gated.
- **Notifications:** the Activity feed loads the 50 newest; unread badges and
  "mark all read" use a separate unread-only query, so they stay correct.
- **Contact privacy:** email and phone live in a private subdocument; a
  phone number is shared with the other party only after an inquiry is
  accepted, with a consent notice shown first. Emergency contact is never
  shared. A tenant's map pin and ranking weights are private to the tenant.
- **Privacy and deletion:** a versioned Privacy Notice screen, a required 18+
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
- Verification documents are publicly fetchable behind hard-to-guess
  Cloudinary links; this is a documented, accepted risk for the alpha.
- Ratings can be gamed by collusion: an owner marks a booking and a friend's
  account leaves a rating. Rules cannot prevent this; admin review can.
- Rating aggregation into tenant credibility scores is not built (tenant
  counters are stored, but nothing ranks by them yet).

## Security

- `firestore.rules` never trusts the client-written `bScore`: tenant
  inquiries, owner invites and `matches` writes re-derive the non-distance
  eligibility checks from the stored profiles and property.
- Writes that matter (inquiries, invites, chat, ratings, contact sharing,
  owner listings) require `email_verified`; sign-up and onboarding writes do
  not. Admin actions are exempt.
- Rating counters cannot be forged: a bump needs a rating created in the same
  batch, owned by the caller, tied to the inquiry's own property, with stars
  equal to the sum change; owners cannot bump or write their own counters;
  `ownerProfiles` rating fields are not writable by anyone.
- Documents have size and format limits (messages, ratings, titles, photo
  counts, Cloudinary-only links); inquiry ids must equal match ids.
- Private subdocuments (contact, tenant prefs, owner documents) are readable
  only by the owner of the data and admins.
- Details, findings and the console checklist (API-key restrictions, App
  Check, Cloudinary preset lockdown) are in `SECURITY_REPORT.md`, a local
  git-ignored document (see below).

## Performance notes

- The matching results are cached in `matches` and read by Home and Search;
  the Search tab does not recompute on every visit.
- Network images are decoded at roughly their displayed size (`cacheWidth`).
- Screens use `buildWhen`/`select` so large trees rebuild only when the data
  they show changes.
- Release builds use R8 code shrinking and resource shrinking.

## Before a Play Store release

- Change the application id from `com.example.rentease`, re-register it in
  Firebase, add the signing key fingerprints and replace `google-services.json`.
- Add a release signing key (currently the debug key is used), and test a
  release build.
- Restrict the Firebase API keys and enable App Check; review the merged
  Android manifest.
- Replace the placeholder privacy contact, add the missing items to the
  Privacy Notice (device location, Google sign-in data, ID-upload consent) and
  have it reviewed.
- Deploy the rules and indexes together with the release build.
- Run the rules tests against the emulator (needs Java).
- Backfill old ratings into counters if existing ratings must show.

## Project documents

`CLAUDE.md`, `DATA_DICTIONARY.md`, `SPRINTPLAN.md` and `SECURITY_REPORT.md`
are git-ignored working documents kept locally (the data dictionary and
security report describe the schema and the security review). Back them up
separately, or remove them from `.gitignore` if the team should share them.
