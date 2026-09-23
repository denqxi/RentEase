// Temporary diagnostic — reproduces the exact Firestore calls
// FilteringService/TopsisService/TenantOnboardingCubit make, in order, to
// find precisely which one the deployed rules deny.
const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertSucceeds } = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'rentease-diagnose';
let testEnv;

const { GeoPoint } = require('firebase/firestore');

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});
after(async () => { if (testEnv) await testEnv.cleanup(); });

const TENANT = 'tenantX';
const OWNER = 'ownerX';
const PROPERTY = 'propX';

it('walks the exact submit() sequence step by step', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc(`users/${TENANT}`).set({ role: 'tenant', status: 'active', gender: 'Female' });
    await db.doc(`users/${OWNER}`).set({ role: 'owner', status: 'active' });
    await db.doc(`ownerProfiles/${OWNER}`).set({ verificationStatus: 'verified' });
    await db.doc(`properties/${PROPERTY}`).set({
      ownerId: OWNER,
      isAvailable: true,
      isVerified: true,
      allowedGender: 'Mixed / Any',
      smokingAllowed: true,
      petsAllowed: true,
      maxOccupants: 5,
      monthlyRent: 3000,
      hasWifi: true,
      amenityList: ['WiFi'],
      amenityScore: 1,
      location: new GeoPoint(7.08, 125.61),
    });
  });

  const tenantDb = testEnv.authenticatedContext(TENANT).firestore();

  console.log('Step 1: saveProfile (tenantProfiles set merge)');
  await assertSucceeds(
    tenantDb.doc(`tenantProfiles/${TENANT}`).set(
      {
        maxBudget: 4500,
        requiredGender: 'Mixed / Any',
        needsWifi: true,
        maxDistanceKm: 5,
        poiLatLng: new GeoPoint(7.07, 125.6),
        poiLabel: 'Test POI',
        poiType: 'School',
        isSmoker: false,
        hasPet: false,
        groupSize: 1,
        isSeeking: true,
        wRent: 0.35,
        wDistance: 0.35,
        wAmenities: 0.30,
        updatedAt: new Date(),
      },
      { merge: true },
    ),
  );
  console.log('  OK');

  console.log('Step 2: FilteringService reads tenantProfiles');
  await assertSucceeds(tenantDb.doc(`tenantProfiles/${TENANT}`).get());
  console.log('  OK');

  console.log('Step 3: FilteringService reads users/{tenantId}.gender');
  await assertSucceeds(tenantDb.doc(`users/${TENANT}`).get());
  console.log('  OK');

  console.log('Step 4: FilteringService reads available+verified properties');
  await assertSucceeds(
    tenantDb.collection('properties').where('isAvailable', '==', true).where('isVerified', '==', true).get(),
  );
  console.log('  OK');

  const matchId = `${TENANT}_${PROPERTY}`;
  console.log('Step 5: FilteringService writes matches/{matchId} (create)');
  await assertSucceeds(
    tenantDb.doc(`matches/${matchId}`).set(
      {
        tenantId: TENANT,
        ownerId: OWNER,
        propertyId: PROPERTY,
        pScore: 1,
        tScore: 1,
        bScore: 1,
        distanceKm: 1.2,
        computedAt: new Date(),
      },
      { merge: true },
    ),
  );
  console.log('  OK');

  console.log('Step 6: TopsisService queries eligible matches');
  await assertSucceeds(
    tenantDb.collection('matches').where('tenantId', '==', TENANT).where('bScore', '==', 1).get(),
  );
  console.log('  OK');

  console.log('Step 7: TopsisService reads the property for rent/amenityScore');
  await assertSucceeds(tenantDb.doc(`properties/${PROPERTY}`).get());
  console.log('  OK');

  console.log('Step 8: TopsisService updates tenantCi/tenantRank on the match');
  await assertSucceeds(
    tenantDb.doc(`matches/${matchId}`).update({ tenantCi: 0.9, tenantRank: 1 }),
  );
  console.log('  OK — all steps passed');
});
