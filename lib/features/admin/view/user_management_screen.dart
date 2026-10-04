import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/firestore/models/models.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/users_cubit.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_state_views.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();

  static const _tabs = ['all', 'tenant', 'owner', 'suspended'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleSuspend(UserDoc user) async {
    final cubit = context.read<UsersCubit>();
    final suspend = user.status != 'suspended';
    final ok = await confirmAdminAction(
      context,
      title: suspend ? 'Suspend account?' : 'Reactivate account?',
      body: suspend
          ? '${_displayName(user)} will be marked as suspended.'
          : '${_displayName(user)} will be marked as active again.',
      confirmLabel: suspend ? 'Suspend' : 'Reactivate',
      destructive: suspend,
    );
    if (ok) cubit.setSuspended(user.userId, suspended: suspend);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
      listener: (context, state) => showAdminNotice(context, state.notice),
      builder: (context, state) {
        return DefaultTabController(
          length: _tabs.length,
          child: Scaffold(
            backgroundColor: context.appColors.surface,
            body: Column(
              children: [
                AdminPageHeader(
                  title: 'Users',
                  subtitle: '${state.users.length} registered accounts',
                  bottom: AdminSearchField(
                    controller: _searchController,
                    hintText: 'Search by name or email...',
                    onChanged: context.read<UsersCubit>().setQuery,
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
                  child: state.isLoading
                      ? const AdminLoadingView()
                      : state.errorMessage != null && state.users.isEmpty
                      ? AdminMessageView(
                          icon: Icons.error_outline_rounded,
                          message: state.errorMessage!,
                          onRetry: context.read<UsersCubit>().start,
                        )
                      : TabBarView(
                          children: _tabs.map((tab) {
                            final list = state.filtered(tab);
                            if (list.isEmpty) {
                              return const AdminMessageView(
                                icon: Icons.people_outline_rounded,
                                message: 'No users found.',
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
                              separatorBuilder: (_, _) =>
                                  SizedBox(height: AppSpacing.sm),
                              itemBuilder: (_, i) => _UserCard(
                                user: list[i],
                                isBusy: state.busyIds.contains(list[i].userId),
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
      },
    );
  }
}

String _displayName(UserDoc u) {
  final n = '${u.firstName} ${u.lastName}'.trim();
  return n.isEmpty ? 'This user' : n;
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isBusy,
    required this.onToggleSuspend,
  });

  final UserDoc user;
  final bool isBusy;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.status == 'suspended';
    final isOwner = user.role == 'owner';
    final name = _displayName(user);
    final roleLabel = isOwner ? 'Owner' : 'Tenant';
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
                name.substring(0, 1).toUpperCase(),
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
                        name,
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
                        roleLabel,
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
                if (user.email.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text(user.email, style: AppTextStyles.caption(context)),
                ],
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
                      '${isSuspended ? 'Suspended' : 'Active'} · Joined ${formatAdminDate(user.createdAt?.toDate())}',
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
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            )
          else
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
