/// The role a user signs up as.
enum UserRole {
  tenant(
    label: 'Tenant',
    description: 'Looking for a rental that matches your lifestyle.',
    imagePath: 'assets/images/tenant.png',
  ),
  landlord(
    label: 'Owner',
    description: 'Looking for compatible tenants for your property.',
    imagePath: 'assets/images/owner.png',
  ),
  guest(
    label: 'Guest',
    description: 'Browse listings without creating an account.',
    imagePath: 'assets/images/guest.png',
  );

  const UserRole({
    required this.label,
    required this.description,
    required this.imagePath,
  });

  /// Human-readable role name.
  final String label;

  /// Short explanation shown under the role name.
  final String description;

  /// Asset path for the role illustration shown in the option card.
  final String imagePath;
}
