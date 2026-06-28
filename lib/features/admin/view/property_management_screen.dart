import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vacancy_status_pill.dart';

class PropertyManagementScreen extends StatefulWidget {
  const PropertyManagementScreen({super.key});

  static const routeName = '/admin/properties';

  @override
  State<PropertyManagementScreen> createState() => _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends State<PropertyManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return MockData.properties;
    return MockData.properties.where((p) {
      return (p['name'] as String).toLowerCase().contains(_query.toLowerCase()) ||
          (p['address'] as String).toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.appColors.surface,
        appBar: AppBar(
          backgroundColor: context.appColors.surface,
          elevation: 0,
          title: Text(
            'Property management',
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
                      hintText: 'Search properties...',
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
                    Tab(text: 'Active'),
                    Tab(text: 'Flagged'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _PropertyList(properties: _filtered, showFlaggedOnly: false),
            _PropertyList(
              properties: _filtered.where((p) => p['vacancyStatus'] == 'available').toList(),
              showFlaggedOnly: false,
            ),
            _PropertyList(
              properties: _filtered.where((p) => p['isFlagged'] == true).toList(),
              showFlaggedOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyList extends StatelessWidget {
  const _PropertyList({required this.properties, required this.showFlaggedOnly});

  final List<Map<String, dynamic>> properties;
  final bool showFlaggedOnly;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Center(child: Text('No properties found.', style: AppTextStyles.body(context)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: properties.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _PropertyCard(property: properties[i]),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final isFlagged = property['isFlagged'] == true;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFlagged ? AppColors.destructive : context.appColors.fieldBorder,
          width: isFlagged ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
            ),
            child: Center(child: Icon(Icons.home_work_rounded, color: AppColors.accent, size: 22)),
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
                        property['name'] as String,
                        style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
                      ),
                    ),
                    if (isFlagged)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadii.chip),
                        ),
                        child: Text('Flagged', style: TextStyle(fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.destructive)),
                      )
                    else
                      VacancyStatusPill.fromString(property['vacancyStatus'] as String),
                  ],
                ),
                SizedBox(height: 2),
                Text(property['address'] as String, style: AppTextStyles.caption(context)),
                Text('₱${property['rent']}/mo', style: AppTextStyles.caption(context)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: context.appColors.textSecondary, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
