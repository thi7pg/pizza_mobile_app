import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'login_page.dart';
import 'models/customer_profile.dart';
import 'services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  CustomerProfile? _profile;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = ApiService.currentEmail;
    if (email == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await ApiService.getUserProfile(email);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Load profile error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditDialog() async {
    final profile = _profile;
    if (profile == null) return;

    final nameCtrl = TextEditingController(text: profile.fullName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final addressCtrl = TextEditingController(text: profile.address);

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String? validationMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EditField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            profile.email,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade400,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _EditField(
                    controller: addressCtrl,
                    label: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        validationMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) {
                    setDialogState(() {
                      validationMessage = 'Full name is required.';
                    });
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (submitted != true) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      return;
    }

    if (!ApiService.isLoggedIn) {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      addressCtrl.dispose();
      return;
    }

    final fullName = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final address = addressCtrl.text.trim();

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();

    final updated = CustomerProfile(
      userId: ApiService.currentEmail ?? '',
      fullName: fullName,
      email: profile.email,
      phone: phone,
      address: address,
      profileImageUrl: profile.profileImageUrl,
      profileImagePath: profile.profileImagePath,
      profileImageData: profile.profileImageData,
    );

    try {
      if (!mounted) return;
      setState(() => _isSavingProfile = true);

      await ApiService.updateUserProfileData(
        fullName: updated.fullName,
        phone: updated.phone,
        address: updated.address,
      );

      if (!mounted) return;
      setState(() => _profile = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved, but refresh timed out.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update the profile: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    final currentProfile = _profile;
    if (currentProfile == null || _isUploadingImage) return;
    if (currentProfile.profileImageUrl.isEmpty &&
        currentProfile.profileImageData.isEmpty) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove profile image?'),
        content: const Text('This will delete your current profile image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!mounted) return;
      setState(() => _isUploadingImage = true);

      final updatedProfile = CustomerProfile(
        userId: currentProfile.userId,
        fullName: currentProfile.fullName,
        email: currentProfile.email,
        phone: currentProfile.phone,
        address: currentProfile.address,
        profileImageUrl: '',
        profileImagePath: '',
        profileImageData: '',
      );

      await ApiService.updateUserProfileData(
        fullName: updatedProfile.fullName,
      );

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image removed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove profile image: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showProfileImageOptions() async {
    final currentProfile = _profile;
    if (currentProfile == null || _isUploadingImage) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Profile Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (currentProfile.profileImageUrl.isNotEmpty ||
                  currentProfile.profileImageData.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Current Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleInfoCardTap(String label) {
    if (_isSavingProfile || _isUploadingImage) {
      return;
    }
    if (label == 'Email') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email is managed by your sign-in account.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _openEditDialog();
  }

  ImageProvider<Object>? _profileImageProvider(CustomerProfile profile) {
    if (profile.profileImageUrl.isNotEmpty) {
      return NetworkImage(profile.profileImageUrl);
    }
    if (profile.profileImageData.isEmpty) {
      return null;
    }

    try {
      final rawBase64 = profile.profileImageData.contains(',')
          ? profile.profileImageData.split(',').last
          : profile.profileImageData;
      return MemoryImage(base64Decode(rawBase64));
    } catch (_) {
      return null;
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Logout?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await ApiService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final profile = _profile;
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 48,
                color: Color(0xFFE53935),
              ),
              const SizedBox(height: 12),
              const Text(
                'Profile data is not available right now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull to refresh or try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final avatarImage = _profileImageProvider(profile);
    final hasPhone = profile.phone.isNotEmpty;
    final hasAddress = profile.address.isNotEmpty;
    final hasPhoto = avatarImage != null;

    return RefreshIndicator(
      color: const Color(0xFFE53935),
      onRefresh: _loadProfile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 320,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(42),
                    ),
                  ),
                ),
                Positioned(
                  top: -36,
                  right: -24,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: -44,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor: const Color(0xFFFFF4EF),
                                      backgroundImage: avatarImage,
                                      child: avatarImage == null
                                          ? Text(
                                              profile.fullName.isEmpty
                                                  ? 'P'
                                                  : profile.fullName[0]
                                                        .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFE53935),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    profile.fullName.isEmpty
                                        ? 'Customer'
                                        : profile.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    profile.email,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFF6F0),
                                      foregroundColor: const Color(0xFFB71C1C),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _openEditDialog,
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 18,
                              top: 68,
                              child: GestureDetector(
                                onTap: _showProfileImageOptions,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: _isUploadingImage
                                      ? const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFE53935),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 18,
                                          color: Color(0xFFE53935),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeading(
                      title: 'My Information',
                      subtitle:
                          'The details your orders and deliveries depend on',
                      compact: true,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: profile.fullName.isEmpty ? '—' : profile.fullName,
                      onTap: () => _handleInfoCardTap('Full Name'),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email.isEmpty ? '—' : profile.email,
                      onTap: () => _handleInfoCardTap('Email'),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profile.phone.isEmpty ? 'Not set' : profile.phone,
                      empty: profile.phone.isEmpty,
                      onTap: () => _handleInfoCardTap('Phone'),
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.location_on_outlined,
                      label: 'Delivery Address',
                      value: profile.address.isEmpty
                          ? 'Not set'
                          : profile.address,
                      empty: profile.address.isEmpty,
                      onTap: () => _handleInfoCardTap('Delivery Address'),
                    ),
                    const SizedBox(height: 16),
                    _QuickActionsRow(
                      hasPhone: hasPhone,
                      hasAddress: hasAddress,
                      hasPhoto: hasPhoto,
                      onEditProfile: _openEditDialog,
                      onEditPhoto: _showProfileImageOptions,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ApiService.isAdmin) SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8B4C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  label: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPage()),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _logout,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final bool hasPhone;
  final bool hasAddress;
  final bool hasPhoto;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPhoto;

  const _QuickActionsRow({
    required this.hasPhone,
    required this.hasAddress,
    required this.hasPhoto,
    required this.onEditProfile,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionChip(
          icon: Icons.edit_outlined,
          label: hasPhone && hasAddress ? 'Update details' : 'Complete details',
          onTap: onEditProfile,
        ),
        _ActionChip(
          icon: hasPhoto
              ? Icons.photo_camera_back_outlined
              : Icons.add_a_photo_outlined,
          label: hasPhoto ? 'Change photo' : 'Add photo',
          onTap: onEditPhoto,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFFE53935)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202020),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info display card ─────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool empty;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.empty = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF2E7DE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFE53935), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: empty ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: onTap == null
                    ? Colors.grey.shade200
                    : Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 17 : 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF241818),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: compact ? 12 : 12.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ── Edit dialog text field ────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE53935), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
