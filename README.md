# RentEase

A two-way boarding house rental matching platform for tenants and owners in
Davao City, Philippines. Built with Flutter and Firebase. Capstone research
project by Dumadapat, Item, and Samson — University of Mindanao.

The system's core contribution is a **dual-sided constraint-based filtering
engine** combined with **TOPSIS multi-criteria ranking**: tenants are matched
against properties (and vice versa) on hard constraints, then ranked for the
tenant by a weighted TOPSIS score. Communication between a tenant and owner
is only enabled once both sides pass the bilateral filter.

## Stack

- **Frontend:** Flutter (Dart), BLoC/Cubit for state
- **Backend:** Firebase — Authentication, Cloud Firestore. No Cloud
  Functions and no FCM push (both need a paid plan); in-app `notifications`
  docs stand in for push alerts.
- **Media:** Cloudinary (unsigned upload presets) for property photos and
  owner verification documents — not Firebase Storage.
- **Matching engine:** runs client-side in Dart (no Cloud Functions) —
  `FilteringService` for bilateral eligibility, `TopsisService` for ranking.
  See `CLAUDE.md` for the full architecture and the rules this project is
  built around.
- **Maps:** `flutter_map` + OpenStreetMap tiles for pin placement/display;
  `latlong2` (Haversine) for the actual distance calculation used in
  matching, not a maps routing/distance API.

## Getting started

```bash
flutter pub get
flutterfire configure   # or drop in your own firebase_options.dart
flutter run
```

Firestore security rules live in `firestore.rules`; deploy with
`firebase deploy --only firestore:rules`. Rules tests run against the local
emulator from `firestore-tests/` (`npm test`, requires
`firebase emulators:exec`).

## Where things stand

**Working end to end, backed by real Firestore data:**
- Tenant onboarding → bilateral filtering → TOPSIS ranking → Home/Search
- Owner onboarding → property listing (live immediately, unverified or not)
  → Find Tenants
- Owner verification is a trust-signal badge only: it gates nothing for
  `none`/`pending`/`verified` owners. A `rejected` status is the one
  exception — it blocks listing, inviting, and chatting.
- Admin screens (login, analytics, pending verifications with a document
  viewer, user/property management) — no self-registration
- Guest browsing (no account) with gated saving/inquiries/profile
- Structured two-phase inquiries: Send Inquiry → owner Accept/Decline →
  live chat → Mark as Booked → ratings, plus owner-initiated invites
- Contact privacy: email/phone live in a private subdoc; a phone number is
  shared per-inquiry only after acceptance, with a consent notice shown
  first
- Tenant profile/weight editing and owner property editing, both re-running
  the matching engine on save
- Property photos and verification documents upload to Cloudinary

**Still mock data / not built:**
- Rating aggregation into tenant credibility scores
- Cloud Functions / push notifications (permanently out of scope — no paid
  plan; in-app `notifications` docs cover alerts instead)

## Recent branch work (`samson`)

- **Removed the owner-side TOPSIS instance** (`ownerCi`/`ownerRank`, the
  owner weight-slider step, "Edit ranking") — the paper no longer describes
  a second instance, so owner-side tenant discovery is filtering-only.
- **Fixed a matching bug**: a booked/unlisted/unverified property's match
  row could survive indefinitely instead of being dropped, so it kept
  appearing as inquirable. Fixed in filtering, the UI, and the rules.
- **Built `InquiryService`**: the entire two-phase inquiry flow is now
  real, including the "fills my last vacancy" booking flow that takes a
  listing off the market atomically.
- **Reworked owner verification into a badge-only trust signal**: dropped
  the earlier "unverified owners are hidden/gated" design — listings,
  inquiries, invites, and chat all work regardless of verification status,
  with a `rejected` status as the one feature-blocking exception
  (`ownerNotRejected()` in `firestore.rules`).
- **Added contact privacy**: moved email/phone out of the world-readable
  user doc into a private subdoc; phone numbers are now shared per-inquiry
  only after acceptance.
- **Migrated off paid-plan-only Firebase features**: Cloudinary replaces
  Firebase Storage for photo/document uploads; `flutter_map` +
  OpenStreetMap replaces the Google Maps SDK; Cloud Functions stay
  permanently out of scope, with `firestore.rules` doing the independent
  server-side eligibility checks instead.
- **Made the edit screens save**: tenant preference/weight editing and
  owner property editing persist and re-trigger matching on save.

See `CLAUDE.md` for the full set of architectural rules and invariants this
project is held to (color tokens, the client-side matching engine, the
bilateral filter formulas, absolute rules like "role is permanent" and
"Send Inquiry is absent, never disabled").
