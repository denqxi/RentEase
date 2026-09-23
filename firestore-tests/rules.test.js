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

async function seedUsersAndProfiles() {
  await seed(async (db) => {
    await db.doc(`users/${TENANT_A}`).set({ role: 'tenant', status: 'active' });
    await db.doc(`users/${TENANT_B}`).set({ role: 'tenant', status: 'active' });
    await db.doc(`users/${OWNER_A}`).set({ role: 'owner', status: 'active' });
    await db.doc(`users/${OWNER_B}`).set({ role: 'owner', status: 'active' });
    await db.doc(`users/${ADMIN}`).set({ role: 'admin', status: 'active' });
    await db
      .doc(`ownerProfiles/${OWNER_A}`)
      .set({ verificationStatus: 'verified' });
    await db.doc(`properties/${PROPERTY}`).set({ ownerId: OWNER_A });
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

describe('ownerProfiles / properties — owners can only read/write their own', () => {
  beforeEach(seedUsersAndProfiles);

  it('an owner can update their own ownerProfile (non-verification fields)', async () => {
    await assertSucceeds(
      asOwner(OWNER_A)
        .doc(`ownerProfiles/${OWNER_A}`)
        .set({ verificationStatus: 'verified', documentUrls: ['a.png'] }),
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
      asOwner(OWNER_A).doc(`properties/${PROPERTY}`).set({ ownerId: OWNER_A, monthlyRent: 4000 }),
    );
  });

  it('an owner cannot write another owner\'s property', async () => {
    await assertFails(
      asOwner(OWNER_B).doc(`properties/${PROPERTY}`).set({ ownerId: OWNER_A, monthlyRent: 1 }),
    );
  });

  it('an unverified owner cannot create a property at all', async () => {
    await seed((db) =>
      db.doc(`ownerProfiles/${OWNER_B}`).set({ verificationStatus: 'pending' }),
    );
    await assertFails(
      asOwner(OWNER_B).doc('properties/prop2').set({ ownerId: OWNER_B, monthlyRent: 1000 }),
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

  it('a participant can free-chat once stage 2 + accepted', async () => {
    await seedInquiry(2, 'accepted');
    await assertSucceeds(
      asTenant(TENANT_A)
        .doc('inquiries/inq1/messages/m1')
        .set({ senderId: TENANT_A, isAutoGenerated: false }),
    );
  });
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
    await assertSucceeds(asAdmin(ADMIN).doc('adminLogs/log1').set({ action: 'approve' }));
    await assertFails(asOwner(OWNER_A).doc('adminLogs/log1').get());
  });

  it('admin can read any report; a reporter can only read their own', async () => {
    await seed((db) => db.doc('reports/r1').set({ reporterId: TENANT_A, status: 'open' }));
    await assertSucceeds(asAdmin(ADMIN).doc('reports/r1').get());
    await assertSucceeds(asTenant(TENANT_A).doc('reports/r1').get());
    await assertFails(asTenant(TENANT_B).doc('reports/r1').get());
  });
});
