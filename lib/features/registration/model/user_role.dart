import 'package:flutter/material.dart';

/// The role a user signs up as.
enum UserRole {
  tenant(
    label: 'Tenant',
    description: 'Looking for a rental that matches your lifestyle.',
    icon: Icons.home_outlined,
  ),
  landlord(
    label: 'Landlord',
    description: 'Looking for compatible tenants for your property.',
    icon: Icons.vpn_key_outlined,
  );

  const UserRole({
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Human-readable role name.
  final String label;

  /// Short explanation shown under the role name.
  final String description;

  /// Leading icon for the role card.
  final IconData icon;
}
