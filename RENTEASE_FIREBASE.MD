# RentEase Data Dictionary (Firebase Cloud Firestore)

This document contains the field names, data types, descriptions, and constraints for each collection in the RentEase Firestore database. Use this as the schema reference when setting up Firebase.

---

## 1. Users
Stores account information of all registered tenants, boarding house owners, and administrators.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| userId | String | User Identifier | Document ID |
| firstName | String | User's first name | Required |
| middleName | String | User's middle name | Optional |
| lastName | String | User's last name | Required |
| email | String | User's email | Unique, Required |
| gender | String | User gender | Required |
| phone | String | Mobile number | Required |
| role | String | System access role | Required |
| status | String | Account verification status | Required |
| profilePhoto | String | Avatar URL | Optional |
| fcmToken | String | Device token | Required |
| lastLoginAt | Timestamp | Last login | Auto-generated |
| createdAt | Timestamp | Account created | Auto-generated |

---

## 2. TenantProfiles
Stores rental preferences and profile information of tenants used during matching.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| userId | String | Tenant identifier | Document ID, references users |
| maxBudget | Number | Maximum budget | Required |
| requiredGender | String | Gender preference | Required |
| needsWifi | Boolean | WiFi requirement | Required |
| needsPrivateBath | Boolean | Bathroom type | Required |
| maxDistanceKm | Number | Maximum distance | Required |
| poiLatLng | GeoPoint | Point location | Required |
| poiLabel | String | Location name | Required |
| isSmoker | Boolean | Smoking status | Required |
| hasPet | Boolean | Pet ownership | Required |
| intendedStay | Number | Stay duration | Required |
| groupSize | Number | Occupant count | Required |
| school | String | School attended | Optional |
| occupation | String | Occupation | Optional |
| moveInDate | Timestamp | Preferred move-in date | Optional |
| emergencyContact | String | Emergency contact info | Optional |
| isSeeking | Boolean | Active search status | Required, default: true |
| wRent | Number | Rent weight | Required |
| wDistance | Number | Distance weight | Required |
| wAmenities | Number | Amenities weight | Required |
| avgRating | Number | Average rating | Computed |
| totalRatings | Number | Rating count | Computed |
| profileCompleteness | Number | Profile completion | Computed |
| credibilityScore | Number | Credibility score | Computed |
| updatedAt | Timestamp | Last update | Auto-generated |

---

## 3. OwnerProfiles
Stores verification details and profile information of boarding house owners.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| userId | String | Owner identifier | Document ID, references users |
| verificationStatus | String | Verification status | Required |
| documentUrls | Array\<String\> | Document URLs | Required |
| submittedAt | Timestamp | Document submission date | Required |
| verifiedAt | Timestamp | Approval date | Optional |
| rejectedAt | Timestamp | Rejection date | Optional |
| rejectionReason | String | Reason for rejection | Optional |
| wStayDuration | Number | Stay weight | Required |
| wCredibility | Number | Credibility weight | Required |
| wCompleteness | Number | Completion weight | Required |
| avgRating | Number | Average rating | Computed |
| totalRatings | Number | Rating count | Computed |
| propertyCount | Number | Listing count | Computed |
| updatedAt | Timestamp | Last update | Auto-generated |

---

## 4. Properties
Stores boarding house listing information created by verified owners.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| propertyId | String | Property identifier | Document ID |
| ownerId | String | Owner reference | References users |
| title | String | Property title | Required |
| description | String | Property description | Optional |
| address | String | Property address | Required |
| location | String | Property location | Required |
| geoHash | String | Location geohash | Required |
| photos | Array\<String\> | Property photos | Required |
| monthlyRent | Number | Monthly rent | Required |
| depositAmount | Number | Security deposit | Required |
| advanceMonths | Number | Advance payment | Required |
| isAvailable | Boolean | Availability flag (vacancyStatus == 'available') | Required |
| vacancyStatus | String | 'available' \| 'pending' \| 'booked' | Required |
| isVerified | Boolean | Verification status | Required |
| createdAt | Timestamp | Creation date | Auto-generated |
| updatedAt | Timestamp | Last updated | Auto-generated |
| allowedGender | String | Allowed gender | Required |
| smokingAllowed | Boolean | Smoking policy | Required |
| petsAllowed | Boolean | Pet policy | Required |
| maxOccupants | Number | Maximum occupant | Required |
| minStayMonths | Number | Minimum stay | Required |
| curfewHours | Number | Curfew hours | Optional |
| hasWifi | Boolean | WiFi availability | Required |
| bathroomType | String | Type of bathroom | Required |
| amenityList | Array\<String\> | Available amenities | Required |
| amenityScore | Number | Amenities score | Computed |

---

## 5. Rooms
Stores information about individual rooms within a boarding house property.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| roomId | String | Room identifier | Document ID |
| propertyId | String | Property reference | References properties |
| label | String | Room label | Required |
| maxOccupants | Number | Maximum occupants | Required |
| monthlyRent | Number | Monthly rent | Required |
| isAvailable | Boolean | Availability status | Required |
| photos | Array\<String\> | Room photos | Optional |
| notes | String | Room notes | Optional |

---

## 6. Matches
Stores compatibility results generated by dual-sided constraint-based filtering and TOPSIS.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| matchId | String | Match identifier | Document ID |
| tenantId | String | Tenant reference | References users |
| ownerId | String | Owner reference | References users |
| propertyId | String | Property reference | References properties |
| pScore | Number | Property score | Computed |
| tScore | Number | Tenant score | Computed |
| bScore | Number | Compatibility score | Computed |
| distanceKm | Number | Haversine distance from tenant POI (km) | Computed |
| tenantCi | Number | Tenant ranking (TOPSIS) | Computed |
| ownerCi | Number | Owner ranking | Computed |
| tenantRank | Number | Tenant rank | Computed |
| ownerRank | Number | Owner rank | Computed |
| computedAt | Timestamp | Computation date | Auto-generated |
| version | Number | Match version | Computed |

