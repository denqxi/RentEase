/// Type of property a tenant is looking for.
enum PropertyType {
  apartment('Apartment'),
  boardingHouse('Boarding House'),
  studio('Studio'),
  house('House');

  const PropertyType(this.label);

  /// Human-readable label shown in the chip.
  final String label;
}
