# RentEase — Prototype Correct Flow Script
### Tenant ↔ Owner ↔ Admin Interaction Sequence

This document describes the **correct end-to-end flow** of the RentEase prototype, showing how the tenant, owner, and admin roles interact in sequence. Use this as a walkthrough reference or as a test script to validate the prototype behaves as designed.

---

## Actors

- **Tenant** — searching for a compatible boarding house
- **Owner** — listing a verified property, searching for compatible tenants
- **Admin** — verifies owner accounts, manages platform integrity

---

## Phase 0 — Admin Verifies Owner (Prerequisite)

1. Owner registers an account and submits verification documents.
2. Owner **cannot post a property yet** — `isVerified = false` blocks listing creation at the Firestore security-rule level, not just the UI.
3. Admin logs in (admin accounts are created manually in Firebase console — no self-registration).
4. Admin opens **Pending Verifications**, reviews the owner's submitted documents.
5. Admin taps **Approve**.
   - `isVerified` flips to `true` server-side.
   - Owner can now create property listings.

> Correct behavior check: an unverified owner attempting to list a property should be blocked even if they tamper with the client UI — enforcement is defined server-side in `firestore.rules`.
>
> **Prototype note:** in the current build the Approve action updates local demo state (with a confirmation snackbar); the live Firestore write is not yet wired. Show `firestore.rules` on screen if the panel asks about server-side enforcement.

---

## Phase 1 — Owner Lists a Property

1. Verified owner creates a property listing: rent, gender policy, WiFi, private bathroom, curfew, amenities, house rules, deposit, coordinates.
2. Listing becomes visible in the matching pool once saved.

---

## Phase 2 — Tenant Onboarding (5 Steps)

1. **Hard constraints** — tenant sets non-negotiable filters (max budget, gender policy, WiFi, private bathroom, curfew). *Layer 2 of the bilateral filter.*
2. **Soft preferences** — tenant sets nice-to-haves (room type, amenities). These refine ranking only, never disqualify.
3. **POI setup** — tenant pins school/workplace location on the map (`flutter_map` / OpenStreetMap in the prototype). Used for display and search-bar lookup only, **not** for distance calculation.
4. **Distance preference** — tenant sets a 0–10 km slider referencing the POI from Step 3. *(Order dependency: POI must exist first.)*
5. **TOPSIS weights** — tenant sets weight of Monthly Rent, Distance from POI, and Amenities Score. Defaults: 40% rent / 35% distance / 25% amenities. Total must equal exactly 100% before matches unlock.

> Correct behavior check: "Find My Matches" stays locked until weights sum to 100%.

After Step 5, a **"Finding your matches"** transition screen plays (constraints → bilateral check → TOPSIS ranking) before landing on Home. Owners get the mirror version ("Setting up your dashboard") after their onboarding. Narrate over it: *"this is the moment the matching runs server-side — computed once at profile save, not on every search."*

---

## Phase 3 — Server-Side Matching (Cloud Functions)

Triggered automatically the moment the tenant saves their profile (not recalculated on every search):

1. **Bilateral filter** runs both directions:
   - Layer 1 — owner-side constraints against tenant
   - Layer 2 — tenant-side constraints against property
   - Result: `B_score = 1` (compatible) or `B_score = 0` (incompatible)
2. **Two independent TOPSIS rankings** run, both server-side, never on-device:
   - **Tenant-facing ranking** — properties ranked by Rent, Distance (Haversine from stored coordinates), Amenities Score
   - **Owner-facing ranking** — tenants ranked by Intended Stay Duration, Credibility Score, Profile Completeness
3. Only pairs with `B_score = 1` appear in either ranked list.

> Correct behavior check: Haversine distance is used, not the Maps Distance Matrix API (cost control at scale).
>
> **Prototype note:** Cloud Functions are not yet implemented — B_scores and Ci scores are precomputed in mock data. Narrate this phase over the architecture diagram rather than clicking; the design (save-time computation, server-side only) is enforced in `firestore.rules` (`matches` collection is client-read-only).

---

## Phase 4 — Tenant Searches & Selects a Property

