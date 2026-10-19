import 'package:flutter/material.dart';

import '../../../core/firestore/models/models.dart';
import '../../../core/utils/date_utils.dart';

/// Detail view for a property owner / landlord (tenant perspective).
/// Displays host information, contact details, and listing overview.
class OwnerDetailScreen extends StatelessWidget {
  const OwnerDetailScreen({
    this.owner,
    this.ownerProfile,
    this.property,
    required this.fallbackName,
    this.phone,
    this.isVerified = false,
    super.key,
  });

  final UserDoc? owner;
  final OwnerProfileDoc? ownerProfile;
  final PropertyDoc? property;
  final String fallbackName;
  final String? phone;
  final bool isVerified;

  String get _displayName {
    final o = owner;
    if (o == null) return fallbackName;
    final name = '${o.firstName} ${o.lastName}'.trim();
    return name.isNotEmpty ? name : fallbackName;
  }

  String get _initials {
    final parts = _displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final inits = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return inits.isEmpty ? '?' : inits;
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = owner?.profilePhoto;
    final phoneText = (phone != null && phone!.trim().isNotEmpty)
        ? phone!.trim()
        : (owner?.phone.isNotEmpty == true ? owner!.phone : 'Shared in chat');
    final emailText = owner?.email.isNotEmpty == true ? owner!.email : '—';
    final p = property;

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
                // ── Top Header Bar ───────────────────────────────────────────
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
                        'Owner Profile',
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
                                              _initials,
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
                                        _displayName,
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
                                          color: isVerified
                                              ? const Color(0xFFEFF6FF)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isVerified
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFFCBD5E1),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isVerified
                                                  ? Icons.verified_rounded
                                                  : Icons.shield_outlined,
                                              size: 13,
                                              color: isVerified
                                                  ? const Color(0xFF0284C7)
                                                  : const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isVerified ? 'Verified Owner' : 'Property Host',
                                              style: TextStyle(
                                                fontFamily: 'DM Sans',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: isVerified
                                                    ? const Color(0xFF0369A1)
                                                    : const Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Verified boarding house host on RentEase',
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

                        // ── Section 2: Host Details ─────────────────────────
                        _sectionTitle(Icons.badge_outlined, 'Host details'),
                        const SizedBox(height: 8),
                        _cardWrapper([
                          _detailRow(
                            label: 'Verification',
                            value: isVerified ? 'Identity Verified' : 'Registered Host',
                          ),
                          _divider(),
                          _detailRow(
                            label: 'Role',
                            value: 'Property Landlord / Host',
                            isLast: true,
                          ),
                        ]),

                        if (p != null) ...[
                          const SizedBox(height: 20),
                          // ── Section 3: Property Inquired ──────────────────
                          _sectionTitle(Icons.home_work_outlined, 'Listing information'),
                          const SizedBox(height: 8),
                          _cardWrapper([
                            _detailRow(label: 'Property name', value: p.title),
                            _divider(),
                            _detailRow(label: 'Location', value: p.address),
                            _divider(),
                            _detailRow(label: 'Monthly rent', value: '₱${p.monthlyRent}/mo'),
                            _divider(),
                            _detailRow(label: 'Deposit', value: '₱${p.depositAmount}'),
                            _divider(),
                            _detailRow(
                              label: 'Advance',
                              value: p.advanceMonths > 0
                                  ? '₱${(p.monthlyRent * p.advanceMonths).toInt()}'
                                  : 'None',
                            ),
                            _divider(),
                            _detailRow(
                              label: 'Curfew',
                              value: formatCurfew(p.curfewHours),
                            ),
                            _divider(),
                            _detailRow(
                              label: 'Gender policy',
                              value: p.allowedGender.isNotEmpty ? p.allowedGender : 'Mixed / Any',
                              isLast: true,
                            ),
                          ]),
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
            width: 110,
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

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF1F5F9));
}
