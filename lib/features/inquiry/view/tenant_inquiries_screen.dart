import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/phase_badge.dart';
import '../../resolution/view/rating_screen.dart';
import 'phase1_tenant_screen.dart';
import 'phase2_tenant_screen.dart';

class TenantInquiriesScreen extends StatefulWidget {
  const TenantInquiriesScreen({super.key});

  @override
  State<TenantInquiriesScreen> createState() => _TenantInquiriesScreenState();
}

class _TenantInquiriesScreenState extends State<TenantInquiriesScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Resolved

  @override
  Widget build(BuildContext context) {
    final int activeCount = MockData.inquiries.length;
    final property = MockData.properties[0];

    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Inquiries',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  // Active count badge
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Segmented control â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _SegmentedControl(
                selected: _selectedTab,
                onChanged: (i) => setState(() => _selectedTab = i),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // â”€â”€ Tab content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: _selectedTab == 0
                  ? _ActiveTab(property: property)
                  : const _ResolvedTab(),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Segmented control â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: <Widget>[
          _SegTab(
            label: 'Active',
            isSelected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _SegTab(
            label: 'Resolved',
            isSelected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? context.appColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Active tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: MockData.inquiries.length + 1,
      itemBuilder: (ctx, i) {
        if (i == MockData.inquiries.length) {
          return SizedBox(height: AppSpacing.lg);
        }
        final inquiry = MockData.inquiries[i];
        final int phase = inquiry['phase'] as int;
        final bool isPhase1 = phase == 1;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => isPhase1
                    ? Phase1TenantScreen(property: property)
                    : Phase2TenantScreen(property: property),
              ),
            );
          },
          child: _InquiryCard(
            propertyInitials: inquiry['propertyInitials'] as String,
            propertyName: inquiry['propertyName'] as String,
            ownerName: inquiry['ownerName'] as String,
            phase: phase,
            date: inquiry['date'] as String,
            isResolved: false,
          ),
        );
      },
    );
  }
}

// â”€â”€ Resolved tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ResolvedTab extends StatelessWidget {
  const _ResolvedTab();

  static const List<Map<String, String>> _resolved = <Map<String, String>>[
    {
      'initials': 'SB',
      'name': 'Sunshine Boarding House',
      'owner': 'Maria Reyes',
    },
    {
      'initials': 'BD',
      'name': 'BlueSky Dormitory',
      'owner': 'Ana Santos',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _resolved.length + 1,
      itemBuilder: (_, i) {
        if (i == _resolved.length) return SizedBox(height: AppSpacing.lg);
        final item = _resolved[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const RatingScreen()),
          ),
          child: _InquiryCard(
            propertyInitials: item['initials']!,
            propertyName: item['name']!,
            ownerName: item['owner']!,
            phase: 0,
            date: '',
            isResolved: true,
          ),
        );
      },
    );
  }
}

// â”€â”€ Shared inquiry card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.propertyInitials,
    required this.propertyName,
    required this.ownerName,
    required this.phase,
    required this.date,
    required this.isResolved,
  });

  final String propertyInitials;
  final String propertyName;
  final String ownerName;
  final int phase;
  final String date;
  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = phase == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isResolved ? context.appColors.fieldFill : AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              propertyInitials,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isResolved
                    ? context.appColors.textSecondary
                    : AppColors.accent,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  propertyName,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  ownerName,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                if (isResolved)
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.hint,
                    ),
                  )
                else
                  Text(
                    isPhase1 ? 'Awaiting response' : 'Chat open',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPhase1
                          ? AppColors.matchMedium
                          : AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
          // Trailing
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (isResolved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Booked',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.hint,
                    ),
                  ),
                )
              else
                PhaseBadge(phase: phase),
              if (date.isNotEmpty) ...<Widget>[
                SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: context.appColors.hint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
