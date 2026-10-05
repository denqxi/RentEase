import '../../../home/model/listing.dart';

/// Per-user saved listings (hearts), persisted in
/// users/{uid}/savedListings/{propertyId}.
abstract class SavedListingsRepository {
  /// Live set of the user's saved property ids.
  Stream<Set<String>> watchSavedIds(String uid);

  /// Saves [propertyId] (create only; the rules have no update). Throws on
  /// failure.
  Future<void> save(String uid, String propertyId);

  /// Removes [propertyId] from the saved set. Throws on failure.
  Future<void> unsave(String uid, String propertyId);

  /// The still-available properties among [propertyIds] as cards, fetched in
  /// chunks of 30 (the `whereIn` limit). Removed or unavailable ones are
  /// omitted. Order follows [propertyIds].
  Future<List<Listing>> fetchSavedListings(List<String> propertyIds);
}
