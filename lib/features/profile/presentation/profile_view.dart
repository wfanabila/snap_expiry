import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  static const Color backgroundColor = Color(0xFFF4F6EF);
  static const Color primaryColor = Color(0xFF4B7655);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String email = user?.email ?? 'No email available';
    final String name =
        user?.displayName ??
        (email.contains('@') ? email.split('@').first : 'SnapExpiry User');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ProfileAvatar(size: 48),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 35, 22, 30),
          child: Column(
            children: [
              // Profile information card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const _ProfileAvatar(size: 120),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Settings options
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      title: 'Edit Profile',
                      onTap: () => _showEditProfile(context, name),
                    ),
                    const _SettingsDivider(),

                    _SettingsTile(
                      title: 'Change Password',
                      onTap: () => _showChangePassword(context),
                    ),
                    const _SettingsDivider(),

                    // Biometric App Lock
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          activeColor: primaryColor,
                          title: const Text(
                            'Biometric App Lock',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: const Text(
                            'Use fingerprint or face recognition to '
                            'protect SnapExpiry.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          secondary: const Icon(
                            Icons.fingerprint,
                            color: primaryColor,
                            size: 30,
                          ),
                          value: state.isBiometricLockEnabled,
                          onChanged: state.isBiometricAuthenticating
                              ? null
                              : (enabled) async {
                                  final cubit =
                                      context.read<AuthCubit>();

                                  final success = enabled
                                      ? await cubit.enableBiometricLock()
                                      : await cubit.disableBiometricLock();

                                  if (!context.mounted) return;

                                  final message = success
                                      ? cubit.state.infoMessage ??
                                          'Security setting updated.'
                                      : cubit.state.errorMessage ??
                                          'Unable to update security setting.';

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(message),
                                      ),
                                    );
                                },
                        );
                      },
                    ),

                    const _SettingsDivider(),

                    _SettingsTile(
                      title: 'About ExpiryTracker',
                      onTap: () => _showAbout(context),
                    ),
                    const _SettingsDivider(),

                    _SettingsTile(
                      title: 'FAQ',
                      onTap: () => _showFaq(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Log out button
              SizedBox(
                width: double.infinity,
                height: 65,
                child: OutlinedButton(
                  onPressed: () => _confirmLogout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _BottomNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  onTap: () => context.go('/home'),
                ),
                _BottomNavItem(
                  icon: Icons.add_circle_outline,
                  label: 'Add',
                  onTap: () => context.push('/add-product'),
                ),
                _BottomNavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  selected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Edit profile dialog
  static void _showEditProfile(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Text(
          'Your current display name is $currentName. '
          'Profile editing can be connected to Firebase in the next step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Change password dialog
  static void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'Password changes will be handled through Firebase Authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // About dialog
  static void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SnapExpiry',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'A mobile application that helps users track product expiry dates.',
    );
  }

  // FAQ dialog
  static void _showFaq(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. What is SnapExpiry?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'SnapExpiry helps you manage and monitor product expiry dates.',
              ),
              SizedBox(height: 15),
              Text(
                '2. How do I add a product?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tap the Add button to enter product details or scan its barcode.',
              ),
              SizedBox(height: 15),
              Text(
                '3. How can I check expiry dates?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Open your Items page to view your saved products and expiry information.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Logout confirmation
  static void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await context.read<AuthCubit>().signOut();

              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile avatar
class _ProfileAvatar extends StatelessWidget {
  final double size;

  const _ProfileAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFECC5BF),
      backgroundImage:
          photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Icon(
              Icons.person,
              size: size * 0.65,
              color: const Color(0xFF4B7655),
            )
          : null,
    );
  }
}

// Reusable settings tile
class _SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 23,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 25,
      endIndent: 25,
      color: Color(0xFFD6D6D6),
    );
  }
}

// Reusable bottom navigation item
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: selected ? const Color(0xFF4B7655) : Colors.black87,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF4B7655) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}