1. Tenant lands on Home / Search — sees only "Compatible properties," each already passed the bilateral filter.
2. Each card shows the TOPSIS Ci score (match %) and the owner's verified badge.
3. Tenant opens a compatible property (`B_score = 1`) → **Send Inquiry** button is present.
4. Incompatible properties (`B_score = 0`) **never appear in search results at all** — they are removed from the pool entirely, which is a stronger guarantee than hiding a button. Narrate: "and anywhere a B_score = 0 property could surface, the inquiry button is absent, not disabled."
5. (Optional) Tenant applies a session filter — a property that passes hard constraints but falls outside the session override shows **"Send Inquiry Anyway"**, demonstrating that session filters are exploratory and local-only, never written to Firestore.

> Correct behavior check: absent ≠ disabled. Absent means "not an option for this pairing," not "temporarily blocked."

---

## Phase 5 — Structured Two-Phase Inquiry

### Phase 5a — Auto Information Exchange (Chat Locked)

1. Tenant sends an inquiry to the property. *(Live in the prototype: the inquiry is created in the tenant's Inquiries tab AND appears in the owner's Incoming inbox — switch roles to show the same inquiry from both sides.)*
2. System auto-exchanges structured info — no free chat yet:
   - Owner sees the tenant's profile summary + "Passes all your rules" badge.
   - Tenant sees house rules, deposit, and owner's verified badge.
3. Owner opens the inquiry → sees locked chat input, with **Accept** / **Decline** buttons.

### Phase 5b — Open Chat (After Acceptance)

1. Owner taps **Accept**. *(Live: the tenant's copy of the inquiry flips to Phase 2 / "Chat is open" — worth switching back to the tenant to show it.)*
2. Full chat unlocks with quick-reply templates.
3. Once ready, owner marks the tenant as **Booked**.
4. Booking triggers the rating prompt on **both sides**: the owner is taken to the rating screen immediately after confirming the booking (rating the tenant), and the tenant rates the property from their **Inquiries tab** (tap the booked inquiry → rate).

> Correct behavior check: chat input must remain locked until the owner explicitly accepts.

---

## Phase 6 — Owner Searches & Selects a Tenant (Mirror Flow)

1. Owner opens **Find Tenants** on their property.
2. Sees the mirror TOPSIS ranking — tenants ranked by Intended Stay Duration, Credibility Score, Profile Completeness.
3. Only tenants with `B_score = 1` against this property appear.
4. Owner sends an invite to a compatible tenant.
5. Same absent-not-disabled rule applies: incompatible tenants don't show an invite option at all.

---

## Phase 7 — Post-Booking

1. Both tenant and owner rate each other after a confirmed booking.
2. Owner's listing and profile update to reflect completed matches (if applicable).

---

## Full Sequence Summary (Quick Reference)

```
Admin verifies Owner
        ↓
Owner lists Property
        ↓
Tenant completes 5-step onboarding
        ↓
Cloud Functions: bilateral filter (B_score) + dual TOPSIS ranking
        ↓
Tenant searches → sees only compatible properties → sends inquiry
        ↓
Phase 1 inquiry: structured info exchange (chat locked)
        ↓
Owner reviews → Accept / Decline
        ↓
Phase 2 inquiry: chat unlocked (only if Accepted)
        ↓
Owner marks tenant as Booked
        ↓
Rating prompt for both parties

(In parallel) Owner → Find Tenants → sees only compatible tenants → sends invite
```

---

## Notes for Testing / Demo Accuracy

- Role is **permanent** after signup — no switching between tenant and owner, enforced in UI and security rules.
- Session filters are **never persisted** to Firestore.
- Verification (`isVerified`) is **admin-only** and enforced **server-side** (`firestore.rules`), not just hidden in the UI.
- B_score is computed **once, at save-time** — not recalculated on every search action.

### Prototype limitations to be transparent about (if asked)

- **Mock data:** listings and matches come from precomputed mock data (B_score/Ci are not computed live). The **inquiry lifecycle, however, is fully simulated in-session**: a tenant's sent inquiry appears in the owner's inbox, Accept unlocks Phase 2 on both sides, Decline/Booked resolve it on both sides. State lives in memory — restarting the app resets it to the seeded data.
- **Cloud Functions:** not yet deployed; B_score/TOPSIS design is documented and enforced-by-design in `firestore.rules` (clients cannot write `matches`).
- **Maps:** the prototype uses `flutter_map` (OpenStreetMap tiles); the paper's Google Maps SDK integration is a deployment-phase swap.
