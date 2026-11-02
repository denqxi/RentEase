// Usage:
//   node restore.js backups/firestore-<timestamp>.json --confirm
// Writes every document back with set() (overwrites docs with the same path;
// does not delete anything else). Refuses to run without --confirm.
const fs = require('fs');
const admin = require('firebase-admin');
const { decode } = require('./codec');

const file = process.argv[2];
if (!file || !process.argv.includes('--confirm')) {
  console.error('Usage: node restore.js <backup.json> --confirm');
  process.exit(1);
}
admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();

(async () => {
  const { docs } = JSON.parse(fs.readFileSync(file, 'utf8'));
  const writer = db.bulkWriter();
  let n = 0;
  for (const [p, data] of Object.entries(docs)) {
    writer.set(db.doc(p), decode(data, db));
    n++;
  }
  await writer.close();
  console.log(`Restored ${n} documents.`);
})().catch((e) => { console.error(e); process.exit(1); });
