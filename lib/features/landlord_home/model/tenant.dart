import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A potential tenant shown in the landlord's home and matches screens.
class Tenant extends Equatable {
  const Tenant({
    required this.id,
    required this.name,
    required this.occupation,
    required this.incomeRange,
    required this.tags,
    required this.matchPercent,
    required this.imageSeed,
    this.isSaved = false,
    this.isVerified = true,
  });

  final String id;
  final String name;
  final String occupation;

  /// Formatted income bracket, e.g. "\$1.5k–2k".
  final String incomeRange;

  /// Lifestyle/preference tags shown as chips.
  final List<String> tags;

  final int matchPercent;

  /// 1–5 — selects the gradient palette for the avatar placeholder.
  final int imageSeed;

  final bool isSaved;
  final bool isVerified;

  Color get matchDotColor =>
      matchPercent >= 80 ? AppColors.matchHigh : AppColors.matchMedium;

  Tenant copyWith({bool? isSaved}) => Tenant(
        id: id,
        name: name,
        occupation: occupation,
        incomeRange: incomeRange,
        tags: tags,
        matchPercent: matchPercent,
        imageSeed: imageSeed,
        isSaved: isSaved ?? this.isSaved,
        isVerified: isVerified,
      );

  static const List<Tenant> samples = <Tenant>[
    Tenant(
      id: '1',
      name: 'Jane Doe',
      occupation: 'Product Designer',
      incomeRange: '\$1.5k–2k',
      tags: <String>['Non-smoker', 'No pets', '2 occupants'],
      matchPercent: 94,
      imageSeed: 1,
    ),
    Tenant(
      id: '2',
      name: 'David Kim',
      occupation: 'Software Engineer',
      incomeRange: '\$1.8k–2.4k',
      tags: <String>['Non-smoker', '1 occupant', 'Parking'],
      matchPercent: 90,
      imageSeed: 2,
    ),
    Tenant(
      id: '3',
      name: 'Aisha Mbeki',
      occupation: 'Graduate Student',
      incomeRange: '\$800–1.1k',
      tags: <String>['Student', 'Non-smoker', 'No pets'],
      matchPercent: 86,
      imageSeed: 3,
      isVerified: false,
    ),
    Tenant(
      id: '4',
      name: 'Carlos Rivera',
      occupation: 'Nurse',
      incomeRange: '\$1.4k–1.9k',
      tags: <String>['Non-smoker', '2 occupants', 'Pet owner'],
      matchPercent: 83,
      imageSeed: 4,
    ),
    Tenant(
      id: '5',
      name: 'Lena Fischer',
      occupation: 'Marketing Lead',
      incomeRange: '\$2k–2.6k',
      tags: <String>['Non-smoker', '1 occupant'],
      matchPercent: 80,
      imageSeed: 5,
    ),
  ];

  @override
  List<Object?> get props =>
      <Object?>[id, name, occupation, incomeRange, tags, matchPercent, imageSeed, isSaved, isVerified];
}
