// Lossless JSON encoding for Firestore values (Timestamp, GeoPoint, refs, bytes).
const admin = require('firebase-admin');
const { Timestamp, GeoPoint, DocumentReference } = admin.firestore;

function encode(v) {
  if (v === null || typeof v !== 'object') return v;
  if (v instanceof Timestamp) return { __type: 'timestamp', seconds: v.seconds, nanoseconds: v.nanoseconds };
  if (v instanceof GeoPoint) return { __type: 'geopoint', latitude: v.latitude, longitude: v.longitude };
  if (v instanceof DocumentReference) return { __type: 'reference', path: v.path };
  if (Buffer.isBuffer(v) || v instanceof Uint8Array) return { __type: 'bytes', base64: Buffer.from(v).toString('base64') };
  if (Array.isArray(v)) return v.map(encode);
  const out = {};
  for (const [k, x] of Object.entries(v)) out[k] = encode(x);
  return out;
}

function decode(v, db) {
  if (v === null || typeof v !== 'object') return v;
  if (Array.isArray(v)) return v.map((x) => decode(x, db));
  switch (v.__type) {
    case 'timestamp': return new Timestamp(v.seconds, v.nanoseconds);
    case 'geopoint': return new GeoPoint(v.latitude, v.longitude);
    case 'reference': return db.doc(v.path);
    case 'bytes': return Buffer.from(v.base64, 'base64');
  }
  const out = {};
  for (const [k, x] of Object.entries(v)) out[k] = decode(x, db);
  return out;
}

module.exports = { encode, decode };
