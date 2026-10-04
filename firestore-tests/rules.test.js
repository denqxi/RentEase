// Firestore security rules tests — covers SPRINTPLAN.md Day 2's checklist
// literally: tenantProfiles/ownerProfiles ownership, matches/inquiries
// visibility, messages participant-gating, and admin's broad access.
//
// Run with the emulator: from this directory,
//   npm install
//   firebase emulators:exec --only firestore,auth "npm test"
// (run from the repo root so the emulator picks up firebase.json/firestore.rules)

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const assert = require('assert');
const firebaseCompat = require('firebase/compat/app');
require('firebase/compat/firestore');
const FieldValue = firebaseCompat.default.firestore.FieldValue;

const PROJECT_ID = 'rentease-rules-test';

let testEnv;

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

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

/** Seeds documents with security rules disabled (as the Admin SDK would). */
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

function asTenant(uid) {
  return testEnv.authenticatedContext(uid, { role: 'tenant' }).firestore();
}
function asOwner(uid) {
  return testEnv.authenticatedContext(uid, { role: 'owner' }).firestore();
}
function asAdmin(uid) {
  return testEnv.authenticatedContext(uid, { role: 'admin' }).firestore();
}

const TENANT_A = 'tenantA';
const TENANT_B = 'tenantB';
const OWNER_A = 'ownerA';
const OWNER_B = 'ownerB';
const ADMIN = 'admin1';
const PROPERTY = 'prop1';
const MATCH_ID = `${TENANT_A}_${PROPERTY}`;
// A valid 14-item-checklist selection: amenityScore must equal its length.
const AMENITIES = { amenityList: ['WiFi', 'CCTV'], amenityScore: 2 };

async function seedUsersAndProfiles() {
  await seed(async (db) => {
    await db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'active' });
    await db.doc(`users/${TENANT_B}`).set({ role: 'tenant', status: 'active' });
    await db.doc(`users/${OWNER_A}`).set({ role: 'owner', status: 'active' });
    await db.doc(`users/${OWNER_B}`).set({ role: 'owner', status: 'active' });
    await db.doc(`users/${ADMIN}`).set({ role: 'admin', status: 'active' });
    // Compatible-by-default profiles: inquiries/matches rules now re-derive
    // eligibility from tenantProfiles, which must exist (empty = Dart fallbacks).
    await db.doc(`tenantProfiles/${TENANT_A}`).set({});
    await db.doc(`tenantProfiles/${TENANT_B}`).set({});
    await db
      .doc(`ownerProfiles/${OWNER_A}`)
      .set({ verificationStatus: 'verified' });
    await db.doc(`properties/${PROPERTY}`).set({
      ownerId: OWNER_A,
      isAvailable: true,
      isVerified: true,
      vacancyStatus: 'available',
      amenityList: ['WiFi'],
      amenityScore: 1,
    });
  });
}

describe('tenantProfiles — tenants can only read/write their own', () => {
  beforeEach(seedUsersAndProfiles);

  it('a tenant can write their own tenantProfile', async () => {
    await assertSucceeds(
      asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 4500 }),
    );
  });

  it('a tenant cannot write another tenant\'s tenantProfile', async () => {
    await assertFails(
      asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_B}`).set({ maxBudget: 4500 }),
    );
  });
});

describe('tenantProfiles — read restricted to self, owners and admin', () => {
  beforeEach(seedUsersAndProfiles);
  const path = `tenantProfiles/${TENANT_A}`;

  it('self can read', async () => {
    await assertSucceeds(asTenant(TENANT_A).doc(path).get());
  });
  it('another tenant cannot read', async () => {
    await assertFails(asTenant(TENANT_B).doc(path).get());
  });
  it('an owner can read', async () => {
    await assertSucceeds(asOwner(OWNER_A).doc(path).get());
  });
  it('admin can read', async () => {
    await assertSucceeds(asAdmin(ADMIN).doc(path).get());
  });
  it('unauthenticated cannot read', async () => {
    await assertFails(testEnv.unauthenticatedContext().firestore().doc(path).get());
  });
  it('a tenant inquiry still passes pairEligible without reading others', async () => {
    await seed(async (db) => {
      await db.doc(`properties/${PROPERTY}`).set({
        ownerId: OWNER_A, isAvailable: true, monthlyRent: 3000, allowedGender: 'All',
        maxOccupants: 2, ...AMENITIES,
      });
      await db.doc(path).set({ maxBudget: 5000, groupSize: 1 });
      await db.doc(`matches/${MATCH_ID}`).set({
        tenantId: TENANT_A, propertyId: PROPERTY, ownerId: OWNER_A, bScore: 1,
      });
    });
    await assertSucceeds(
      asTenant(TENANT_A).doc('inquiries/inqPriv').set({
        matchId: MATCH_ID, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
        stage: 1, ownerDecision: 'pending',
      }),
    );
  });
});

describe('emergencyContact stays private', () => {
  beforeEach(seedUsersAndProfiles);
  const priv = `users/${TENANT_A}/private/contact`;

  it('self can store it in private contact', async () => {
    await assertSucceeds(
      asTenant(TENANT_A).doc(priv).set({ phone: '1', email: 'a@b.c', emergencyContact: 'Rosa 0917' }),
    );
  });
  it('admin can write it, another tenant cannot', async () => {
    await assertSucceeds(asAdmin(ADMIN).doc(priv).set({ emergencyContact: 'x' }));
    await assertFails(asTenant(TENANT_B).doc(priv).set({ emergencyContact: 'x' }));
    await assertFails(asOwner(OWNER_A).doc(priv).get());
  });
  it('must be a string', async () => {
    await assertFails(asTenant(TENANT_A).doc(priv).set({ emergencyContact: 5 }));
  });
  it('tenantProfiles create/update with emergencyContact is denied', async () => {
    const p = `tenantProfiles/${TENANT_A}`;
    await assertFails(asTenant(TENANT_A).doc(p).set({ maxBudget: 1, emergencyContact: 'x' }));
    await assertFails(asTenant(TENANT_A).doc(p).update({ emergencyContact: 'x' }));
  });
  it('self update that deletes legacy emergencyContact is allowed', async () => {
    await seed((db) =>
      db.doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 1, emergencyContact: 'Rosa' }),
    );
    await assertSucceeds(
      asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`)
        .update({ emergencyContact: FieldValue.delete() }),
    );
  });
});

describe('ownerProfiles / properties — owners can only read/write their own', () => {
  beforeEach(seedUsersAndProfiles);

  it('an owner can update their own ownerProfile (non-verification fields)', async () => {
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`ownerProfiles/${OWNER_A}`)
        .set({ verificationStatus: 'verified', businessName: 'x' }),
    );
  });

  it('an owner cannot self-approve verificationStatus from none to verified', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'none' }));
    await assertFails(
      asOwner(OWNER_B).doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'verified' }),
    );
  });

  it('a verified owner can write their own property', async () => {
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`properties/${PROPERTY}`)
        .set({ ownerId: OWNER_A, monthlyRent: 4000, isVerified: true, ...AMENITIES }),
    );
  });

  it('an owner cannot write another owner\'s property', async () => {
    await assertFails(
      asOwner(OWNER_B)
        .doc(`properties/${PROPERTY}`)
        .set({ ownerId: OWNER_A, monthlyRent: 1, ...AMENITIES }),
    );
  });

  it('a pending owner can create and edit their own unpublished property', async () => {
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }),
    );
    const db = asOwner(OWNER_B);
    await assertSucceeds(
      db.doc('properties/prop2').set({
        ownerId: OWNER_B, monthlyRent: 1000, isVerified: false, isAvailable: true, ...AMENITIES,
      }),
    );
    await assertSucceeds(db.doc('properties/prop2').update({ monthlyRent: 1200 }));
    await assertSucceeds(
      db.doc('properties/prop2').update({ vacancyStatus: 'booked', isAvailable: false }),
    );
  });

  it('a none-status owner (or one with no profile yet) can create an unpublished property', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'none' }));
    await assertSucceeds(
      asOwner(OWNER_B)
        .doc('properties/prop2')
        .set({ ownerId: OWNER_B, isVerified: false, ...AMENITIES }),
    );
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).delete());
    await assertSucceeds(
      asOwner(OWNER_B)
        .doc('properties/prop4')
        .set({ ownerId: OWNER_B, isVerified: false, ...AMENITIES }),
    );
  });

  it('a pending owner cannot publish a property (isVerified true), on create or update', async () => {
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }),
    );
    const db = asOwner(OWNER_B);
    await assertFails(
      db.doc('properties/prop2').set({ ownerId: OWNER_B, isVerified: true, ...AMENITIES }),
    );
    await seed((s) =>
      s.doc('properties/prop2').set({ ownerId: OWNER_B, isVerified: false, ...AMENITIES }),
    );
    await assertFails(db.doc('properties/prop2').update({ isVerified: true }));
  });

  it('a pending owner cannot write for someone else, nor can a rejected owner write at all', async () => {
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }),
    );
    await assertFails(
      asOwner(OWNER_B)
        .doc(`properties/${PROPERTY}`)
        .update({ monthlyRent: 1 }),
    );
    await assertFails(
      asOwner(OWNER_B).doc('properties/prop2').set({ ownerId: OWNER_A, ...AMENITIES }),
    );
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'rejected' }),
    );
    await assertFails(
      asOwner(OWNER_B).doc('properties/prop2').set({ ownerId: OWNER_B, ...AMENITIES }),
    );
  });

  it('a tenant cannot write properties', async () => {
    await assertFails(
      asTenant(TENANT_A)
        .doc('properties/prop2')
        .set({ ownerId: TENANT_A, isVerified: false, ...AMENITIES }),
    );
  });

  it('an unverified owner\'s property is visible to signed-in users and queryable by the matching engine', async () => {
    await seed(async (db) => {
      await db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' });
      await db.doc('properties/live').set({
        ownerId: OWNER_B, isAvailable: true, isVerified: false, ...AMENITIES,
      });
      await db.doc('properties/live/rooms/r1').set({ price: 1 });
    });
    await assertSucceeds(asTenant(TENANT_A).doc('properties/live').get());
    await assertSucceeds(asOwner(OWNER_A).doc('properties/live').get());
    await assertSucceeds(asTenant(TENANT_A).doc('properties/live/rooms/r1').get());
    await assertSucceeds(asAdmin(ADMIN).doc('properties/live').get());
    await assertSucceeds(
      asTenant(TENANT_A).collection('properties').where('isAvailable', '==', true).get(),
    );
    // Guests may read AVAILABLE listings (public browse) - see the guest block.
    await assertSucceeds(testEnv.unauthenticatedContext().firestore().doc('properties/live').get());
  });

  it('admin can publish an owner\'s property once approved', async () => {
    await seed((db) =>
      db.doc('properties/hidden').set({ ownerId: OWNER_B, isVerified: false, ...AMENITIES }),
    );
    await assertSucceeds(
      asAdmin(ADMIN).doc('properties/hidden').update({ isVerified: true }),
    );
  });

  it('a newly verified owner can publish their existing property', async () => {
    await seed(async (db) => {
      await db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'verified' });
      await db.doc('properties/hidden').set({ ownerId: OWNER_B, isVerified: false, ...AMENITIES });
    });
    await assertSucceeds(asOwner(OWNER_B).doc('properties/hidden').update({ isVerified: true }));
  });

  it('a property whose amenityScore does not match its amenityList is rejected', async () => {
    await assertFails(
      asOwner(OWNER_A)
        .doc('properties/prop3')
        .set({ ownerId: OWNER_A, amenityList: ['WiFi'], amenityScore: 14 }),
    );
  });

  it('a new owner can submit for verification (create as pending)', async () => {
    await assertSucceeds(
      asOwner(OWNER_B).doc(`ownerProfiles/${OWNER_B}`).set({
        verificationStatus: 'pending',
      }),
    );
  });

  it('a new owner cannot create their profile as already verified', async () => {
    await assertFails(
      asOwner(OWNER_B)
        .doc(`ownerProfiles/${OWNER_B}`)
        .set({ verificationStatus: 'verified' }),
    );
  });

  it('a rejected owner cannot move themselves back to pending', async () => {
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'rejected' }),
    );
    await assertFails(
      asOwner(OWNER_B)
        .doc(`ownerProfiles/${OWNER_B}`)
        .update({ verificationStatus: 'pending' }),
    );
  });
});

