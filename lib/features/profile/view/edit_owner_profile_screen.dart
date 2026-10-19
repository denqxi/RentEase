import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../../core/cubit/app_theme_cubit.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../home/cubit/home_cubit.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../uploads/data/repositories/cloudinary_image_upload_repository.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../cubit/profile_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.isOwner = true});

  final bool isOwner;

  static const Color bgIceBlue = Colors.white;
  static const Color primaryCyan = Color(0xFF00A8F0);
  static const Color textDarkNavy = Color(0xFF14213D);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0C2340).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0C2340).withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static Future<void> open(BuildContext context, {bool isOwner = true}) {
    LandlordHomeCubit? landlordCubit;
    ProfileCubit? profileCubit;
    HomeCubit? homeCubit;
    try {
      landlordCubit = context.read<LandlordHomeCubit>();
    } catch (_) {}
    try {
      profileCubit = context.read<ProfileCubit>();
    } catch (_) {}
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {}

    Widget child = EditProfileScreen(isOwner: isOwner);
    if (landlordCubit != null) {
      child = BlocProvider<LandlordHomeCubit>.value(
        value: landlordCubit,
        child: child,
      );
    }
    if (profileCubit != null) {
      child = BlocProvider<ProfileCubit>.value(
        value: profileCubit,
        child: child,
      );
    }
    if (homeCubit != null) {
      child = BlocProvider<HomeCubit>.value(
        value: homeCubit,
        child: child,
      );
    }

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => child,
      ),
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

typedef EditOwnerProfileScreen = EditProfileScreen;

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _photoUrl;
  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _emailController.text = user.email ?? '';

    try {
      final firestore = FirebaseFirestore.instance;
      final (userSnap, contactSnap) = await (
        firestore.collection(FirestoreCollections.users).doc(user.uid).get(),
        firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .collection(FirestoreCollections.userPrivate)
            .doc(FirestoreCollections.userContact)
            .get(),
      ).wait;

      if (userSnap.exists) {
        final data = userSnap.data() ?? {};
        _firstNameController.text = data['firstName'] as String? ?? '';
        _middleNameController.text = data['middleName'] as String? ?? '';
        _lastNameController.text = data['lastName'] as String? ?? '';
        _photoUrl = data['profilePhoto'] as String?;
        _gender = data['gender'] as String? ?? 'Prefer not to say';
      }

      if (contactSnap.exists) {
        final contactData = contactSnap.data() ?? {};
        final phone = contactData['phone'] as String? ?? '';
        if (phone.isNotEmpty) {
          _phoneController.text = phone;
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final uploadRepo = CloudinaryImageUploadRepository();
    try {
      final path = await uploadRepo.pick(
        ImageKind.propertyPhoto,
        PickSource.gallery,
      );
      if (path == null) return;

      setState(() => _isSaving = true);
      final uploaded = await uploadRepo.upload(
        ImageKind.propertyPhoto,
        path,
      );
      if (mounted) {
        setState(() {
          _photoUrl = uploaded.url;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              CloudinaryConfig.isConfigured
                  ? 'Failed to upload photo. Please try again.'
                  : 'Photo uploaded in preview mode.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name.')),
      );
      return;
    }
    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your last name.')),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef =
          firestore.collection(FirestoreCollections.users).doc(user.uid);
      final contactDocRef = userDocRef
          .collection(FirestoreCollections.userPrivate)
          .doc(FirestoreCollections.userContact);

      final userUpdate = <String, dynamic>{
        'firstName': firstName,
        'middleName': _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        'lastName': lastName,
        if (_photoUrl != null) 'profilePhoto': _photoUrl,
        if (_gender != null) 'gender': _gender,
      };

      final contactUpdate = <String, dynamic>{
        'phone': phone,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await Future.wait([
        userDocRef.update(userUpdate),
        contactDocRef.set(contactUpdate, SetOptions(merge: true)),
      ]);

      if (mounted) {
        try {
          context.read<LandlordHomeCubit>().refresh();
        } catch (_) {}
        try {
          context.read<ProfileCubit>().refresh();
        } catch (_) {}
        try {
          context.read<HomeCubit>().refresh();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppThemeCubit>().state;
    final bgColor = isDark ? context.appColors.surface : EditOwnerProfileScreen.bgIceBlue;
    final cardColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : EditOwnerProfileScreen.textDarkNavy;
    const primaryCyan = EditOwnerProfileScreen.primaryCyan;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: EditOwnerProfileScreen.cardShadow,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Edit personal info',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Avatar + Change Photo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryCyan.withValues(alpha: 0.3),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFE0F2FE),
                              backgroundImage:
                                  _photoUrl != null && _photoUrl!.isNotEmpty
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 52,
                                      color: primaryCyan,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _isSaving ? null : _pickAndUploadPhoto,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 16,
                                    color: primaryCyan,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Change photo',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // First name *
                    _buildLabel('First name', isRequired: true, textColor: textColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _firstNameController,
                      hint: 'Enter your first name',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 16),

                    // Middle name (optional)
                    _buildLabel('Middle name (optional)', isRequired: false, textColor: textColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _middleNameController,
                      hint: 'Enter your middle name',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 16),

                    // Last name *
                    _buildLabel('Last name', isRequired: true, textColor: textColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _lastNameController,
                      hint: 'Enter your last name',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 16),

                    // Phone number *
                    _buildLabel('Phone number', isRequired: true, textColor: textColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+63 9XX XXX XXXX',
                      cardColor: cardColor,
                      textColor: textColor,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: primaryCyan,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.isOwner
                                ? 'Shared with a tenant only after you accept their inquiry.'
                                : 'Used for communication with landlords and property managers.',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              color: EditProfileScreen.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email address (read only)
                    _buildLabel('Email address', isRequired: false, textColor: textColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'email@rentease.ph',
                      readOnly: true,
                      cardColor: isDark ? const Color(0xFF2A2A36) : const Color(0xFFF1F5F9),
                      textColor: EditOwnerProfileScreen.textMuted,
                      suffixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: EditOwnerProfileScreen.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Managed via authentication provider.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: EditOwnerProfileScreen.textMutedLight,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save changes button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryCyan,
                          disabledBackgroundColor:
                              primaryCyan.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save changes',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired, required Color textColor}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        children: [
          TextSpan(text: text),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    required Color textColor,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: readOnly ? null : EditOwnerProfileScreen.cardShadow,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14.5,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            color: EditOwnerProfileScreen.textMutedLight,
          ),
          suffixIcon: suffixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
