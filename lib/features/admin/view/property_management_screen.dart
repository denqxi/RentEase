import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/listing_image_placeholder.dart';
import '../../../shared/widgets/vacancy_status_pill.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../widgets/admin_page_header.dart';

class PropertyManagementScreen extends StatefulWidget {
  const PropertyManagementScreen({super.key});

  static const routeName = '/admin/properties';

  @override
  State<PropertyManagementScreen> createState() =>
      _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFlag(Map<String, dynamic> property) {
    setState(() {
      final i = MockData.properties.indexOf(property);
      if (i == -1) return;
      MockData.properties[i] = {
        ...MockData.properties[i],
        'isFlagged': !(property['isFlagged'] == true),
      };
    });
  }

  void _removeListing(Map<String, dynamic> property) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove listing?',
          style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${property['title']}" will be removed from the platform. '
          'This cannot be undone.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => MockData.properties.remove(property));
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: AppColors.destructive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return MockData.properties;
    return MockData.properties.where((p) {
      return (p['title'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase()) ||
          (p['address'] as String)
              .toLowerCase()
              .contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        body: Column(
          children: [
            AdminPageHeader(
              title: 'Properties',
              subtitle: '${MockData.properties.length} listings on the platform',
              bottom: AdminSearchField(
                controller: _searchController,
                hintText: 'Search by name or address...',
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
                Tab(text: 'Active'),
                Tab(text: 'Flagged'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PropertyList(
                    properties: _filtered,
                    onToggleFlag: _toggleFlag,
                    onRemove: _removeListing,
                  ),
                  _PropertyList(
                    properties: _filtered
                        .where((p) => p['vacancyStatus'] == 'available')
                        .toList(),
                    onToggleFlag: _toggleFlag,
                    onRemove: _removeListing,
                  ),
                  _PropertyList(
                    properties: _filtered
                        .where((p) => p['isFlagged'] == true)
                        .toList(),
                    onToggleFlag: _toggleFlag,
                    onRemove: _removeListing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyList extends StatelessWidget {
  const _PropertyList({
    required this.properties,
    required this.onToggleFlag,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> properties;
  final ValueChanged<Map<String, dynamic>> onToggleFlag;
  final ValueChanged<Map<String, dynamic>> onRemove;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Center(
        child: Text('No properties found.', style: AppTextStyles.body(context)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      itemCount: properties.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _PropertyCard(
        property: properties[i],
        onToggleFlag: () => onToggleFlag(properties[i]),
        onRemove: () => onRemove(properties[i]),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.onToggleFlag,
    required this.onRemove,
  });

  final Map<String, dynamic> property;
  final VoidCallback onToggleFlag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isFlagged = property['isFlagged'] == true;
    final seed = (property['propertyId'] as String).hashCode % 5 + 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFlagged
              ? AppColors.destructive
              : context.appColors.fieldBorder,
          width: isFlagged ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.field),
            child: SizedBox(
              width: 60,
              height: 60,
              child: ListingImagePlaceholder(seed: seed),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property['title'] as String,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFlagged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.destructive.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                        ),
                        child: Text(
                          'Flagged',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.destructive,
                          ),
                        ),
                      )
                    else
                      VacancyStatusPill.fromString(
                        property['vacancyStatus'] as String,
                      ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  property['address'] as String,
                  style: AppTextStyles.caption(context),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₱${property['monthlyRent']}/mo',
                      style: AppTextStyles.caption(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${property['ownerName']}',
                        style: AppTextStyles.caption(context),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (property['isVerified'] == true) ...[
                      SizedBox(width: 4),
                      const VerifiedBadge(isVerified: true, isSmall: true),
                    ],
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
            onSelected: (value) {
              if (value == 'flag') onToggleFlag();
              if (value == 'remove') onRemove();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'flag',
                child: Text(
                  isFlagged ? 'Unflag listing' : 'Flag listing',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 13),
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  'Remove listing',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.destructive,
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