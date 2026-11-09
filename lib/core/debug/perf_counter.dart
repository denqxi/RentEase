import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Debug-only Firestore read/write counter for performance baselines
/// (CLAUDE.md "Performance Testing"). Every method is a no-op in profile and
/// release builds (`kDebugMode` is a compile-time constant, so the counting
/// code is tree-shaken out of release APKs).
///
/// Counts what the client can see:
///  * reads: documents delivered from the SERVER by a get or a listener
///    update (cache hits are counted separately and are not billed). A query
///    that returns no documents still costs one read.
///  * writes: documents set, updated or deleted.
///
/// It cannot see the reads firestore.rules make internally (get()/exists()),
/// which are billed too; perf results report those as a separate estimate.
abstract final class PerfCounter {
  static final Map<String, int> _reads = {};
  static final Map<String, int> _cacheReads = {};
  static final Map<String, int> _writes = {};

  /// Monotonic count of every event, so a harness can wait until the app has
  /// gone quiet.
  static int _events = 0;
  static int get events => _events;

  static void reset() {
    _reads.clear();
    _cacheReads.clear();
    _writes.clear();
  }

  static int get totalReads => _sum(_reads);
  static int get totalCacheReads => _sum(_cacheReads);
  static int get totalWrites => _sum(_writes);

  /// Per-tag breakdown, e.g. {'matching.availableListings': 400}.
  static Map<String, int> get readsByTag => Map.unmodifiable(_reads);
  static Map<String, int> get writesByTag => Map.unmodifiable(_writes);

  static int _sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

  static void _add(Map<String, int> m, String tag, int n) {
    if (n <= 0) return;
    m[tag] = (m[tag] ?? 0) + n;
    _events++;
  }

  /// [listenerUpdate]: a later snapshot of a listener, billed only for the
  /// documents that changed. One-off gets and a listener's first snapshot
  /// bill every returned document, and at least one read.
  static void query(
    QuerySnapshot<Object?> snap,
    String tag, {
    bool listenerUpdate = false,
  }) {
    if (!kDebugMode) return;
    final n = listenerUpdate
        ? snap.docChanges.length
        : (snap.docs.isEmpty ? 1 : snap.docs.length);
    _add(snap.metadata.isFromCache ? _cacheReads : _reads, tag, n);
  }

  static void doc(DocumentSnapshot<Object?> snap, String tag) {
    if (!kDebugMode) return;
    _add(snap.metadata.isFromCache ? _cacheReads : _reads, tag, 1);
  }

  static void write(String tag, [int count = 1]) {
    if (!kDebugMode) return;
    _add(_writes, tag, count);
  }
}

extension CountedQuery<T extends Object?> on Query<T> {
  Future<QuerySnapshot<T>> countedGet(String tag) async {
    final snap = await get();
    PerfCounter.query(snap, tag);
    return snap;
  }

  Stream<QuerySnapshot<T>> countedSnapshots(String tag) {
    var first = true;
    return snapshots().map((snap) {
      PerfCounter.query(snap, tag, listenerUpdate: !first);
      first = false;
      return snap;
    });
  }
}

extension CountedDocument<T extends Object?> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> countedGet(String tag) async {
    final snap = await get();
    PerfCounter.doc(snap, tag);
    return snap;
  }

  Stream<DocumentSnapshot<T>> countedSnapshots(String tag) =>
      snapshots().map((snap) {
        PerfCounter.doc(snap, tag);
        return snap;
      });
}
