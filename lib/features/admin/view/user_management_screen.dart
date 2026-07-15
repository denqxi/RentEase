import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/admin_page_header.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

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
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSuspend(Map<String, dynamic> user) {
    setState(() {
      final i = _users.indexOf(user);
      if (i == -1) return;
      _users[i] = {
        ..._users[i],
        'status': user['status'] == 'suspended' ? 'active' : 'suspended',
      };
    });
  }

  List<Map<String, dynamic>> _filtered(String role) {
    return _users.where((u) {
      final matchesRole = role == 'All' ||
          u['role'] == role ||
          (role == 'Suspended' && u['status'] == 'suspended');
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
        body: Column(
          children: [
            AdminPageHeader(
              title: 'Users',
              subtitle: '${_users.length} registered accounts',
              bottom: AdminSearchField(
                controller: _searchController,
                hintText: 'Search by name or email...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: context.appColors.textSecondary,
              labelStyle: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Tenants'),
                Tab(text: 'Owners'),
                Tab(text: 'Suspended'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: ['All', 'Tenant', 'Owner', 'Suspended'].map((role) {
                  final list = _filtered(role);
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'No users found.',
                        style: AppTextStyles.body(context),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      120,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _UserCard(
                      user: list[i],
                      onToggleSuspend: () => _toggleSuspend(list[i]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onToggleSuspend});

  final Map<String, dynamic> user;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    final isSuspended = user['status'] == 'suspended';
    final isOwner = user['role'] == 'Owner';
    final roleColor = isOwner ? AppColors.matchMedium : AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.fieldBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user['name'] as String).substring(0, 1),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['name'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        user['role'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(user['email'] as String, style: AppTextStyles.caption(context)),
                SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isSuspended
                            ? AppColors.destructive
                            : AppColors.matchHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      isSuspended ? 'Suspended' : 'Active',
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSuspended
                            ? AppColors.destructive
                            : AppColors.matchHigh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.appColors.textSecondary,
              size: 18,
            ),
            color: context.appColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) {
              if (v == 'toggle') onToggleSuspend();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  isSuspended ? 'Reactivate account' : 'Suspend account',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: isSuspended
                        ? AppColors.matchHigh
                        : AppColors.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
