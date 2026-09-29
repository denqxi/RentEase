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
- **Backend:** Firebase — Authentication, Cloud Firestore, Storage (photos/
  documents, not yet enabled), Cloud Messaging (not yet wired)
- **Matching engine:** runs client-side in Dart (no Cloud Functions) —
  `FilteringService` for bilateral eligibility, `TopsisService` for ranking.
  See `CLAUDE.md` for the full architecture and the rules this project is
  built around.
- **Maps:** Google Maps SDK for pin placement/display; `latlong2` (Haversine)
  for the actual distance calculation used in matching, not the Maps API

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
- Owner onboarding (admin approval) → property listing → Find Tenants
- Guest browsing (no account) with gated saving/inquiries/profile
- Structured two-phase inquiries: Send Inquiry → owner Accept/Decline →
  live chat → Mark as Booked → ratings
- Tenant profile/weight editing and owner property editing, both re-running
  the matching engine on save

**Still mock data / not built:**
- Landlord home dashboard (the owner's main screen)
- Admin screens (verification is console/script-only for now)
- Firebase Storage uploads (needs the paid Blaze plan)
- Push notifications, owner-initiated invites, rating aggregation into
  credibility scores

## Recent branch work (`samson`)

This branch merged in a separate UI-focused branch (`dumadapat`: splash
video, onboarding carousel, new app icons, guest browsing) on top of this
branch's Firebase backend work, then closed the gaps that merge left and
built out everything that was still mock data:

- **Removed the owner-side TOPSIS instance** (`ownerCi`/`ownerRank`, the
  owner weight-slider step, "Edit ranking") — the paper no longer describes
  a second instance, so owner-side tenant discovery is filtering-only.
- **Reconciled the UI merge**: kept this branch's real Firebase-backed auth/
  registration (the other branch predated the backend and wrote to
  `MockData`), took the genuine UI improvements, fixed a mis-added "Guest"
  role-picker option and a missing/broken guest entry point.
- **Fixed a matching bug**: a booked/unlisted/unverified property's match
  row could survive indefinitely instead of being dropped, so it kept
  appearing as inquirable. Fixed in filtering, the UI, and the rules.
- **Built `InquiryService`**: the entire two-phase inquiry flow was
  `MockData`-only before this; it's now real, including the "fills my last
  vacancy" booking flow that takes a listing off the market atomically.
- **Wired up Search**: was 100% mock; now reads real ranked matches with a
  working text search and session filter.
- **Made the edit screens save**: tenant preference/weight editing and
  owner property editing previously did nothing on "Save changes" — now
  they persist and re-trigger matching.

See `CLAUDE.md` for the full set of architectural rules and invariants this
project is held to (color tokens, the client-side matching engine, the
bilateral filter formulas, absolute rules like "role is permanent" and
"Send Inquiry is absent, never disabled").
