import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                hintText: 'Search users...',
                filled: true,
                fillColor: AppColors.fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primaryMid),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryMid,
            indicatorColor: AppColors.primaryMid,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Tenants'),
              Tab(text: 'Owners'),
              Tab(text: 'Suspended'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All
                ListView(
                  children: const [
                    _UserTile(
                      name: 'Maria Santos',
                      role: 'Tenant',
                      joinDate: 'Joined May 2025',
                      isActive: true,
                    ),
                    _UserTile(
                      name: 'Maria Reyes',
                      role: 'Owner',
                      joinDate: 'Joined Jan 2025',
                      isActive: true,
                    ),
                    _UserTile(
                      name: 'Ana Santos',
                      role: 'Owner',
                      joinDate: 'Joined Mar 2025',
                      isActive: true,
                    ),
                    _UserTile(
                      name: 'Jana Ramos',
                      role: 'Tenant',
                      joinDate: 'Joined Jun 2025',
                      isActive: false,
                    ),
                  ],
                ),
                // Tab 2: Tenants
                Center(
                  child: Text(
                    'No tenants to display.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
                // Tab 3: Owners
                Center(
                  child: Text(
                    'No owners to display.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
                // Tab 4: Suspended
                Center(
                  child: Text(
                    'No suspended users.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.name,
    required this.role,
    required this.joinDate,
    required this.isActive,
  });

  final String name;
  final String role;
  final String joinDate;
  final bool isActive;

  String get _initials => name.isNotEmpty ? name[0] : '?';

  @override
  Widget build(BuildContext context) {
    final isTenant = role == 'Tenant';
    final avatarBg = isTenant ? AppColors.tenantFillBlue : AppColors.ownerFill;
    final avatarText = isTenant ? AppColors.tenantTextDeep : AppColors.ownerText;
    final badgeBg = isTenant ? AppColors.tenantFillBlue : AppColors.ownerFill;
    final badgeText = isTenant ? AppColors.tenantTextDeep : AppColors.ownerText;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarBg,
        child: Text(
          _initials,
          style: TextStyle(color: avatarText, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: badgeText,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.greenPrimary : AppColors.redPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                joinDate,
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
