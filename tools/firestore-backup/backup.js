// Usage:
//   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\outside\repo\serviceAccount.json
//   node backup.js            -> backups/firestore-<timestamp>.json
// Reads every collection and subcollection (one read per document; Spark allows 50k/day).
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { encode } = require('./codec');

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();

async function dumpCollection(colRef, out) {
  // listDocuments also returns docs that exist only as parents of subcollections.
  const refs = await colRef.listDocuments();
  for (let i = 0; i < refs.length; i += 300) {
    const snaps = await db.getAll(...refs.slice(i, i + 300));
    for (const snap of snaps) {
      if (snap.exists) out[snap.ref.path] = encode(snap.data());
      for (const sub of await snap.ref.listCollections()) await dumpCollection(sub, out);
    }
  }
}

(async () => {
  const projectId = admin.app().options.projectId || process.env.GCLOUD_PROJECT || '(from key)';
  const docs = {};
  for (const col of await db.listCollections()) await dumpCollection(col, docs);
  fs.mkdirSync(path.join(__dirname, 'backups'), { recursive: true });
  const file = path.join(__dirname, 'backups', `firestore-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
  fs.writeFileSync(file, JSON.stringify({ projectId, createdAt: new Date().toISOString(), docs }, null, 2));
  const byCol = {};
  for (const p of Object.keys(docs)) byCol[p.split('/')[0]] = (byCol[p.split('/')[0]] || 0) + 1;
  console.log(`Backed up ${Object.keys(docs).length} documents to ${file}`);
  console.table(byCol);
})().catch((e) => { console.error(e); process.exit(1); });
