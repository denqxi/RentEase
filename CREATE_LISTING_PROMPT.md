# RentEase — 6-Step Create Listing Implementation & Architecture Guide

## 1. Project Context & Non-Negotiable Constraints
- **Application:** RentEase (Flutter + Cloud Firestore + Cloudinary).
- **Goal:** Update the existing Create Listing flow into a 6-step wizard supporting **Entire Place** and **A Room**.
- **SCOPE BOUNDARY:** **DO NOT TOUCH THE HOME SCREEN (`landlord_home_screen.dart`).** Focus 100% on the **Create Listing process**, its step widgets, cubit, state, and models.
- **Core Algorithm Safety:** **Do NOT rewrite or alter the existing matching algorithm or Firestore Security Rules.**
  - **Bilateral Filtering** ($P_{score} \times T_{score}$) and **TOPSIS Ranking** ($C_i$) must remain 100% mathematically exact.
  - The Firestore Security Rules (`validAmenities()`, `amenityScore == amenityList.size()`, `bEligible()`) must pass with zero modifications.
  - Each room is created as its own 1:1 listing document in the `properties` collection, preserving direct, scalar matching on price, capacity, and amenities.

---

## 2. Specification & 6-Step Flow

### STEP 1 — Rental Type
- **Title:** What are you renting out?
- **Subtitle:** Choose what tenants can rent from you.
- **Option 1 (Card):** Entire Place
  - Description: *A whole house, apartment, or condo.*
- **Option 2 (Card):** A Room
  - Description: *A room in a boarding house, dorm, or shared home.*
- **Button:** Continue (determines Step 2 fields).

### STEP 2 — Property Details
**If Entire Place:**
- **Title:** Tell us about your place | **Subtitle:** Add the details tenants will see.
- Property Name — text input.
- Property Type — dropdown (`House`, `Apartment`, `Condominium`, `Studio Unit`, `Other`).
- Full Address — text input (supports reverse geocoding from map).
- Set Location — interactive map pin.
- Add Photos — Cloudinary image uploader (1–5 photos).
- **Buttons:**  Continue.

**If A Room:**
- **Title:** Tell us about your room | **Subtitle:** Choose the property where your room is located.
- Property Name — dropdown populated with the owner's existing saved properties, plus an option:
  - **`+ Add New Property`** (opens modal/sheet to input Property Name, Property Type, Full Address, and Pin Location).
- Selecting an existing property auto-fills and locks the saved address and coordinates.
- Room Name or Number — text input (e.g. `Room 101`) with duplicate validation per property.
- Listing Name Preview — auto-generated: `"${propertyName} – ${roomName}"`.
- Add Photos — room photos (1–5 photos).
- **Buttons:**  Continue.

### STEP 3 — House Rules
- **Title:** Set your house rules | **Subtitle:** Let tenants know what is allowed.
- Security Deposit (₱) — numeric input.
- Advance Rent (Months) — numeric input / selector.
- Who can rent? — `Anyone` / `Men only` / `Women only` (maps to `Mixed / Any`, `Male only`, `Female only`).
- Smoking Allowed — toggle.
- Pets Allowed — toggle.
- Curfew — dropdown / time selector (e.g. `No curfew`, `10:00 PM`).
- **Buttons:** Continue.

### STEP 4 — Rent & Occupants
- **Title:** Set the rent and capacity | **Subtitle:** How much is the rent, and how many people can stay?
- Monthly Rent (₱) — numeric input.
- Maximum Number of Occupants — numeric input.
- Available for Rent — toggle (defaults to `true`).
- **Buttons:**  Continue.

### STEP 5 — Amenities
- **Title:** What does your place have? | **Subtitle:** Select everything tenants can use.
- The fixed 14 amenities grouped into 4 intuitive categories:
  1. **Comfort & Internet:** WiFi, Air conditioning, Electric fan, Furnished room.
  2. **Bathroom & Facilities:** Private bathroom, Laundry facility, Kitchen or cooking area, Refrigerator access.
  3. **Safety & Convenience:** CCTV or security camera, Parking space, Study area or desk, 24-hour access.
  4. **Bills Included:** Water included in rent, Electricity included in rent.