describe('profile edit screens: the exact partial updates they make', () => {
  beforeEach(seedUsersAndProfiles);

  it('a tenant can update just their constraints or weights', async () => {
    await seed((db) =>
      db.doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 4500, avgRating: 4 }),
    );
    const db = asTenant(TENANT_A);
    await assertSucceeds(
      db.doc(`tenantProfiles/${TENANT_A}`).update({
        maxBudget: 5000, requiredGender: 'Mixed / Any', needsWifi: true, maxDistanceKm: 4,
      }),
    );
    // Weights live in the private prefs doc (see the privacy describe below).
    await assertSucceeds(
      db.doc(`tenantProfiles/${TENANT_A}/private/prefs`).set(
        { wRent: 0.5, wDistance: 0.3, wAmenities: 0.2 }, { merge: true },
      ),
    );
  });

  it('a tenant still cannot touch computed rating fields', async () => {
    await seed((db) => db.doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 4500 }));
    await assertFails(
      asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`).update({ avgRating: 5 }),
    );
  });

  it('the owner can edit their listing and relist it', async () => {
    const db = asOwner(OWNER_A);
    await assertSucceeds(
      db.doc(`properties/${PROPERTY}`).update({
        title: 'Renamed', monthlyRent: 4200, maxOccupants: 2, curfewHours: null,
        amenityList: ['WiFi', 'CCTV'], amenityScore: 2, hasWifi: true,
      }),
    );
    await assertSucceeds(
      db.doc(`properties/${PROPERTY}`).update({ vacancyStatus: 'booked', isAvailable: false }),
    );
    await assertSucceeds(
      db.doc(`properties/${PROPERTY}`).update({ vacancyStatus: 'available', isAvailable: true }),
    );
  });

  it('an edit with a mismatched amenityScore is rejected', async () => {
    await assertFails(
      asOwner(OWNER_A)
        .doc(`properties/${PROPERTY}`)
        .update({ amenityList: ['WiFi'], amenityScore: 14 }),
    );
  });
});

describe('matches — client-side engine writes, gated to the tenant\'s own rows', () => {
  beforeEach(seedUsersAndProfiles);

  it('a tenant can create a match row for themselves against a real property', async () => {
    await assertSucceeds(
      asTenant(TENANT_A)
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 }),
    );
  });

  it('a tenant cannot create a match claiming a different ownerId than the property\'s real owner', async () => {
    await assertFails(
      asTenant(TENANT_A)
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_B, propertyId: PROPERTY, bScore: 1 }),
    );
  });

  it('a tenant cannot write a match row for a different tenant', async () => {
    await assertFails(
      asTenant(TENANT_B)
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 }),
    );
  });

  it('matches are readable only by the tenant/owner involved, or admin', async () => {
    await seed((db) =>
      db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 }),
    );
    await assertSucceeds(asTenant(TENANT_A).doc(`matches/${MATCH_ID}`).get());
    await assertSucceeds(asOwner(OWNER_A).doc(`matches/${MATCH_ID}`).get());
    await assertSucceeds(asAdmin(ADMIN).doc(`matches/${MATCH_ID}`).get());
    await assertFails(asTenant(TENANT_B).doc(`matches/${MATCH_ID}`).get());
  });

});

describe('matches — owner-side tenant discovery is read-only (no owner-side TOPSIS)', () => {
  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed((db) =>
      db.doc(`matches/${MATCH_ID}`).set({
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        bScore: 1,
        tenantCi: 0.8,
        tenantRank: 1,
      }),
    );
  });

  it('the match\'s own owner still cannot update it — owners never write to matches', async () => {
    await assertFails(
      asOwner(OWNER_A).doc(`matches/${MATCH_ID}`).update({ tenantCi: 0.99 }),
    );
  });

  it('the tenant can still refresh their own fields', async () => {
    await assertSucceeds(
      asTenant(TENANT_A).doc(`matches/${MATCH_ID}`).set(
        {
          tenantId: TENANT_A,
          ownerId: OWNER_A,
          propertyId: PROPERTY,
          bScore: 1,
          distanceKm: 2.5,
        },
        { merge: true },
      ),
    );
    await assertSucceeds(
      asTenant(TENANT_A).doc(`matches/${MATCH_ID}`).update({ tenantCi: 0.9, tenantRank: 1 }),
    );
  });
});

describe('inquiries — only for a real bScore=1 match belonging to the exact pairing', () => {
  beforeEach(seedUsersAndProfiles);

  it('a tenant can create an inquiry for a compatible (bScore=1) match', async () => {
    await seed((db) =>
      db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 }),
    );
    await assertSucceeds(
      asTenant(TENANT_A).doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        ownerDecision: 'pending',
      }),
    );
  });

  it('a tenant cannot create an inquiry against an incompatible (bScore=0) match', async () => {
    await seed((db) =>
      db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 0 }),
    );
    await assertFails(
      asTenant(TENANT_A).doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        ownerDecision: 'pending',
      }),
    );
  });

  it('a tenant cannot reuse a bScore=1 matchId that belongs to a different property/owner', async () => {
    // Match is genuinely compatible, but only for PROPERTY/OWNER_A.
    await seed((db) =>
      db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 }),
    );
    // Tenant tries to use it to message a different owner/property.
    await assertFails(
      asTenant(TENANT_A).doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_B,
        propertyId: 'prop2',
        stage: 1,
        ownerDecision: 'pending',
      }),
    );
  });

  it('inquiries are readable only by the participating tenant/owner, or admin', async () => {
    await seed((db) =>
      db.doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        ownerDecision: 'pending',
      }),
    );
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inq1').get());
    await assertSucceeds(asOwner(OWNER_A).doc('inquiries/inq1').get());
    await assertSucceeds(asAdmin(ADMIN).doc('inquiries/inq1').get());
    await assertFails(asTenant(TENANT_B).doc('inquiries/inq1').get());
  });
});

describe('inquiries — the exact writes and queries InquiryService makes', () => {
  const INQ = MATCH_ID; // InquiryService keys each inquiry by its match ID

  async function seedInquiry(fields = {}) {
    await seed(async (db) => {
      await db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 });
      await db.doc(`inquiries/${INQ}`).set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        status: 'pending',
        ownerDecision: 'pending',
        ...fields,
      });
    });
  }

  beforeEach(seedUsersAndProfiles);

  it('the tenant can list their inquiries (tenantId query) and look one up by matchId', async () => {
    await seedInquiry();
    const db = asTenant(TENANT_A);
    await assertSucceeds(db.collection('inquiries').where('tenantId', '==', TENANT_A).get());
    await assertSucceeds(
      db
        .collection('inquiries')
        .where('tenantId', '==', TENANT_A)
        .where('matchId', '==', MATCH_ID)
        .limit(1)
        .get(),
    );
  });

  it('the owner can list inquiries sent to them (ownerId query)', async () => {
    await seedInquiry();
    await assertSucceeds(
      asOwner(OWNER_A).collection('inquiries').where('ownerId', '==', OWNER_A).get(),
    );
  });

  it("an unfiltered or other-user query is rejected", async () => {
    await seedInquiry();
    await assertFails(asTenant(TENANT_B).collection('inquiries').get());
    await assertFails(
      asTenant(TENANT_B).collection('inquiries').where('tenantId', '==', TENANT_A).get(),
    );
  });

  it('the owner can accept (stage 2, accepted, active)', async () => {
    await seedInquiry();
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
  });

  it('the tenant cannot accept their own inquiry', async () => {
    await seedInquiry();
    await assertFails(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
  });

  it('the owner can decline with a reason, and mark an accepted inquiry booked', async () => {
    await seedInquiry();
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`inquiries/${INQ}`)
        .update({ ownerDecision: 'declined', status: 'declined', declineReason: 'Full' }),
    );
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertSucceeds(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }),
    );
  });

  it('status cannot be forged: tenant booking/closing, owner booking a pending inquiry, extra keys', async () => {
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}`).update({ status: 'closed' }));
    await seedInquiry();
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'pending', extra: 1 }));
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}`).update({ updatedAt: FieldValue.serverTimestamp() }));
  });

  it('no new inquiry can be opened on a fully booked property', async () => {
    await seed(async (db) => {
      await db
        .doc(`matches/${MATCH_ID}`)
        .set({ tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1 });
      await db.doc(`properties/${PROPERTY}`).update({ isAvailable: false, vacancyStatus: 'booked' });
    });
    await assertFails(
      asTenant(TENANT_A).doc(`inquiries/${INQ}`).set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        status: 'pending',
        ownerDecision: 'pending',
      }),
    );
  });

  it('the owner can book, take the listing off the market, and close other inquiries atomically', async () => {
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await seed((db) =>
      db.doc('inquiries/other').set({
        matchId: 'tenantB_prop1',
        tenantId: TENANT_B,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        status: 'pending',
        ownerDecision: 'pending',
      }),
    );
    const db = asOwner(OWNER_A);
    await assertSucceeds(
      db.collection('inquiries').where('ownerId', '==', OWNER_A).where('propertyId', '==', PROPERTY).get(),
    );
    const batch = db.batch();
    batch.update(db.doc(`inquiries/${INQ}`), { status: 'booked' });
    batch.update(db.doc(`properties/${PROPERTY}`), { vacancyStatus: 'booked', isAvailable: false });
    batch.update(db.doc('inquiries/other'), { status: 'closed' });
    await assertSucceeds(batch.commit());
  });

  it('a tenant cannot take a property off the market', async () => {
    await assertFails(
      asTenant(TENANT_A).doc(`properties/${PROPERTY}`).update({ isAvailable: false }),
    );
  });

  it('both sides can rate once booked — never before', async () => {
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertFails(
      asTenant(TENANT_A).collection('ratings').add({
        inquiryId: INQ, raterId: TENANT_A, ratedId: OWNER_A, raterRole: 'tenant', stars: 5,
      }),
    );
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'booked' });
    await assertSucceeds(
      asTenant(TENANT_A).collection('ratings').add({
        inquiryId: INQ, raterId: TENANT_A, ratedId: OWNER_A, raterRole: 'tenant', stars: 5,
      }),
    );
    await assertSucceeds(
      asOwner(OWNER_A).collection('ratings').add({
        inquiryId: INQ, raterId: OWNER_A, ratedId: TENANT_A, raterRole: 'owner', stars: 4,
      }),
    );
    await assertSucceeds(
      asTenant(TENANT_A)
        .collection('ratings')
        .where('inquiryId', '==', INQ)
        .where('raterId', '==', TENANT_A)
        .get(),
    );
  });

  it('the chat thread is streamable by both participants once open', async () => {
    await seedInquiry({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertSucceeds(
      asTenant(TENANT_A).collection(`inquiries/${INQ}/messages`).add({
        senderId: TENANT_A, senderRole: 'tenant', content: 'hi', isAutoGenerated: false,
      }),
    );
    await assertSucceeds(asOwner(OWNER_A).collection(`inquiries/${INQ}/messages`).get());
    await assertFails(asTenant(TENANT_B).collection(`inquiries/${INQ}/messages`).get());
  });
});

describe('unverified owner\'s listing — in the pool and inquirable (bScore 1)', () => {
  const LIVE = 'live';
  const LIVE_MATCH = `${TENANT_A}_${LIVE}`;
  const inquiry = {
    matchId: LIVE_MATCH, tenantId: TENANT_A, ownerId: OWNER_B, propertyId: LIVE,
    stage: 1, ownerDecision: 'pending',
  };
  const matchRow = { tenantId: TENANT_A, ownerId: OWNER_B, propertyId: LIVE, bScore: 1 };
  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed(async (db) => {
      await db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' });
      await db.doc(`properties/${LIVE}`).set({
        ownerId: OWNER_B, isAvailable: true, isVerified: false, ...AMENITIES,
      });
    });
  });

  it('a tenant can create a match row for an available listing', async () => {
    await assertSucceeds(asTenant(TENANT_A).doc(`matches/${LIVE_MATCH}`).set(matchRow));
  });

  it('a tenant cannot create a match row for an unavailable listing', async () => {
    await seed((db) => db.doc(`properties/${LIVE}`).update({ isAvailable: false }));
    await assertFails(asTenant(TENANT_A).doc(`matches/${LIVE_MATCH}`).set(matchRow));
  });

  it('a tenant cannot create a match row with a mismatched ownerId', async () => {
    await assertFails(
      asTenant(TENANT_A).doc(`matches/${LIVE_MATCH}`).set({ ...matchRow, ownerId: OWNER_A }),
    );
  });

  it('a tenant can inquire an unverified (pending) owner with a bScore 1 match', async () => {
    await seed((db) => db.doc(`matches/${LIVE_MATCH}`).set(matchRow));
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inq1').set(inquiry));
  });

  it('a tenant cannot inquire an unverified owner when the match is bScore 0', async () => {
    await seed((db) => db.doc(`matches/${LIVE_MATCH}`).set({ ...matchRow, bScore: 0 }));
    await assertFails(asTenant(TENANT_A).doc('inquiries/inq1').set(inquiry));
  });

  it('a tenant can inquire once the owner is verified', async () => {
    await seed(async (db) => {
      await db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'verified' });
      await db.doc(`matches/${LIVE_MATCH}`).set(matchRow);
    });
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inq1').set(inquiry));
  });
});

// ---------------------------------------------------------------------------
// Bilateral eligibility is re-derived by the rules (non-distance checks of
// FilteringService). The same parity_cases.json table is asserted against the
// Dart FilteringService in test/features/matching/rules_parity_test.dart.
// ---------------------------------------------------------------------------
describe('inquiries/invites — rules re-derive non-distance eligibility (bScore is not trusted)', () => {
  const PCASES = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'parity_cases.json'), 'utf8'),
  );
  const P = 'parityProp';
  const PM = `${TENANT_A}_${P}`;
  const inq = {
    matchId: PM, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: P,
    stage: 1, ownerDecision: 'pending',
  };
  const invite = { ...inq, initiatedBy: 'owner', status: 'pending' };

  async function seedPair(tp, prop, gender) {
    await seedUsersAndProfiles();
    await seed(async (db) => {
      await db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'active', gender });
      await db.doc(`tenantProfiles/${TENANT_A}`).set(tp);
      await db.doc(`properties/${P}`).set({
        ownerId: OWNER_A, isAvailable: true, ...AMENITIES, ...prop,
      });
      // The forged/stale row: bScore = 1 regardless of real compatibility.
      await db.doc(`matches/${PM}`).set({
        tenantId: TENANT_A, ownerId: OWNER_A, propertyId: P, bScore: 1,
      });
    });
  }

  for (const c of PCASES) {
    it(`parity: ${c.name} -> ${c.ok ? 'allowed' : 'denied'} (tenant inquiry + owner invite)`, async () => {
      await seedPair(c.tp, c.prop, c.gender);
      const run = c.ok ? assertSucceeds : assertFails;
      await run(asTenant(TENANT_A).doc('inquiries/inqP').set(inq));
      await run(asOwner(OWNER_A).doc(`inquiries/${PM}`).set(invite));
    });
  }

  it('stale match: owner edits property to disallow pets after the match -> inquiry and invite denied', async () => {
    await seedPair({ hasPet: true }, { petsAllowed: true }, 'Female');
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inqP').set(inq));
    await seed((db) => db.doc('inquiries/inqP').delete());
    await seed((db) => db.doc(`properties/${P}`).update({ petsAllowed: false }));
    await assertFails(asTenant(TENANT_A).doc('inquiries/inqP').set(inq));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${PM}`).set(invite));
  });

  it('missing tenantProfile -> inquiry and invite denied even with a bScore=1 row', async () => {
    await seedPair({}, {}, '');
    await seed((db) => db.doc(`tenantProfiles/${TENANT_A}`).delete());
    await assertFails(asTenant(TENANT_A).doc('inquiries/inqP').set(inq));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${PM}`).set(invite));
  });

  it('latitude sanity bound: POI beyond the radius in latitude -> denied; within -> allowed', async () => {
    const GeoPoint = firebaseCompat.default.firestore.GeoPoint;
    await seedPair(
      { maxDistanceKm: 5, poiLatLng: new GeoPoint(7.3, 125.6) },
      { location: new GeoPoint(7.0, 125.6) }, '');
    await assertFails(asTenant(TENANT_A).doc('inquiries/inqP').set(inq)); // ~33 km
    await seed((db) => db.doc(`tenantProfiles/${TENANT_A}`).update({ maxDistanceKm: 40 }));
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inqP').set(inq));
  });

  it('matches: forged bScore=1 denied when incompatible; bScore 0 and compatible rows allowed', async () => {
    await seedPair({ maxBudget: 1000 }, { monthlyRent: 5000 }, '');
    await seed((db) => db.doc(`matches/${PM}`).delete());
    const row = { tenantId: TENANT_A, ownerId: OWNER_A, propertyId: P };
    await assertFails(asTenant(TENANT_A).doc(`matches/${PM}`).set({ ...row, bScore: 1 }));
    await assertSucceeds(asTenant(TENANT_A).doc(`matches/${PM}`).set({ ...row, bScore: 0 }));
    await assertFails(asTenant(TENANT_A).doc(`matches/${PM}`).update({ bScore: 1 }));
    await seed((db) => db.doc(`tenantProfiles/${TENANT_A}`).update({ maxBudget: 6000 }));
    await assertSucceeds(asTenant(TENANT_A).doc(`matches/${PM}`).update({ bScore: 1 }));
  });
});

describe('messages — participants only, free chat gated to stage 2 accepted', () => {
  beforeEach(seedUsersAndProfiles);

  async function seedInquiry(stage, ownerDecision) {
    await seed((db) =>
      db.doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage,
        ownerDecision,
      }),
    );
  }

  it('a non-participant cannot read messages', async () => {
    await seedInquiry(2, 'accepted');
    await seed((db) =>
      db
        .doc('inquiries/inq1/messages/m1')
        .set({ senderId: TENANT_A, isAutoGenerated: false }),
    );
    await assertFails(asTenant(TENANT_B).doc('inquiries/inq1/messages/m1').get());
    await assertSucceeds(asTenant(TENANT_A).doc('inquiries/inq1/messages/m1').get());
  });

  it('a participant cannot free-chat while stage 1 (locked)', async () => {
    await seedInquiry(1, 'pending');
    await assertFails(
      asTenant(TENANT_A)
        .doc('inquiries/inq1/messages/m1')
        .set({ senderId: TENANT_A, isAutoGenerated: false }),
    );
  });

  it('no chat writes once the thread is booked / closed / declined', async () => {
    for (const status of ['booked', 'closed', 'declined']) {
      await seed((db) =>
        db.doc('inquiries/inq1').set({
          matchId: MATCH_ID, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
          stage: 2, ownerDecision: 'accepted', status,
        }),
      );
      await assertFails(
        asTenant(TENANT_A).doc('inquiries/inq1/messages/m1')
          .set({ senderId: TENANT_A, isAutoGenerated: false }),
      );
    }
  });

  it('a participant can free-chat once stage 2 + accepted', async () => {
    await seedInquiry(2, 'accepted');
    await assertSucceeds(
      asTenant(TENANT_A)
        .doc('inquiries/inq1/messages/m1')
        .set({ senderId: TENANT_A, isAutoGenerated: false }),
    );
  });
});

const LOG = (action) => ({
  adminId: ADMIN,
  action,
  targetId: 't1',
  targetType: 'owner',
  reason: '',
  createdAt: FieldValue.serverTimestamp(),
});

describe('admin — broad read/write for moderation collections', () => {
  beforeEach(seedUsersAndProfiles);

  it('admin can approve owner verification', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }));
    await assertSucceeds(
      asAdmin(ADMIN).doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'verified' }),
    );
  });

  it('admin can read and write adminLogs; a regular user cannot', async () => {
    await assertSucceeds(asAdmin(ADMIN).doc('adminLogs/log1').set(LOG('approve_owner')));
    await assertSucceeds(asAdmin(ADMIN).doc('adminLogs/log1').get());
    await assertFails(asOwner(OWNER_A).doc('adminLogs/log1').get());
    await assertFails(asOwner(OWNER_A).doc('adminLogs/log2').set(LOG('approve_owner')));
    await assertFails(asTenant(TENANT_A).doc('adminLogs/log2').set(LOG('approve_owner')));
  });

  it('adminLogs entries are attributed to the acting admin and immutable', async () => {
    await assertFails(
      asAdmin(ADMIN).doc('adminLogs/x').set({ ...LOG('approve_owner'), adminId: 'someoneElse' }),
    );
    await assertFails(
      asAdmin(ADMIN).doc('adminLogs/x').set({ ...LOG('approve_owner'), createdAt: new Date(0) }),
    );
    await assertSucceeds(asAdmin(ADMIN).doc('adminLogs/x').set(LOG('approve_owner')));
    await assertFails(asAdmin(ADMIN).doc('adminLogs/x').update({ reason: 'edited' }));
    await assertFails(asAdmin(ADMIN).doc('adminLogs/x').delete());
  });

  it('admin approves an owner: profile + badge flags + log in one batch', async () => {
    await seed(async (db) => {
      await db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' });
      await db
        .doc('properties/pB')
        .set({ ownerId: OWNER_B, isVerified: false, isAvailable: true, ...AMENITIES });
    });
    const db = asAdmin(ADMIN);
    const batch = db.batch();
    batch.update(db.doc(`ownerProfiles/${OWNER_B}`), {
      verificationStatus: 'verified',
      verifiedAt: FieldValue.serverTimestamp(),
    });
    batch.update(db.doc('properties/pB'), { isVerified: true });
    batch.set(db.doc('adminLogs/l1'), LOG('approve_owner'));
    await assertSucceeds(batch.commit());
  });

  it('admin rejects an owner with a reason', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }));
    await assertSucceeds(
      asAdmin(ADMIN).doc(`ownerProfiles/${OWNER_B}`).update({
        verificationStatus: 'rejected',
        rejectedAt: FieldValue.serverTimestamp(),
        rejectionReason: 'Blurry ID',
      }),
    );
  });

  it('an owner cannot self-verify or set verifiedAt', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }));
    await assertFails(
      asOwner(OWNER_B).doc(`ownerProfiles/${OWNER_B}`).update({ verificationStatus: 'verified' }),
    );
    await assertFails(
      asOwner(OWNER_B).doc(`ownerProfiles/${OWNER_B}`).update({
        verifiedAt: FieldValue.serverTimestamp(),
      }),
    );
  });

  it('a tenant cannot approve or reject an owner', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }));
    await assertFails(
      asTenant(TENANT_A).doc(`ownerProfiles/${OWNER_B}`).update({ verificationStatus: 'verified' }),
    );
    await assertFails(
      asTenant(TENANT_A).doc(`ownerProfiles/${OWNER_B}`).update({ verificationStatus: 'rejected' }),
    );
  });

  it('admin can suspend and reactivate a user, but not change role or profile', async () => {
    await assertSucceeds(asAdmin(ADMIN).doc(`users/${TENANT_A}`).update({ status: 'suspended' }));
    await assertSucceeds(asAdmin(ADMIN).doc(`users/${TENANT_A}`).update({ status: 'active' }));
    await assertFails(asAdmin(ADMIN).doc(`users/${TENANT_A}`).update({ status: 'banned' }));
    await assertFails(asAdmin(ADMIN).doc(`users/${TENANT_A}`).update({ role: 'admin' }));
    await assertFails(
      asAdmin(ADMIN).doc(`users/${TENANT_A}`).update({ status: 'suspended', role: 'owner' }),
    );
  });

  it('a user cannot suspend or reactivate anyone, including themselves', async () => {
    await assertFails(asTenant(TENANT_B).doc(`users/${TENANT_A}`).update({ status: 'suspended' }));
    await assertFails(asTenant(TENANT_A).doc(`users/${TENANT_A}`).update({ status: 'suspended' }));
    await seed((db) => db.doc(`users/${OWNER_B}`).update({ status: 'suspended' }));
    await assertFails(asOwner(OWNER_B).doc(`users/${OWNER_B}`).update({ status: 'active' }));
  });

  it('admin can unlist/relist a property; an owner cannot undo an admin unlist', async () => {
    await assertSucceeds(
      asAdmin(ADMIN)
        .doc(`properties/${PROPERTY}`)
        .update({ isAvailable: false, adminUnlisted: true }),
    );
    await assertFails(asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ isAvailable: true }));
    await assertFails(
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ adminUnlisted: false }),
    );
    await assertSucceeds(
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ monthlyRent: 4000 }),
    );
    await assertSucceeds(
      asAdmin(ADMIN)
        .doc(`properties/${PROPERTY}`)
        .update({ isAvailable: true, adminUnlisted: false }),
    );
    await assertSucceeds(
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ isAvailable: false }),
    );
  });

  it('admin cannot edit other property fields; non-admins cannot unlist others', async () => {
    await assertFails(asAdmin(ADMIN).doc(`properties/${PROPERTY}`).update({ monthlyRent: 1 }));
    await assertFails(
      asOwner(OWNER_B)
        .doc(`properties/${PROPERTY}`)
        .update({ isAvailable: false, adminUnlisted: true }),
    );
    await assertFails(
      asTenant(TENANT_A).doc(`properties/${PROPERTY}`).update({ isAvailable: false }),
    );
  });

  it('admin can run the dashboard queries; others cannot read inquiries/logs wholesale', async () => {
    await seed((db) =>
      db.doc('inquiries/i1').set({ tenantId: TENANT_A, ownerId: OWNER_A, status: 'booked' }),
    );
    await assertSucceeds(
      asAdmin(ADMIN).collection('inquiries').where('status', '==', 'booked').get(),
    );
    await assertSucceeds(asAdmin(ADMIN).collection('users').where('role', '==', 'owner').get());
    await assertSucceeds(
      asAdmin(ADMIN)
        .collection('ownerProfiles')
        .where('verificationStatus', '==', 'pending')
        .get(),
    );
    await assertSucceeds(
      asAdmin(ADMIN).collection('adminLogs').orderBy('createdAt', 'desc').limit(5).get(),
    );
    await assertFails(asTenant(TENANT_B).collection('inquiries').get());
    await assertFails(asTenant(TENANT_B).collection('adminLogs').get());
  });

  it('admin can read any report; a reporter can only read their own', async () => {
    await seed((db) => db.doc('reports/r1').set({ reporterId: TENANT_A, status: 'open' }));
    await assertSucceeds(asAdmin(ADMIN).doc('reports/r1').get());
    await assertSucceeds(asTenant(TENANT_A).doc('reports/r1').get());
    await assertFails(asTenant(TENANT_B).doc('reports/r1').get());
  });
});

describe('ownerProfiles/{uid}/private/documents � private verification links', () => {
  const DOCS = {
    documentUrls: ['https://x/a.jpg', 'https://x/b.jpg'],
    documentPublicIds: ['a', 'b'],
  };
  const path = (uid) => `ownerProfiles/${uid}/private/documents`;
  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'none' }));
  });

  it('owner can submit none->pending and write docs in one batch, then read them', async () => {
    const db = asOwner(OWNER_B);
    const batch = db.batch();
    batch.update(db.doc(`ownerProfiles/${OWNER_B}`), { verificationStatus: 'pending' });
    batch.set(db.doc(path(OWNER_B)), DOCS);
    await assertSucceeds(batch.commit());
    await assertSucceeds(db.doc(path(OWNER_B)).get());
  });

  it('owner can submit three documents (optional business permit)', async () => {
    await assertSucceeds(
      asOwner(OWNER_B).doc(path(OWNER_B)).set({
        documentUrls: ['https://x/a.jpg', 'https://x/b.jpg', 'https://x/c.jpg'],
        documentPublicIds: ['a', 'b', 'c'],
      }),
    );
  });

  it('owner cannot submit fewer than two documents', async () => {
    await assertFails(
      asOwner(OWNER_B).doc(path(OWNER_B)).set({
        documentUrls: ['https://x/a.jpg'],
        documentPublicIds: ['a'],
      }),
    );
    await assertFails(
      asOwner(OWNER_B).doc(path(OWNER_B)).set({ documentUrls: [], documentPublicIds: [] }),
    );
  });

  it('owner can resubmit while pending', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }));
    await assertSucceeds(asOwner(OWNER_B).doc(path(OWNER_B)).set(DOCS));
  });

  it('owner cannot write docs once verified', async () => {
    await assertFails(asOwner(OWNER_A).doc(path(OWNER_A)).set(DOCS));
  });

  it('owner cannot add extra fields', async () => {
    await assertFails(asOwner(OWNER_B).doc(path(OWNER_B)).set({ ...DOCS, isVerified: true }));
  });

  it('another owner cannot read or write', async () => {
    await seed((db) => db.doc(path(OWNER_B)).set(DOCS));
    await assertFails(asOwner(OWNER_A).doc(path(OWNER_B)).get());
    await assertFails(asOwner(OWNER_A).doc(path(OWNER_B)).set(DOCS));
  });

  it('a tenant and unauthenticated users cannot read', async () => {
    await seed((db) => db.doc(path(OWNER_B)).set(DOCS));
    await assertFails(asTenant(TENANT_A).doc(path(OWNER_B)).get());
    await assertFails(testEnv.unauthenticatedContext().firestore().doc(path(OWNER_B)).get());
  });

  it('admin can read and delete', async () => {
    await seed((db) => db.doc(path(OWNER_B)).set(DOCS));
    await assertSucceeds(asAdmin(ADMIN).doc(path(OWNER_B)).get());
    await assertSucceeds(asAdmin(ADMIN).doc(path(OWNER_B)).delete());
  });

  it('owner cannot delete their docs', async () => {
    await seed((db) => db.doc(path(OWNER_B)).set(DOCS));
    await assertFails(asOwner(OWNER_B).doc(path(OWNER_B)).delete());
  });

  it('a tenant can still read the public ownerProfiles doc', async () => {
    await assertSucceeds(asTenant(TENANT_A).doc(`ownerProfiles/${OWNER_A}`).get());
  });
});

describe('notifications — only an inquiry participant can notify the other participant', () => {
  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed((db) =>
      db.doc('inquiries/inq1').set({
        matchId: MATCH_ID,
        tenantId: TENANT_A,
        ownerId: OWNER_A,
        propertyId: PROPERTY,
        stage: 1,
        ownerDecision: 'pending',
      }),
    );
  });

  const notif = (recipientId, over = {}) => ({
    recipientId,
    type: 'inquiry',
    title: 't',
    body: 'b',
    relatedId: 'inq1',
    relatedType: 'inquiry',
    isRead: false,
    ...over,
  });

  it('tenant notifies the owner, and owner notifies the tenant', async () => {
    await assertSucceeds(asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A)));
    await assertSucceeds(
      asOwner(OWNER_A).collection('notifications').add(notif(TENANT_A, { type: 'inquiry_accepted' })),
    );
  });

  it('denies notifying yourself, a non-participant, a bad type or an unrelated inquiry', async () => {
    await assertFails(asTenant(TENANT_A).collection('notifications').add(notif(TENANT_A)));
    await assertFails(asTenant(TENANT_B).collection('notifications').add(notif(OWNER_A)));
    await assertFails(
      asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A, { type: 'verification' })),
    );
    await assertFails(
      asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A, { relatedId: 'nope' })),
    );
    await assertFails(
      asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A, { isRead: true })),
    );
  });

  describe('rolling chat alert (msg_{inquiryId}_{recipientId})', () => {
    const ID = `msg_inq1_${OWNER_A}`;
    const msg = (recipientId, over = {}) => notif(recipientId, { type: 'message', ...over });

    it('sender creates then overwrites the deterministic doc', async () => {
      const ref = asTenant(TENANT_A).doc(`notifications/${ID}`);
      await assertSucceeds(ref.set(msg(OWNER_A)));
      await assertSucceeds(ref.set(msg(OWNER_A, { title: 'New message again' })));
    });

    it('denies a message alert under a non-deterministic id', async () => {
      await assertFails(asTenant(TENANT_A).collection('notifications').add(msg(OWNER_A)));
    });

    it('overwrite cannot change recipient, type or inquiry, or stay read', async () => {
      await seed((db) => db.doc(`notifications/${ID}`).set({ ...msg(OWNER_A), isRead: true }));
      const ref = asTenant(TENANT_A).doc(`notifications/${ID}`);
      await assertFails(ref.set(msg(TENANT_A)));
      await assertFails(ref.set(msg(OWNER_A, { type: 'inquiry' })));
      await assertFails(ref.set(msg(OWNER_A, { relatedId: 'other' })));
      await assertFails(ref.set(msg(OWNER_A, { isRead: true })));
      await assertSucceeds(ref.set(msg(OWNER_A)));
    });

    it('non-participant cannot create or overwrite it', async () => {
      await assertFails(asTenant(TENANT_B).doc(`notifications/${ID}`).set(msg(OWNER_A)));
      await seed((db) => db.doc(`notifications/${ID}`).set(msg(OWNER_A)));
      await assertFails(asTenant(TENANT_B).doc(`notifications/${ID}`).set(msg(OWNER_A)));
    });

    it('recipient can still only mark it read', async () => {
      await seed((db) => db.doc(`notifications/${ID}`).set(msg(OWNER_A)));
      const ref = asOwner(OWNER_A).doc(`notifications/${ID}`);
      await assertSucceeds(ref.update({ isRead: true }));
      await assertFails(ref.update({ body: 'x' }));
    });
  });
});

// ───────────────────────── Owner invitations ─────────────────────────
describe('inquiries — owner invitations (initiatedBy owner)', () => {
  const INQ = MATCH_ID;
  const invite = (over = {}) => ({
    matchId: MATCH_ID,
    tenantId: TENANT_A,
    ownerId: OWNER_A,
    propertyId: PROPERTY,
    initiatedBy: 'owner',
    stage: 1,
    status: 'pending',
    ownerDecision: 'pending',
    ...over,
  });
  const seedMatch = (over = {}) =>
    seed((db) =>
      db.doc(`matches/${MATCH_ID}`).set({
        tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1, ...over,
      }),
    );
  const seedInvite = (over = {}) =>
    seed((db) => db.doc(`inquiries/${INQ}`).set(invite(over)));

  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seedMatch();
  });

  it('an owner can invite a compatible tenant', async () => {
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
  });

  it('allows an unverified or pending owner (verification is a badge only)', async () => {
    await seed((db) => db.doc(`ownerProfiles/${OWNER_A}`).set({ verificationStatus: 'pending' }));
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
  });

  it('denies when the match is bScore 0, missing, or for another pairing', async () => {
    await seedMatch({ bScore: 0 });
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
    await seedMatch({ tenantId: TENANT_B });
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
    await assertFails(asOwner(OWNER_A).doc('inquiries/nope').set(invite({ matchId: 'nope' })));
  });

  it('denies a doc id that is not the match id (duplicate threads)', async () => {
    await assertFails(asOwner(OWNER_A).doc('inquiries/dup').set(invite()));
  });

  it('denies an unavailable property, a property of another owner, or bad initial values', async () => {
    await seed((db) => db.doc(`properties/${PROPERTY}`).update({ isAvailable: false }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
    await seed((db) => db.doc(`properties/${PROPERTY}`).update({ isAvailable: true, ownerId: OWNER_B }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite()));
    await seed((db) => db.doc(`properties/${PROPERTY}`).update({ ownerId: OWNER_A }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite({ stage: 2 })));
    await assertFails(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite({ ownerDecision: 'accepted' })),
    );
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(invite({ status: 'active' })));
  });

  it('a tenant cannot create an owner-initiated invite, nor another owner invite as OWNER_A', async () => {
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}`).set(invite()));
    await assertFails(asOwner(OWNER_B).doc(`inquiries/${INQ}`).set(invite()));
  });

  it('the tenant can accept (stage 2 / accepted / active) and decline with a reason', async () => {
    await seedInvite();
    await assertSucceeds(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({
          stage: 2, ownerDecision: 'accepted', status: 'active',
          updatedAt: FieldValue.serverTimestamp(),
        }),
    );
    await seedInvite();
    await assertSucceeds(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ ownerDecision: 'declined', status: 'declined', declineReason: 'Found a place' }),
    );
  });

  it('the owner cannot accept or decline their own invitation', async () => {
    await seedInvite();
    await assertFails(
      asOwner(OWNER_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
    await assertFails(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ ownerDecision: 'declined', status: 'declined' }),
    );
  });

  it('the tenant cannot skip steps, edit other fields, or re-answer a decided invite', async () => {
    await seedInvite();
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}`).update({ stage: 2 }));
    await assertFails(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'booked' }),
    );
    await assertFails(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active', propertyId: 'prop2' }),
    );
    await seedInvite({ ownerDecision: 'declined', status: 'declined' });
    await assertFails(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
  });

  it('the owner can mark an accepted invite booked or close a pending one, but not book early', async () => {
    await seedInvite();
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'closed' }));
    await seedInvite();
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
    await seedInvite({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
  });

  it('an accepted invitation unlocks messages for both sides; a pending one does not', async () => {
    await seedInvite();
    const msg = (uid, role) => ({
      senderId: uid, senderRole: role, content: 'hi', isAutoGenerated: false,
    });
    await assertFails(
      asTenant(TENANT_A).collection(`inquiries/${INQ}/messages`).add(msg(TENANT_A, 'tenant')),
    );
    await seedInvite({ stage: 2, ownerDecision: 'accepted', status: 'active' });
    await assertSucceeds(
      asTenant(TENANT_A).collection(`inquiries/${INQ}/messages`).add(msg(TENANT_A, 'tenant')),
    );
    await assertSucceeds(
      asOwner(OWNER_A).collection(`inquiries/${INQ}/messages`).add(msg(OWNER_A, 'owner')),
    );
  });

  it('invitation notification types are allowed for participants only', async () => {
    await seedInvite();
    const notif = (recipientId, type) => ({
      recipientId, type, title: 't', body: 'b', relatedId: INQ, relatedType: 'inquiry', isRead: false,
    });
    await assertSucceeds(
      asOwner(OWNER_A).collection('notifications').add(notif(TENANT_A, 'invitation')),
    );
    await assertSucceeds(
      asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A, 'invitation_accepted')),
    );
    await assertSucceeds(
      asTenant(TENANT_A).collection('notifications').add(notif(OWNER_A, 'invitation_declined')),
    );
    await assertFails(
      asTenant(TENANT_B).collection('notifications').add(notif(OWNER_A, 'invitation')),
    );
  });

  it('existing tenant-initiated rules still hold (owner decides, tenant cannot self-accept)', async () => {
    await seedInvite({ initiatedBy: 'tenant' });
    await assertFails(
      asTenant(TENANT_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
  });
});

// ───────────────────────── Suspension ─────────────────────────
describe('suspended accounts — reads of own users doc only, no writes', () => {
  const SUSP_T = 'suspTenant';
  const SUSP_O = 'suspOwner';

  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed(async (db) => {
      await db.doc(`users/${SUSP_T}`).set({ role: 'tenant', status: 'suspended' });
      await db.doc(`users/${SUSP_O}`).set({ role: 'owner', status: 'suspended' });
      await db.doc(`ownerProfiles/${SUSP_O}`).set({ verificationStatus: 'verified' });
      await db.doc(`tenantProfiles/${SUSP_T}`).set({ maxBudget: 1 });
      await db.doc('properties/suspProp').set({
        ownerId: SUSP_O, isAvailable: true, isVerified: false, ...AMENITIES,
      });
      await db.doc(`matches/${SUSP_T}_${PROPERTY}`).set({
        tenantId: SUSP_T, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1,
      });
      await db.doc('inquiries/susp1').set({
        matchId: `${SUSP_T}_${PROPERTY}`, tenantId: SUSP_T, ownerId: OWNER_A,
        propertyId: PROPERTY, stage: 2, status: 'active', ownerDecision: 'accepted',
      });
      await db.doc('notifications/n1').set({ recipientId: SUSP_T, isRead: false });
    });
  });

  it('can still read their own users doc', async () => {
    await assertSucceeds(asTenant(SUSP_T).doc(`users/${SUSP_T}`).get());
  });

  it('suspended tenant cannot write profile, matches, inquiries, messages, notifications', async () => {
    const db = asTenant(SUSP_T);
    await assertFails(db.doc(`tenantProfiles/${SUSP_T}`).set({ maxBudget: 5000 }));
    await assertFails(db.doc(`matches/${SUSP_T}_${PROPERTY}`).update({ bScore: 1 }));
    await assertFails(
      db.doc(`matches/${SUSP_T}_p2`).set({
        tenantId: SUSP_T, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1,
      }),
    );
    await assertFails(db.doc(`matches/${SUSP_T}_${PROPERTY}`).delete());
    await assertFails(
      db.doc('inquiries/new1').set({
        matchId: `${SUSP_T}_${PROPERTY}`, tenantId: SUSP_T, ownerId: OWNER_A,
        propertyId: PROPERTY, stage: 1, ownerDecision: 'pending',
      }),
    );
    await assertFails(db.doc('inquiries/susp1').update({ status: 'closed' }));
    await assertFails(
      db.collection('inquiries/susp1/messages').add({
        senderId: SUSP_T, senderRole: 'tenant', content: 'x', isAutoGenerated: false,
      }),
    );
    await assertFails(db.doc('notifications/n1').update({ isRead: true }));
  });

  it('suspended owner cannot write properties or ownerProfiles, or invite', async () => {
    const db = asOwner(SUSP_O);
    await assertFails(db.doc('properties/suspProp').update({ monthlyRent: 1, ...AMENITIES }));
    await assertFails(db.doc('properties/newProp').set({ ownerId: SUSP_O, ...AMENITIES }));
    await assertFails(db.doc(`ownerProfiles/${SUSP_O}`).update({ businessName: 'x' }));
    await seed((s) =>
      s.doc('matches/inv_match').set({
        tenantId: TENANT_A, ownerId: SUSP_O, propertyId: 'suspProp', bScore: 1,
      }),
    );
    await assertFails(
      db.doc('inquiries/inv_match').set({
        matchId: 'inv_match', tenantId: TENANT_A, ownerId: SUSP_O, propertyId: 'suspProp',
        initiatedBy: 'owner', stage: 1, status: 'pending', ownerDecision: 'pending',
      }),
    );
  });

  it('active users keep working (control)', async () => {
    await assertSucceeds(
      asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 4500 }),
    );
    await assertSucceeds(
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ monthlyRent: 3000, ...AMENITIES }),
    );
  });

  it('a user without a users doc yet (signup batch) is treated as active', async () => {
    await assertSucceeds(
      testEnv
        .authenticatedContext('brandNew')
        .firestore()
        .doc('tenantProfiles/brandNew')
        .set({ maxBudget: 1 }),
    );
  });
});

// ───────────────────────── Guest preview ─────────────────────────
describe('guests (unauthenticated) — public view of available listings only', () => {
  const guest = () => testEnv.unauthenticatedContext().firestore();

  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed(async (db) => {
      await db.doc('properties/gone').set({
        ownerId: OWNER_A, isAvailable: false, isVerified: true, ...AMENITIES,
      });
      await db.doc(`properties/${PROPERTY}/rooms/r1`).set({ price: 1 });
      await db.doc('properties/gone/rooms/r1').set({ price: 1 });
      await db.doc(`matches/${MATCH_ID}`).set({
        tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1,
      });
      await db.doc('inquiries/i1').set({
        matchId: MATCH_ID, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
        stage: 1, status: 'pending', ownerDecision: 'pending',
      });
      await db.doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 1 });
    });
  });

  it('can read an available property, its rooms, and run the guest feed query', async () => {
    await assertSucceeds(guest().doc(`properties/${PROPERTY}`).get());
    await assertSucceeds(guest().doc(`properties/${PROPERTY}/rooms/r1`).get());
    await assertSucceeds(
      guest().collection('properties').where('isAvailable', '==', true).limit(20).get(),
    );
  });

  it('cannot read an unavailable property or its rooms, or list unfiltered', async () => {
    await assertFails(guest().doc('properties/gone').get());
    await assertFails(guest().doc('properties/gone/rooms/r1').get());
    await assertFails(guest().collection('properties').get());
  });

  it('cannot read users, ownerProfiles, tenantProfiles, matches, inquiries', async () => {
    await assertFails(guest().doc(`users/${OWNER_A}`).get());
    await assertFails(guest().doc(`ownerProfiles/${OWNER_A}`).get());
    await assertFails(guest().doc(`tenantProfiles/${TENANT_A}`).get());
    await assertFails(guest().doc(`matches/${MATCH_ID}`).get());
    await assertFails(guest().collection('matches').where('bScore', '==', 1).get());
    await assertFails(guest().doc('inquiries/i1').get());
    await assertFails(guest().collection('inquiries/i1/messages').get());
  });

  it('cannot write anything', async () => {
    await assertFails(
      guest().doc('properties/x').set({ ownerId: OWNER_A, isAvailable: true, ...AMENITIES }),
    );
    await assertFails(guest().doc(`properties/${PROPERTY}`).update({ monthlyRent: 1 }));
  });
});

// ---------------------------------------------------------------------------
// Contact privacy: users/{uid}/private/contact and inquiries/{id}/contact/*
// ---------------------------------------------------------------------------
describe('contact privacy — users/{uid}/private/contact', () => {
  beforeEach(seedUsersAndProfiles);
  const CONTACT = { phone: '+639171234567', email: 'a@example.com' };

  it('the user can create, read and update their own private contact', async () => {
    const db = asTenant(TENANT_A);
    await assertSucceeds(
      db.doc(`users/${TENANT_A}/private/contact`).set({ ...CONTACT, updatedAt: FieldValue.serverTimestamp() }),
    );
    await assertSucceeds(db.doc(`users/${TENANT_A}/private/contact`).get());
    await assertSucceeds(
      db.doc(`users/${TENANT_A}/private/contact`).update({ phone: '09170000000' }),
    );
  });

  it('signup batch: users doc (no contact) and private contact are written together', async () => {
    const db = testEnv.authenticatedContext('newbie').firestore();
    const batch = db.batch();
    batch.set(db.doc('users/newbie'), { role: 'tenant', status: 'active', firstName: 'N' });
    batch.set(db.doc('users/newbie/private/contact'), CONTACT);
    await assertSucceeds(batch.commit());
  });

  it('another user, an owner of an inquiry with them, and guests are denied', async () => {
    await seed(async (db) => {
      await db.doc(`users/${TENANT_A}/private/contact`).set(CONTACT);
      await db.doc('inquiries/i1').set({
        tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
        stage: 2, ownerDecision: 'accepted', status: 'active',
      });
    });
    const path = `users/${TENANT_A}/private/contact`;
    await assertFails(asTenant(TENANT_B).doc(path).get());
    await assertFails(asOwner(OWNER_A).doc(path).get());
    await assertFails(asOwner(OWNER_B).doc(path).get());
    await assertFails(testEnv.unauthenticatedContext().firestore().doc(path).get());
    await assertFails(asOwner(OWNER_A).doc(path).set(CONTACT));
    await assertFails(asTenant(TENANT_B).doc(path).set(CONTACT));
  });

  it('admin can read it; extra fields and other doc ids are rejected', async () => {
    await seed(async (db) => db.doc(`users/${TENANT_A}/private/contact`).set(CONTACT));
    await assertSucceeds(asAdmin(ADMIN).doc(`users/${TENANT_A}/private/contact`).get());
    await assertFails(
      asTenant(TENANT_A).doc(`users/${TENANT_A}/private/contact`).set({ ...CONTACT, role: 'admin' }),
    );
    await assertFails(asTenant(TENANT_A).doc(`users/${TENANT_A}/private/other`).set(CONTACT));
  });

  it('a suspended user cannot write their private contact but can still read it', async () => {
    await seed(async (db) => {
      await db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'suspended' });
      await db.doc(`users/${TENANT_A}/private/contact`).set(CONTACT);
    });
    await assertFails(asTenant(TENANT_A).doc(`users/${TENANT_A}/private/contact`).set({ phone: '1' }));
    await assertSucceeds(asTenant(TENANT_A).doc(`users/${TENANT_A}/private/contact`).get());
  });

  it('users doc: new docs cannot hold phone/email; self may delete legacy ones, not add', async () => {
    const db = testEnv.authenticatedContext('newbie2').firestore();
    await assertFails(db.doc('users/newbie2').set({ role: 'tenant', status: 'active', phone: '1' }));
    await assertFails(db.doc('users/newbie2').set({ role: 'tenant', status: 'active', email: 'a@b.c' }));

    await seed(async (s) =>
      s.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'active', phone: '0917', email: 'a@b.c' }),
    );
    const me = asTenant(TENANT_A);
    // touching other fields while legacy contact stays is fine
    await assertSucceeds(me.doc(`users/${TENANT_A}`).update({ lastLoginAt: FieldValue.serverTimestamp() }));
    // changing legacy phone is not
    await assertFails(me.doc(`users/${TENANT_A}`).update({ phone: '0999' }));
    // the migration batch: copy to private + delete from public
    const f = testEnv.authenticatedContext(TENANT_A).firestore();
    const b = f.batch();
    b.set(
      f.doc(`users/${TENANT_A}/private/contact`),
      { phone: '0917', email: 'a@b.c', updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
    b.update(f.doc(`users/${TENANT_A}`), { phone: FieldValue.delete(), email: FieldValue.delete() });
    await assertSucceeds(b.commit());
    // role/status still protected, and the fields cannot come back
    await assertFails(me.doc(`users/${TENANT_A}`).update({ role: 'owner' }));
    await assertFails(me.doc(`users/${TENANT_A}`).update({ phone: '0917' }));
  });
});

describe('contact privacy — inquiries/{id}/contact/{role} (phone shared after accept)', () => {
  const INQ = 'inqShare';
  const share = (extra = {}) => ({ phone: '+639171234567', sharedAt: FieldValue.serverTimestamp(), ...extra });

  async function seedInq(fields = {}) {
    await seed(async (db) => {
      await db.doc(`inquiries/${INQ}`).set({
        matchId: INQ, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
        stage: 2, ownerDecision: 'accepted', status: 'active', ...fields,
      });
    });
  }
  beforeEach(seedUsersAndProfiles);

  it('each participant can write ONLY their own doc after acceptance (active or booked)', async () => {
    await seedInq();
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    await seedInq({ status: 'booked' });
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
  });

  it('denied before accept, when declined or closed', async () => {
    for (const f of [
      { stage: 1, ownerDecision: 'pending', status: 'pending' },
      { stage: 1, ownerDecision: 'declined', status: 'declined' },
      { stage: 2, ownerDecision: 'accepted', status: 'closed' },
    ]) {
      await seedInq(f);
      await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
      await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    }
  });

  it('denied for the counterpart, another role doc id, outsiders and guests', async () => {
    await seedInq();
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/other`).set(share()));
    await assertFails(asTenant(TENANT_B).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
    await assertFails(asOwner(OWNER_B).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    await assertFails(
      testEnv.unauthenticatedContext().firestore().doc(`inquiries/${INQ}/contact/tenant`).set(share()),
    );
  });

  it('only {phone, sharedAt} are allowed: no email, no extras, no missing sharedAt, no forged time', async () => {
    await seedInq();
    const doc = asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`);
    await assertFails(doc.set(share({ email: 'a@b.c' })));
    await assertFails(doc.set(share({ extra: 1 })));
    await assertFails(doc.set({ phone: '0917' }));
    await assertFails(doc.set({ phone: '0917', sharedAt: new Date('2020-01-01') }));
    await assertFails(doc.set(share({ phone: '' })));
    await assertFails(doc.set(share({ phone: 12345 })));
  });

  it('a suspended participant cannot share', async () => {
    await seedInq();
    await seed(async (db) => db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'suspended' }));
    await assertFails(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
  });

  it('readable by both participants and admin only', async () => {
    await seedInq();
    await seed(async (db) =>
      db.doc(`inquiries/${INQ}/contact/tenant`).set({ phone: '0917', sharedAt: new Date() }),
    );
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).get());
    await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/tenant`).get());
    await assertSucceeds(asAdmin(ADMIN).doc(`inquiries/${INQ}/contact/tenant`).get());
    // reading a not-yet-shared doc is also fine for a participant (empty snapshot)
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/owner`).get());
    await assertFails(asTenant(TENANT_B).doc(`inquiries/${INQ}/contact/tenant`).get());
    await assertFails(asOwner(OWNER_B).doc(`inquiries/${INQ}/contact/tenant`).get());
    await assertFails(
      testEnv.unauthenticatedContext().firestore().doc(`inquiries/${INQ}/contact/tenant`).get(),
    );
  });
});

// ───────────────────── Rejected owners cannot invite or chat ─────────────────────
describe('rejected owners — no invites, answers, chat or contact share', () => {
  const INQ = MATCH_ID;
  const setStatus = (status) =>
    seed((db) =>
      status === 'missing'
        ? db.doc(`ownerProfiles/${OWNER_A}`).delete()
        : db.doc(`ownerProfiles/${OWNER_A}`).set({ verificationStatus: status }),
    );
  const inq = (over = {}) => ({
    matchId: MATCH_ID, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY,
    stage: 1, status: 'pending', ownerDecision: 'pending', ...over,
  });
  const msg = (uid, role) => ({
    senderId: uid, senderRole: role, content: 'hi', isAutoGenerated: false,
  });
  const share = () => ({ phone: '+639171234567', sharedAt: FieldValue.serverTimestamp() });

  beforeEach(async () => {
    await seedUsersAndProfiles();
    await seed((db) =>
      db.doc(`matches/${MATCH_ID}`).set({
        tenantId: TENANT_A, ownerId: OWNER_A, propertyId: PROPERTY, bScore: 1,
      }),
    );
  });

  for (const status of ['none', 'pending', 'verified', 'missing']) {
    it(`${status} owner: invite, accept and chat still allowed`, async () => {
      await setStatus(status);
      await assertSucceeds(
        asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(inq({ initiatedBy: 'owner' })),
      );
      await seed((db) => db.doc(`inquiries/${INQ}`).set(inq()));
      await assertSucceeds(
        asOwner(OWNER_A).doc(`inquiries/${INQ}`)
          .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
      );
      await assertSucceeds(
        asOwner(OWNER_A).collection(`inquiries/${INQ}/messages`).add(msg(OWNER_A, 'owner')),
      );
      await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    });
  }

  it('rejected owner cannot create an invite', async () => {
    await setStatus('rejected');
    await assertFails(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`).set(inq({ initiatedBy: 'owner' })),
    );
  });

  it('rejected owner cannot accept or decline a tenant inquiry', async () => {
    await setStatus('rejected');
    await seed((db) => db.doc(`inquiries/${INQ}`).set(inq()));
    await assertFails(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`)
        .update({ stage: 2, ownerDecision: 'accepted', status: 'active' }),
    );
    await assertFails(
      asOwner(OWNER_A).doc(`inquiries/${INQ}`)
        .update({ ownerDecision: 'declined', status: 'declined' }),
    );
  });

  it('rejected owner cannot book or close (tenant inquiry and invite)', async () => {
    await setStatus('rejected');
    const active = { stage: 2, ownerDecision: 'accepted', status: 'active' };
    await seed((db) => db.doc(`inquiries/${INQ}`).set(inq(active)));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'closed' }));
    await seed((db) => db.doc(`inquiries/${INQ}`).set(inq({ ...active, initiatedBy: 'owner' })));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'booked' }));
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}`).update({ status: 'closed' }));
  });

  it('neither side can message a thread whose owner is rejected; no owner contact share', async () => {
    await seed((db) =>
      db.doc(`inquiries/${INQ}`).set(inq({ stage: 2, ownerDecision: 'accepted', status: 'active' })),
    );
    await setStatus('rejected');
    await assertFails(
      asOwner(OWNER_A).collection(`inquiries/${INQ}/messages`).add(msg(OWNER_A, 'owner')),
    );
    await assertFails(
      asTenant(TENANT_A).collection(`inquiries/${INQ}/messages`).add(msg(TENANT_A, 'tenant')),
    );
    await assertFails(asOwner(OWNER_A).doc(`inquiries/${INQ}/contact/owner`).set(share()));
    // the tenant may still share their own phone
    await assertSucceeds(asTenant(TENANT_A).doc(`inquiries/${INQ}/contact/tenant`).set(share()));
  });

  it('rejected owner still cannot write properties', async () => {
    await setStatus('rejected');
    await assertFails(
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).update({ monthlyRent: 1 }),
    );
  });
});

