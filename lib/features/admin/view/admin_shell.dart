import 'package:flutter/material.dart';

import '../../shell/widgets/floating_nav_bar.dart';
import 'analytics_screen.dart';
import 'pending_verifications_screen.dart';
import 'property_management_screen.dart';
import 'user_management_screen.dart';

/// Root scaffold for the admin panel — bottom nav across the four admin
/// screens. Without this, Analytics / Users / Properties were only ever
/// reachable by directly instantiating them; nothing in the UI linked to them.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const List<Widget> _screens = <Widget>[
    AnalyticsScreen(),
    PendingVerificationsScreen(),
    UserManagementScreen(),
    PropertyManagementScreen(),
  ];

  static const List<FloatingNavBarItem> _items = <FloatingNavBarItem>[
    FloatingNavBarItem(icon: Icons.bar_chart_rounded, label: 'Dashboard'),
    FloatingNavBarItem(icon: Icons.verified_user_outlined, label: 'Verify'),
    FloatingNavBarItem(icon: Icons.people_outline_rounded, label: 'Users'),
    FloatingNavBarItem(icon: Icons.home_work_outlined, label: 'Properties'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
