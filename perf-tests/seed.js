// Seeds the Firebase EMULATOR SUITE with perf-test data (CLAUDE.md
// "Performance Testing": never production). Reuses the rules-test tooling in
// ../firestore-tests (no service account key; @firebase/rules-unit-testing
// only ever talks to an emulator).
//
// Run from the repo root, with the emulators already running:
//   firebase emulators:start --only firestore,auth
//   set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//   set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
//   node perf-tests/seed.js
//
// Data: 1 verified owner, 520 available listings near one POI, and 3 tenants
// whose budgets make exactly 20 / 100 / 400 listings eligible:
//   20 x P2,000 | 80 x P3,000 | 300 x P4,000 | 120 x P9,000 (eligible for none)
//   perf.tenant20  budget P2,500 -> 20
//   perf.tenant100 budget P3,500 -> 100
//   perf.tenant400 budget P5,000 -> 400
// Estimated writes: 531 Firestore docs + 4 Auth accounts. Wipes the emulator
// project's Firestore and Auth data first.

const path = require('path');
const fs = require('fs');
const { createRequire } = require('module');

const req = createRequire(path.join(__dirname, '..', 'firestore-tests', 'package.json'));
const { initializeTestEnvironment } = req('@firebase/rules-unit-testing');
const firebaseCompat = req('firebase/compat/app');
req('firebase/compat/firestore');

// Same project id the app uses, so the app (pointed at the emulator) sees
// the data. Only the emulator is ever contacted.
const PROJECT_ID = 'renteasedb-4abb9';
const PASSWORD = process.env.PERF_PASSWORD || 'perf-test-only';
const POI = { lat: 7.0731, lng: 125.6128 }; // UM Matina, Davao City

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (!firestoreHost || !authHost) {
  console.error(
    'Refusing to run: set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST ' +
      '(emulator only, never production).',
  );
  process.exit(1);
}

const { GeoPoint, Timestamp } = firebaseCompat.default.firestore;

const AMENITIES = [
  'WiFi', 'Air conditioning', 'Electric fan', 'Private bathroom',
  'Laundry facility', 'Kitchen or cooking area', 'CCTV or security camera',
  'Parking space', 'Study area or desk', 'Refrigerator access',
  '24-hour access', 'Water included in rent', 'Electricity included in rent',
  'Furnished room',
];
const RENT_TIERS = [
  [20, 2000],
  [80, 3000],
  [300, 4000],
  [120, 9000],
];
const TENANTS = [
  { key: 'tenant20', budget: 2500, expected: 20 },
  { key: 'tenant100', budget: 3500, expected: 100 },
  { key: 'tenant400', budget: 5000, expected: 400 },
];

async function authCall(urlPath, body, owner = false) {
  const res = await fetch(`http://${authHost}${urlPath}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(owner ? { Authorization: 'Bearer owner' } : {}),
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${urlPath}: ${res.status} ${await res.text()}`);
  return res.json();
}

async function createAuthUser(email) {
  const { localId } = await authCall(
    '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key',
    { email, password: PASSWORD, returnSecureToken: true },
  );
  await authCall(
    `/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`,
    { localId, emailVerified: true },
    true,
  );
  return localId;
}

// Deterministic jitter so runs are repeatable; all within ~2 km of the POI.
function jitter(i) {
  const a = ((i * 7919) % 1000) / 1000 - 0.5;
  const b = ((i * 104729) % 1000) / 1000 - 0.5;
  return new GeoPoint(POI.lat + a * 0.03, POI.lng + b * 0.03);
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: firestoreHost.split(':')[0],
      port: Number(firestoreHost.split(':')[1]),
    },
  });

  await testEnv.clearFirestore();
  const del = await fetch(`http://${authHost}/emulator/v1/projects/${PROJECT_ID}/accounts`, {
    method: 'DELETE',
  });
  if (!del.ok) throw new Error(`clear auth: ${del.status}`);

  const ownerId = await createAuthUser('perf.owner@example.test');
  const tenants = [];
  for (const t of TENANTS) {
    tenants.push({ ...t, uid: await createAuthUser(`perf.${t.key}@example.test`) });
  }

  let writes = 0;
  const now = Date.now();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const ts = (msAgo) => Timestamp.fromMillis(now - msAgo);

    await db.collection('users').doc(ownerId).set({
      firstName: 'Perf', lastName: 'Owner', role: 'owner', gender: 'Male',
      status: 'active', createdAt: ts(86400000),
    });
    await db.collection('ownerProfiles').doc(ownerId).set({
      verificationStatus: 'verified', submittedAt: ts(86400000),
      verifiedAt: ts(80000000), updatedAt: ts(80000000),
    });
    writes += 2;

    for (const t of tenants) {
      const profile = db.collection('tenantProfiles').doc(t.uid);
      await db.collection('users').doc(t.uid).set({
        firstName: 'Perf', lastName: t.key, role: 'tenant', gender: 'Female',
        status: 'active', createdAt: ts(86400000),
      });
      await profile.set({
        maxBudget: t.budget, requiredGender: 'Any', needsWifi: false,
        maxDistanceKm: 10, isSmoker: false, hasPet: false, groupSize: 1,
        isSeeking: true, school: 'UM', updatedAt: ts(86400000),
      });
      await profile.collection('private').doc('prefs').set({
        poiLatLng: new GeoPoint(POI.lat, POI.lng), poiLabel: 'UM Matina',
        poiType: 'School', wRent: 0.35, wDistance: 0.35, wAmenities: 0.3,
        updatedAt: ts(86400000),
      });
      writes += 3;
    }

    let i = 0;
    for (const [count, rent] of RENT_TIERS) {
      // Batches of 400 (Firestore cap is 500 writes per batch).
      for (let start = 0; start < count; start += 400) {
        const batch = db.batch();
        for (let k = start; k < Math.min(count, start + 400); k++, i++) {
          const amenityList = AMENITIES.filter((_, n) => (i + n) % 3 === 0);
          batch.set(db.collection('properties').doc(`perf_prop_${String(i).padStart(3, '0')}`), {
            ownerId, title: `Perf Boarding House ${i}`, address: 'Matina, Davao City',
            location: jitter(i), geoHash: '', photos: [], photoPublicIds: [],
            monthlyRent: rent, depositAmount: rent, advanceMonths: 1,
            isAvailable: true, vacancyStatus: 'available', isVerified: true,
            allowedGender: 'Mixed / Any', smokingAllowed: false, petsAllowed: false,
            maxOccupants: 2, hasWifi: true, amenityList,
            amenityScore: amenityList.length, rentalType: 'entire_place',
            // Spread over the last ~9 days, oldest first.
            createdAt: ts((520 - i) * 1500000), updatedAt: ts((520 - i) * 1500000),
          });
          writes++;
        }
        await batch.commit();
      }
    }
  });

  await testEnv.cleanup();
  console.log(`Seeded ${writes} Firestore docs and ${1 + tenants.length} Auth accounts.`);
  for (const t of tenants) {
    console.log(`  perf.${t.key}@example.test  expected matches: ${t.expected}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
