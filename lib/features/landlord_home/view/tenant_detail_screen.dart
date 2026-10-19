import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/models.dart';
import '../../inquiry/widgets/invite_button.dart';
import '../../owner/model/compatible_tenant.dart';
import '../../owner_onboarding/widgets/listing_form_widgets.dart';

/// Detail view for a compatible tenant (owner perspective).
/// Displays personal information, contact details, and living preferences.
///
/// Follows the profile card and gradient styling from the profile screen.
class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({
    required this.tenant,
    this.user,
    this.profile,
    this.phone,
    this.showInviteButton = false,
    super.key,
  });

  final CompatibleTenant tenant;
  final UserDoc? user;
  final TenantProfileDoc? profile;
  final String? phone;
  final bool showInviteButton;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  UserDoc? _user;
  TenantProfileDoc? _profile;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _profile = widget.profile;
    if (_profile == null || _user == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final futures = <Future<void>>[];
      if (_profile == null) {
        futures.add(
          firestore
              .collection('tenantProfiles')
              .doc(widget.tenant.tenantId)
              .get()
              .then((snap) {
            if (snap.exists && mounted) {
              setState(() {
                _profile = TenantProfileDoc.fromSnapshot(snap);
              });
            }
          }),
        );
      }
      if (_user == null) {
        futures.add(
          firestore
              .collection('users')
              .doc(widget.tenant.tenantId)
              .get()
              .then((snap) {
            if (snap.exists && mounted) {
              setState(() {
                _user = UserDoc.fromSnapshot(snap);
              });
            }
          }),
        );
      }
      await Future.wait(futures);
    } catch (_) {
      // Best-effort load; fallback to fields on CompatibleTenant
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Flexible';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final user = _user;
    final profile = _profile;

    final photoUrl = user?.profilePhoto;
    final phoneText = (widget.phone != null && widget.phone!.trim().isNotEmpty)
        ? widget.phone!.trim()
        : (user?.phone.isNotEmpty == true ? user!.phone : 'Shared in inquiry');
    final emailText = user?.email.isNotEmpty == true ? user!.email : '—';

    final genderText = tenant.gender.isNotEmpty
        ? tenant.gender
        : (user?.gender.isNotEmpty == true ? user!.gender : '—');
    final occupationText = profile?.occupation ?? tenant.occupation ?? '—';
    final schoolText = profile?.school ?? tenant.school ?? '—';
    final groupSizeText = '${profile?.groupSize ?? 1} person(s)';

    final budgetText = '₱${profile?.maxBudget ?? tenant.maxBudget}/month';
    final moveInText = _formatDate(profile?.moveInDate?.toDate());
    final roomTypeText = profile?.roomType?.isNotEmpty == true
        ? profile!.roomType!
        : 'Any room type';
    final smokingText = (profile?.isSmoker ?? false) ? 'Smoker' : 'Non-smoker';
    final petText = (profile?.hasPet ?? false) ? 'Has pet' : 'No pets';
    final wifiText = (profile?.needsWifi ?? false)
        ? 'Wi-Fi required'
        : 'Not required';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top Decorative Sky-Blue Gradient Backdrop ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.1,
                    colors: [
                      const Color(0xFFCCF2FE).withValues(alpha: 0.70),
                      const Color(0xFFE0F7FE).withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.45, 0.88],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Tenant Profile',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Card (Matching ProfileScreen design) ────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                // Avatar with gradient ring
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF7DD3FC), // Light blue
                                        Color(0xFF00A8F0), // Blue
                                        Color(0xFF10B981), // Emerald
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: const Color(0xFFE0F2FE),
                                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: (photoUrl == null || photoUrl.isEmpty)
                                          ? Text(
                                              tenant.initials,
                                              style: const TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF00A8F0),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.name,
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF10B981),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 13,
                                              color: Color(0xFF10B981),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Compatible Match',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Passes property rules and requirements',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Section 1: Contact Information ──────────────────
                        _sectionTitle(Icons.contact_phone_outlined, 'Contact details'),
                        const SizedBox(height: 8),
                        _cardWrapper([
                          _detailRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: phoneText,
                          ),
                          _divider(),
                          _detailRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            value: emailText,
                            isLast: true,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // ── Section 2: Personal Profile ─────────────────────
                        _sectionTitle(Icons.person_outline_rounded, 'Personal details'),
                        const SizedBox(height: 8),
                        _cardWrapper([
                          _detailRow(label: 'Gender', value: genderText),
                          _divider(),
                          _detailRow(label: 'Occupation', value: occupationText),
                          _divider(),
                          _detailRow(label: 'School / Workplace', value: schoolText),
                          _divider(),
                          _detailRow(label: 'Group size', value: groupSizeText, isLast: true),
                        ]),

                        const SizedBox(height: 20),

                        // ── Section 3: Living & Rental Preferences ───────────
                        _sectionTitle(Icons.tune_rounded, 'Rental & living preferences'),
                        const SizedBox(height: 8),
                        _cardWrapper([
                          _detailRow(label: 'Maximum budget', value: budgetText),
                          _divider(),
                          _detailRow(label: 'Target move-in', value: moveInText),
                          _divider(),
                          _detailRow(label: 'Room preference', value: roomTypeText),
                          _divider(),
                          _detailRow(label: 'Smoking policy', value: smokingText),
                          _divider(),
                          _detailRow(label: 'Pet policy', value: petText),
                          _divider(),
                          _detailRow(label: 'Internet', value: wifiText),
                          if (profile?.preferredAmenities?.isNotEmpty ?? false) ...[
                            _divider(),
                            _amenitiesRow(
                              label: 'Preferred amenities',
                              amenities: profile!.preferredAmenities!,
                            ),
                          ],
                        ]),

                        // ── Optional Invite Button (only if showInviteButton is true) ──
                        if (widget.showInviteButton) ...[
                          const SizedBox(height: 24),
                          InviteButton(
                            tenantId: tenant.tenantId,
                            tenantName: tenant.name,
                            bScore: tenant.bScore,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00A8F0)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _cardWrapper(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    IconData? icon,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenitiesRow({
    required String label,
    required List<String> amenities,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final amenity in amenities)
                _TenantAmenityChip(label: amenity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF1F5F9));
}

class _TenantAmenityChip extends StatelessWidget {
  const _TenantAmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final iconData = amenityIconFor(label);

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 0.75,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              iconData,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
