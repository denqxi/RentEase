import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Welcome back, [name]" greeting with a landlord avatar on the right.
class LandlordHeader extends StatelessWidget {
  const LandlordHeader({this.name = 'test', super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome back,',
                style: AppTextStyles.caption.copyWith(fontSize: 14),
              ),
              Text(
                name,
                style: AppTextStyles.title.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        const _LandlordAvatar(),
      ],
    );
  }
}

class _LandlordAvatar extends StatelessWidget {
  const _LandlordAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF2C3E6B), Color(0xFF0D1B3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person, color: AppColors.onInk, size: 24),
    );
  }
}