---

## 7. Inquiries
Stores rental inquiries exchanged between compatible tenants and owners.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| inquiryId | String | Inquiry identifier | Document ID |
| matchId | String | Match reference | References matches |
| tenantId | String | Tenant reference | References users |
| ownerId | String | Owner reference | References users |
| propertyId | String | Property reference | References properties |
| tenantCiSnapshot | Number | Match score | Required |
| stage | Number | Inquiry stage | Required |
| initiatedBy | String | Inquiry initiator | Required |
| status | String | Inquiry status | Required |
| ownerDecision | String | Owner decision | Required |
| declineReason | String | Decline reason | Optional |
| autoInfoSent | Boolean | Auto message sent | Required |
| createdAt | Timestamp | Creation date | Auto-generated |
| updatedAt | Timestamp | Last updated | Auto-generated |

---

## 8. Messages
Stores conversations exchanged between tenants and owners per inquiry.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| messageId | String | Message identifier | Document ID |
| senderId | String | Sender reference | References users |
| senderRole | String | Sender role | Required |
| content | String | Message content | Required |
| isAutoGenerated | Boolean | System message | Required |
| readAt | Timestamp | Read time | Optional |
| timeStamp | Timestamp | Sent time | Auto-generated |

---

## 9. Ratings
Stores feedback submitted by tenants and owners after a completed transaction.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| ratingId | String | Rating identifier | Document ID |
| inquiryId | String | Inquiry reference | References inquiries |
| raterId | String | Rater reference | References users |
| ratedId | String | Rated user | References users |
| raterRole | String | Rater role | Required |
| stars | Number | Star rating | Required |
| review | String | User review | Optional |
| createdAt | Timestamp | Submission date | Auto-generated |

---

## 10. Notifications
Stores system-generated notifications sent to users.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| notifId | String | Notification identifier | Document ID |
| recipientId | String | Recipient reference | References users |
| type | String | Notification type | Required |
| title | String | Notification title | Required |
| body | String | Notification message | Required |
| relatedId | String | Resource reference | References collection |
| relatedType | String | Resource type | Required |
| isRead | Boolean | Read status | Required |
| createdAt | Timestamp | Submission date | Auto-generated |

---

## 11. AdminLogs
Stores records of actions performed by administrators (audit trail).

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| logId | String | Log identifier | Document ID |
| adminId | String | Admin reference | References users |
| action | String | Admin action | Required |
| targetId | String | Target reference | References collection |
| targetType | String | Target type | Required |
| reason | String | Action reason | Required |
| createdAt | Timestamp | Action date | Auto-generated |

---

## 12. Reports
Stores reports submitted by users against other users or listings.

| Field Name | Data Type | Description | Constraints |
|---|---|---|---|
| reportId | String | Report identifier | Document ID |
| reporterId | String | Reporter reference | References users |
| targetId | String | Target reference | References collection |
| targetType | String | Target type | Required |
| reason | String | Report reason | Required |
| status | String | Report status | Required |
| createdAt | Timestamp | Action date | Auto-generated |

---

## Notes on Collection Relationships (for Firestore structuring)
- `users` is the root collection referenced by `TenantProfiles`, `OwnerProfiles`, `Properties.ownerId`, `Matches`, `Inquiries`, `Messages.senderId`, `Ratings`, `Notifications.recipientId`, `AdminLogs.adminId`, and `Reports.reporterId`.
- `Properties` → referenced by `Rooms.propertyId`, `Matches.propertyId`, `Inquiries.propertyId`.
- `Matches` → referenced by `Inquiries.matchId`.
- `Inquiries` → referenced by `Ratings.inquiryId`, and parent for `Messages` (subcollection recommended: `inquiries/{inquiryId}/messages/{messageId}`).
- Consider top-level collections for `Users`, `Properties`, `Matches`, `Inquiries`, `Reports`, `AdminLogs`, `Notifications`; use subcollections for `Rooms` (under `Properties`) and `Messages` (under `Inquiries`) to keep reads scoped and reduce query complexity.

---

## Implementation Status (applied to codebase)

- **Packages**: `firebase_core`, `firebase_auth`, `cloud_firestore` added to `pubspec.yaml`.
- **Collection paths**: `lib/core/firestore/firestore_collections.dart` (camelCase collection names; `rooms` under `properties`, `messages` under `inquiries`).
- **Typed models**: `lib/core/firestore/models/` — one `*Doc` class per collection with `fromSnapshot`/`toMap`, field names exactly as in this dictionary. Import via `models.dart` barrel.
- **Security rules**: `firestore.rules` — role permanence, admin-only verification, verified-owner-only property writes, Cloud-Functions-only `matches`, inquiry create requires `bScore == 1`, free chat only at stage 2 after owner accepts, immutable `adminLogs`.
- **Indexes**: `firestore.indexes.json` (match ranking, inquiry lists, notifications, pending verifications). `firebase.json` wires both for deploy.

### Remaining manual steps (require Google login — cannot be automated here)
1. Create the Firebase project at https://console.firebase.google.com (enable Auth Email/Password + Firestore).
2. `npm install -g firebase-tools` then `firebase login`.
3. `dart pub global activate flutterfire_cli` then `flutterfire configure` in the project root — generates `lib/firebase_options.dart` and `android/app/google-services.json`.
4. Add to `main.dart` before `runApp`: `WidgetsFlutterBinding.ensureInitialized(); await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
5. Deploy schema artifacts: `firebase deploy --only firestore:rules,firestore:indexes`.
6. Create the admin account manually in the Firebase console (no self-registration).