// ───────── Tenant map pin + TOPSIS weights are private (tenantProfiles/{uid}/private/prefs) ─────────
describe('tenant private prefs — POI pin and weights hidden from owners', () => {
  const GeoPoint = firebaseCompat.default.firestore.GeoPoint;
  const prefsPath = (uid) => `tenantProfiles/${uid}/private/prefs`;
  const prefs = (over = {}) => ({
    poiLatLng: new GeoPoint(7.07, 125.6), poiLabel: 'USEP', poiType: 'School',
    wRent: 0.35, wDistance: 0.35, wAmenities: 0.3, ...over,
  });
  beforeEach(seedUsersAndProfiles);

  it('the tenant (and admin) can write and read their own prefs; nobody else can read', async () => {
    await assertSucceeds(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).set(prefs()));
    await assertSucceeds(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).get());
    await assertSucceeds(asAdmin(ADMIN).doc(prefsPath(TENANT_A)).get());
    await assertFails(asOwner(OWNER_A).doc(prefsPath(TENANT_A)).get());
    await assertFails(asTenant(TENANT_B).doc(prefsPath(TENANT_A)).get());
    await assertFails(testEnv.unauthenticatedContext().firestore().doc(prefsPath(TENANT_A)).get());
  });

  it('only the tenant writes their prefs; a suspended tenant cannot; shape is validated', async () => {
    await assertFails(asTenant(TENANT_B).doc(prefsPath(TENANT_A)).set(prefs()));
    await assertFails(asOwner(OWNER_A).doc(prefsPath(TENANT_A)).set(prefs()));
    await assertFails(asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}/private/other`).set(prefs()));
    await assertFails(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).set(prefs({ extra: 1 })));
    await assertFails(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).set(prefs({ wRent: 'x' })));
    await assertFails(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).set(prefs({ poiLatLng: 'here' })));
    await seed((db) => db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'suspended' }));
    await assertFails(asTenant(TENANT_A).doc(prefsPath(TENANT_A)).set(prefs()));
  });

  it('the public tenantProfiles doc rejects the pin and weights on create and update', async () => {
    const t = asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`);
    await assertFails(t.set({ maxBudget: 4500, poiLatLng: new GeoPoint(7.07, 125.6) }));
    await assertFails(t.set({ maxBudget: 4500, poiLabel: 'USEP' }));
    await assertFails(t.set({ maxBudget: 4500, wRent: 0.35 }));
    await assertFails(t.update({ wDistance: 0.4 }));
    await assertFails(t.update({ poiType: 'School' }));
    await assertFails(t.update({ poiLatitude: 7.07 }));
    await assertSucceeds(t.set({ maxBudget: 4500, maxDistanceKm: 3 }));
  });

  it('legacy fields can be deleted by a self update; untouched leftovers do not block other edits', async () => {
    await seed((db) =>
      db.doc(`tenantProfiles/${TENANT_A}`).set({
        maxBudget: 4500, poiLatLng: new GeoPoint(7.07, 125.6), poiLabel: 'USEP',
        poiType: 'School', wRent: 0.35, wDistance: 0.35, wAmenities: 0.3,
      }),
    );
    const t = asTenant(TENANT_A).doc(`tenantProfiles/${TENANT_A}`);
    await assertSucceeds(t.update({ maxBudget: 5000 })); // leftovers untouched
    await assertFails(t.update({ wRent: 0.5 })); // but they cannot be changed
    await assertSucceeds(
      t.update({
        poiLatLng: FieldValue.delete(), poiLabel: FieldValue.delete(),
        poiType: FieldValue.delete(), wRent: FieldValue.delete(),
        wDistance: FieldValue.delete(), wAmenities: FieldValue.delete(),
      }),
    );
  });

  it('migration batch (copy to prefs + delete from profile) is allowed', async () => {
    await seed((db) =>
      db.doc(`tenantProfiles/${TENANT_A}`).set({
        maxBudget: 4500, poiLatLng: new GeoPoint(7.07, 125.6), poiLabel: 'USEP', wRent: 0.35,
      }),
    );
    const db = asTenant(TENANT_A);
    const batch = db.batch();
    batch.set(db.doc(prefsPath(TENANT_A)), prefs(), { merge: true });
    batch.update(db.doc(`tenantProfiles/${TENANT_A}`), {
      poiLatLng: FieldValue.delete(), poiLabel: FieldValue.delete(), wRent: FieldValue.delete(),
    });
    await assertSucceeds(batch.commit());
  });

  it('owners still read the public profile (budget, flags) with no pin or weights', async () => {
    await seed((db) => db.doc(`tenantProfiles/${TENANT_A}`).set({ maxBudget: 4500, school: 'USEP' }));
    const snap = await assertSucceeds(asOwner(OWNER_A).doc(`tenantProfiles/${TENANT_A}`).get());
    assert.strictEqual(snap.data().poiLatLng, undefined);
    assert.strictEqual(snap.data().wRent, undefined);
  });

  describe('latitude bound reads the private prefs doc', () => {
    const P = 'prefProp';
    const PM = `${TENANT_A}_${P}`;
    const inq = {
      matchId: PM, tenantId: TENANT_A, ownerId: OWNER_A, propertyId: P,
      stage: 1, ownerDecision: 'pending',
    };
    const invite = { ...inq, initiatedBy: 'owner', status: 'pending' };
    beforeEach(async () => {
      await seed(async (db) => {
        await db.doc(`tenantProfiles/${TENANT_A}`).set({ maxDistanceKm: 5 });
        await db.doc(`properties/${P}`).set({
          ownerId: OWNER_A, isAvailable: true, ...AMENITIES, location: new GeoPoint(7.0, 125.6),
        });
        await db.doc(`matches/${PM}`).set({
          tenantId: TENANT_A, ownerId: OWNER_A, propertyId: P, bScore: 1,
        });
      });
    });

    it('no prefs doc -> bound skipped; far pin -> denied; near pin -> allowed (inquiry and invite)', async () => {
      await assertSucceeds(asTenant(TENANT_A).doc('inquiries/i1').set(inq));
      await seed((db) => db.doc('inquiries/i1').delete());
      await seed((db) => db.doc(prefsPath(TENANT_A)).set(prefs({ poiLatLng: new GeoPoint(7.3, 125.6) })));
      await assertFails(asTenant(TENANT_A).doc('inquiries/i1').set(inq)); // ~33 km
      await assertFails(asOwner(OWNER_A).doc(`inquiries/${PM}`).set(invite));
      await assertFails(
        asTenant(TENANT_A).doc(`matches/${PM}`).update({ bScore: 1 }),
      );
      await seed((db) => db.doc(prefsPath(TENANT_A)).set(prefs({ poiLatLng: new GeoPoint(7.01, 125.6) })));
      await assertSucceeds(asTenant(TENANT_A).doc('inquiries/i1').set(inq));
      await seed((db) => db.doc('inquiries/i1').delete());
      await assertSucceeds(asOwner(OWNER_A).doc(`inquiries/${PM}`).set(invite));
    });
  });
});
