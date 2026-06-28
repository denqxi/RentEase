import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';

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
      ),
    );
  }
}

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
        ],
      ),
    );
  }
}
