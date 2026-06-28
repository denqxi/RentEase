import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import '../../../core/constants/app_colors.dart';
=======

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
>>>>>>> Stashed changes

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

<<<<<<< Updated upstream
=======
  static const routeName = '/admin/users';

>>>>>>> Stashed changes
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

<<<<<<< Updated upstream
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
=======
class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _users = [
    {'name': 'Maria Santos', 'email': 'maria@email.com', 'role': 'Tenant', 'status': 'active'},
    {'name': 'Jana Reyes', 'email': 'jana@email.com', 'role': 'Tenant', 'status': 'active'},
    {'name': 'Anna Cruz', 'email': 'anna@email.com', 'role': 'Tenant', 'status': 'active'},
    {'name': 'Carlos Mendoza', 'email': 'carlos@email.com', 'role': 'Owner', 'status': 'active'},
    {'name': 'Rosa Villanueva', 'email': 'rosa@email.com', 'role': 'Owner', 'status': 'active'},
    {'name': 'Benito Cruz', 'email': 'benito@email.com', 'role': 'Owner', 'status': 'suspended'},
  ];

  @override
  void dispose() {
>>>>>>> Stashed changes
    _searchController.dispose();
    super.dispose();
  }

<<<<<<< Updated upstream
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
=======
  List<Map<String, dynamic>> _filtered(String role) {
    return _users.where((u) {
      final matchesRole = role == 'All' || u['role'] == role || (role == 'Suspended' && u['status'] == 'suspended');
      final matchesQuery = _query.isEmpty ||
          (u['name'] as String).toLowerCase().contains(_query.toLowerCase()) ||
          (u['email'] as String).toLowerCase().contains(_query.toLowerCase());
      return matchesRole && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        appBar: AppBar(
          backgroundColor: context.appColors.surface,
          elevation: 0,
          title: Text(
            'User management',
            style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: AppTextStyles.field(context),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: AppTextStyles.field(context).copyWith(color: context.appColors.hint),
                      prefixIcon: Icon(Icons.search_rounded, color: context.appColors.hint, size: 18),
                      filled: true,
                      fillColor: context.appColors.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        borderSide: BorderSide(color: context.appColors.fieldBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.field),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: context.appColors.textSecondary,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Tenants'),
                    Tab(text: 'Owners'),
                    Tab(text: 'Suspended'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: ['All', 'Tenant', 'Owner', 'Suspended'].map((role) {
            final list = _filtered(role);
            if (list.isEmpty) {
              return Center(child: Text('No users found.', style: AppTextStyles.body(context)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: list.length,
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _UserCard(user: list[i]),
            );
          }).toList(),
        ),
>>>>>>> Stashed changes
      ),
    );
  }
}

<<<<<<< Updated upstream
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
=======
class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final isSuspended = user['status'] == 'suspended';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              (user['name'] as String).substring(0, 1),
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: context.appColors.ink),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] as String, style: TextStyle(fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                Text(user['email'] as String, style: AppTextStyles.caption(context)),
                Text(user['role'] as String, style: AppTextStyles.caption(context).copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          if (isSuspended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Text('Suspended', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.destructive)),
            )
          else
            AppButton(
              label: 'Suspend',
              variant: AppButtonVariant.outline,
              isSmall: true,
              isFullWidth: false,
              onPressed: () {},
            ),
>>>>>>> Stashed changes
        ],
      ),
    );
  }
}
