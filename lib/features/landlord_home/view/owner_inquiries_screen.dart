import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/phase_badge.dart';

class OwnerInquiriesScreen extends StatefulWidget {
  const OwnerInquiriesScreen({super.key});

  @override
  State<OwnerInquiriesScreen> createState() => _OwnerInquiriesScreenState();
}

class _OwnerInquiriesScreenState extends State<OwnerInquiriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = (MockData.ownerInquiries as List)
      ..sort((a, b) => (b['ciScore'] as double).compareTo(a['ciScore'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiries'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.ownerPrimary,
          indicatorColor: AppColors.ownerPrimary,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Sent invitations'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Text(
              'Sorted by compatibility score',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Incoming
                ListView.builder(
                  itemCount: inquiries.length,
                  itemBuilder: (context, index) {
                    final inq = inquiries[index] as Map;
                    final phase = inq['phase'] as int;
                    final score = inq['ciScore'] as double;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.ownerFill,
                                  child: Text(
                                    inq['tenantInitials'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.ownerText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inq['tenantName'] ?? '',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.ownerFill,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Ci ${score.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors.ownerText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        inq['propertyName'] ?? '',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PhaseBadge(phase: phase),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (phase == 1)
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: 'Accept',
                                      color: AppColors.ownerPrimary,
                                      isSmall: true,
                                      onPressed: () {},
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppButton(
                                      label: 'Decline',
                                      isDanger: true,
                                      isSmall: true,
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            if (phase == 2)
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.ownerPrimary,
                                ),
                                child: const Text('Open chat'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Tab 2: Sent invitations
                Center(
                  child: Text(
                    'No sent invitations yet.',
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