- Note: `amenityScore` is strictly `amenityList.length` (satisfies Firestore rule `size <= 14`).
- **Buttons:**  Continue.

### STEP 6 — Review & Post Listing
- **Title:** Check your listing | **Subtitle:** Make sure everything is correct before posting.
- Review cards displaying: Listing Name, Rental Type, Address, Map Location, Cover Photo preview, House Rules, Rent & Occupancy, Availability, and Amenities.
- Edit button on each section returning to that specific step.
- **Buttons:** Post Listing (creates the listing and navigates back to Owner Home).

---

## 3. Exact Files to be Modified / Created

### 1. Data Model
* **`lib/core/firestore/models/property_doc.dart`**
  - Add optional fields:
    ```dart
    final String rentalType; // 'entire_place' | 'room' (default 'entire_place')
    final String? propertyName; // Parent building name (e.g. "GL Boardinghouse")
    final String? roomName;     // Room number/name (e.g. "Room 101")
    final String? propertyType; // "Boarding House", "House", "Apartment", etc.
    ```
  - Update `toMap()` and `fromMap()` to serialize these fields cleanly.

### 2. State Management (Wizard State)
* **`lib/features/owner_onboarding/cubit/owner_onboarding_state.dart`**
  - Extend state to retain all 6 steps in memory:
    - Step 1: `rentalType` ('entire_place' | 'room')
    - Step 2: `propertyName`, `propertyType`, `address`, `latitude`, `longitude`, `photos`, `roomName`
    - Step 3: `depositAmount`, `advanceMonths`, `allowedGender`, `smokingAllowed`, `petsAllowed`, `curfewHours`
    - Step 4: `monthlyRent`, `maxOccupants`, `isAvailable`
    - Step 5: `amenities` (List<String>)
    - Current step index: `currentStep` (0 to 5)
* **`lib/features/owner_onboarding/cubit/owner_onboarding_cubit.dart`**
  - Add navigation methods (`goToStep(int)`, `nextStep()`, `previousStep()`).
  - Add step-saver methods preserving state when moving backward or forward.
  - In `submitProperty(uid)`:
    - Generate `title = (rentalType == 'room' && roomName != null) ? '$propertyName – $roomName' : (propertyName ?? title)`.
    - Construct `PropertyDoc` with all matching fields populated.

### 3. Wizard Views
* **`lib/features/owner_onboarding/view/create_listing_wizard_screen.dart`** (New / Unified Wizard container)
  - Manages the 6-step progress indicator (`Step X of 6`), keyboard-safe scrolling, and consistent Continue buttons.
  - Hosts the 6 step bodies:
    - Step 1: `RentalTypeStep`
    - Step 2: `PropertyDetailsStep` (handles Entire Place vs A Room with saved property picker and new property modal)
    - Step 3: `HouseRulesStep`
    - Step 4: `RentOccupantsStep`
    - Step 5: `AmenitiesStep` (4 categorized amenity sections)
    - Step 6: `ReviewListingStep`
* **`lib/core/router/app_router.dart`**
  - Route `AppRouter.addProperty` to `CreateListingWizardScreen`.

---

## 4. Execution Guidance for the Next Agent
1. **Scope Restriction:**
   - **DO NOT TOUCH `landlord_home_screen.dart` or any Home screen widgets.**
2. **Preserve Database Compatibility:**
   - Do not change existing field types on `PropertyDoc` (`monthlyRent` must remain `num`, `amenityScore` must equal `amenityList.length`, etc.).
   - Do not alter `firestore.rules`.
3. **Preserve Location Services:**
   - Reuse the existing `GeocodingService` and OpenStreetMap `FlutterMap` picker from `add_property_screen.dart`.
4. **Preserve Image Uploads:**
   - Reuse `ImageUploadCubit` and `ImageUploadSlot` with Cloudinary.
5. **Test After Implementation:**
   - Run `dart analyze` to ensure 0 errors.
   - Run `flutter test test/features/owner/owner_properties_cubit_test.dart` to verify vacancy and property logic pass.
