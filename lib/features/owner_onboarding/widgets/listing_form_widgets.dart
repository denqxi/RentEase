import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_toggle.dart';

/// Small building blocks shared by the create-listing wizard steps. They reuse
/// the existing field/pill styling so the wizard matches the rest of the app.

/// Standard property types with Boarding House on top and Others at the bottom.
const List<String> kStandardPropertyTypes = [
  'Boarding House',
  'Dormitory',
  'Apartment',
  'Condo',
  'Others',
];

/// Modern custom dropdown styled after the floating card reference design.
class ListingDropdown<T> extends StatefulWidget {
  const ListingDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;

  @override
  State<ListingDropdown<T>> createState() => _ListingDropdownState<T>();
}

class _ListingDropdownState<T> extends State<ListingDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _removeOverlay(immediate: true);
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (widget.onChanged == null || widget.items.isEmpty) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    FocusScope.of(context).unfocus();
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: AppColors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: size.width,
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: AppColors.onInk,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.slate900.withValues(alpha: 0.11),
                          blurRadius: 22,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.slate900.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (ctx, index) {
                        final item = widget.items[index];
                        final isSelected = item.value == widget.value;
                        return InkWell(
                          onTap: () {
                            final selectedVal = item.value;
                            _closeDropdown();
                            widget.onChanged?.call(selectedVal);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : AppColors.transparent,
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.slate900,
                              ),
                              child: item.child,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animController.forward(from: 0);
  }

  Future<void> _closeDropdown() async {
    if (!_isOpen) return;
    await _animController.reverse();
    _removeOverlay(immediate: true);
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _removeOverlay({bool immediate = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!immediate && mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DropdownMenuItem<T>? selectedItem;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedItem = item;
        break;
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _triggerKey,
        onTap: _toggleDropdown,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.onInk,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.accent
                  : AppColors.indicatorInactive,
              width: _isOpen ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: selectedItem != null
                    ? DefaultTextStyle(
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                        child: selectedItem.child,
                      )
                    : Text(
                        widget.hint,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 160),
                child: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern Property Type dropdown with preset choices ('Boarding House',
/// 'Dormitory', 'Apartment', 'Condo', 'Others'). When 'Others' is clicked,
/// the dropdown field switches into an inline text input with a guiding placeholder.
class PropertyTypeDropdown extends StatefulWidget {
  const PropertyTypeDropdown({
    required this.value,
    required this.onChanged,
    this.hint = 'Select property type',
    this.customPlaceholder = 'Type property type (e.g. Townhouse, Studio)...',
    this.options = kStandardPropertyTypes,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String hint;
  final String customPlaceholder;
  final List<String> options;

  @override
  State<PropertyTypeDropdown> createState() => _PropertyTypeDropdownState();
}

class _PropertyTypeDropdownState extends State<PropertyTypeDropdown>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _isCustomMode = false;

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOutCubic,
  );

  List<String> get _presetOnly =>
      widget.options.where((o) => o != 'Others').toList();

  @override
  void initState() {
    super.initState();
    _syncFromValue(widget.value);
    _customFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant PropertyTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isCustomMode) {
      _syncFromValue(widget.value);
    }
  }

  void _syncFromValue(String? val) {
    if (val != null && val.trim().isNotEmpty && !_presetOnly.contains(val)) {
      _isCustomMode = true;
      if (_customController.text != val) {
        _customController.text = val;
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay(immediate: true);
    _animController.dispose();
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    FocusScope.of(context).unfocus();
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: AppColors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: size.width,
                    decoration: BoxDecoration(
                      color: AppColors.onInk,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.slate900.withValues(alpha: 0.11),
                          blurRadius: 22,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.slate900.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final option in widget.options)
                            InkWell(
                              onTap: () => _handleSelectOption(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 11,
                                ),
                                color: (_isOptionSelected(option))
                                    ? AppColors.primary.withValues(alpha: 0.06)
                                    : AppColors.transparent,
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: _isOptionSelected(option)
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _isOptionSelected(option)
                                        ? AppColors.primary
                                        : AppColors.slate900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animController.forward(from: 0);
  }

  bool _isOptionSelected(String option) {
    if (option == 'Others') return _isCustomMode;
    return !_isCustomMode && widget.value == option;
  }

  Future<void> _handleSelectOption(String option) async {
    await _closeDropdown();
    if (!mounted) return;
    if (option == 'Others') {
      setState(() {
        _isCustomMode = true;
        _customController.clear();
      });
      widget.onChanged(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _customFocusNode.requestFocus();
      });
    } else {
      setState(() {
        _isCustomMode = false;
        _customController.clear();
      });
      widget.onChanged(option);
    }
  }

  Future<void> _closeDropdown() async {
    if (!_isOpen) return;
    await _animController.reverse();
    _removeOverlay(immediate: true);
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _removeOverlay({bool immediate = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!immediate && mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocusedOrOpen = _isOpen || _customFocusNode.hasFocus;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        key: _triggerKey,
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: _isCustomMode ? 2 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.onInk,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocusedOrOpen
                ? AppColors.accent
                : AppColors.indicatorInactive,
            width: isFocusedOrOpen ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _isCustomMode
                  ? TextField(
                      controller: _customController,
                      focusNode: _customFocusNode,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.customPlaceholder,
                        hintStyle: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.slate400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        final trimmed = val.trim();
                        widget.onChanged(trimmed.isEmpty ? null : trimmed);
                      },
                    )
                  : GestureDetector(
                      onTap: _toggleDropdown,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        (widget.value != null && widget.value!.isNotEmpty)
                            ? widget.value!
                            : widget.hint,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight:
                              (widget.value != null && widget.value!.isNotEmpty)
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                          color:
                              (widget.value != null && widget.value!.isNotEmpty)
                                  ? context.appColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleDropdown,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + switch row (same look as the property-rules toggles).
class ListingToggleRow extends StatelessWidget {
  const ListingToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    super.key,
  });

  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: context.appColors.textPrimary),
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                Text(helper!, style: AppTextStyles.caption(context)),
              ],
            ],
          ),
        ),
        AppToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Big selectable card used for the Step 1 rental-type choice.
class RentalTypeCard extends StatelessWidget {
  const RentalTypeCard({
    this.icon,
    this.svgString,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  }) : assert(icon != null || svgString != null, 'Either icon or svgString must be provided');

  final IconData? icon;
  final String? svgString;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? AppColors.onInk
        : context.appColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $description',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.onInk,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.slate200,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.scrim.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.slate200,
                  ),
                ),
                alignment: Alignment.center,
                child: svgString != null
                    ? AppSvgIcon(
                        svgString: svgString!,
                        size: 24,
                        color: iconColor,
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.caption(context)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Information callout box with a circular icon and descriptive text.
class ListingCalloutBox extends StatelessWidget {
  const ListingCalloutBox({
    required this.title,
    required this.subtitle,
    this.icon = Icons.lightbulb_rounded,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(
          color: context.appColors.fieldBorder.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.slate200.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.35,
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

/// Categorized amenity sections shared across Create Listing and Edit Listing screens.
const List<(String, List<String>)> kAmenityGroups = [
  (
    'Comfort & Internet',
    ['WiFi', 'Air conditioning', 'Electric fan', 'Furnished room'],
  ),
  (
    'Bathroom & Facilities',
    [
      'Private bathroom',
      'Laundry facility',
      'Kitchen or cooking area',
      'Refrigerator access',
    ],
  ),
  (
    'Safety & Convenience',
    [
      'CCTV or security camera',
      'Parking space',
      'Study area or desk',
      '24-hour access',
    ],
  ),
  (
    'Bills Included',
    ['Water included in rent', 'Electricity included in rent'],
  ),
];

/// Returns a clean outline icon for each standard amenity label.
IconData amenityIconFor(String label) {
  switch (label) {
    case 'WiFi':
      return Icons.wifi_rounded;
    case 'Air conditioning':
      return Icons.ac_unit_rounded;
    case 'Electric fan':
      return Icons.air_rounded;
    case 'Furnished room':
      return Icons.chair_outlined;
    case 'Private bathroom':
      return Icons.bathtub_outlined;
    case 'Laundry facility':
      return Icons.local_laundry_service_outlined;
    case 'Kitchen or cooking area':
      return Icons.countertops_outlined;
    case 'Refrigerator access':
      return Icons.kitchen_outlined;
    case 'CCTV or security camera':
      return Icons.videocam_outlined;
    case 'Parking space':
      return Icons.directions_car_outlined;
    case 'Study area or desk':
      return Icons.desk_outlined;
    case '24-hour access':
      return Icons.schedule_outlined;
    case 'Water included in rent':
      return Icons.water_drop_outlined;
    case 'Electricity included in rent':
      return Icons.bolt_outlined;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

/// Selectable amenity pill with a circular outline icon badge and theme-colored active state.
class AmenityChip extends StatelessWidget {
  const AmenityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCloseIcon = true,
    this.activeColor,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCloseIcon;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final iconData = amenityIconFor(label);
    final effectiveActiveColor = activeColor ?? AppColors.accent;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            5,
            5,
            selected && showCloseIcon ? 9 : 11,
            5,
          ),
          decoration: BoxDecoration(
            color: selected ? effectiveActiveColor : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? effectiveActiveColor
                  : AppColors.slate200.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.onInk.withValues(alpha: 0.22)
                      : AppColors.onInk,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  iconData,
                  size: 13,
                  color: selected ? AppColors.onInk : effectiveActiveColor,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.onInk : AppColors.slate900,
                    height: 1.1,
                  ),
                ),
              ),
              if (selected && showCloseIcon) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.close_rounded,
                  size: 13.5,
                  color: AppColors.onInk.withValues(alpha: 0.9),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Review card with a title and an Edit action.
class ReviewSectionCard extends StatelessWidget {
  const ReviewSectionCard({
    required this.title,
    required this.onEdit,
    required this.child,
    super.key,
  });

  final String title;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.fieldFill,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: context.appColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label(context).copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Edit $title',
                child: GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// `label  value` line used inside review cards.
class ReviewLine extends StatelessWidget {
  const ReviewLine(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: AppTextStyles.caption(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: context.appColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
