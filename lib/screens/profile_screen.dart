import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zeecv/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onLogout;
  final Function(UserModel) onEditResume;
  final VoidCallback onTermsAndConditions;
  final VoidCallback onPrivacyPolicy;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onEditResume,
    required this.onTermsAndConditions,
    required this.onPrivacyPolicy,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDeleting = false;

  // ============================================================
  // SHOW DELETE ACCOUNT DIALOG
  // ============================================================

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete your account?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action is permanent and cannot be undone. All your data, including resumes and saved jobs, will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : () => _deleteAccount(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> _deleteAccount(BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();

      if (success && mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to login screen
        context.go('/login');
      } else if (mounted) {
        // Close the dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to delete account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header with Gradient Background
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    // Profile Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitial(widget.user),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Edit Resume
                _buildProfileMenuItem(
                  icon: Icons.edit_document,
                  title: 'Edit Resume',
                  subtitle: 'Update your CV and portfolio',
                  color: AppColors.primary,
                  onTap:()=>{
                        context.go(
                      '/in-app/edit-resume',
                      extra: {
                        'back_url': '/home/profile',
                      },
                    )
                  },
                ),
                
                const Divider(height: 1),
                
                // Terms & Conditions
                _buildProfileMenuItem(
                  icon: Icons.description,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms of service',
                  color: Colors.blue,
                  onTap: widget.onTermsAndConditions,
                ),
                
                const Divider(height: 1),
                
                // Privacy Policy
                _buildProfileMenuItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Learn how we protect your data',
                  color: Colors.purple,
                  onTap: widget.onPrivacyPolicy,
                ),
                
                const Divider(height: 1),
                
                // Delete Account
                _buildProfileMenuItem(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and data',
                  color: Colors.red,
                  onTap: () => _showDeleteAccountDialog(context),
                  isDanger: true,
                ),
                
                const Divider(height: 1),
                TextButton(
            onPressed: () => context.go('/debug-logs'), // or context.push('/debug-logs')
            child: const Text('View Debug Logs'),
          ),
                // Logout
                _buildProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out from your account',
                  color: Colors.red,
                  onTap: widget.onLogout,
                  isLogout: true,
                ),
                
              ],
            ),
            
          ),
          
          const SizedBox(height: 24),
          
          // App Version
          Text(
            'App Version 1.0.0',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          
                    
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE MENU ITEM
  // ============================================================

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool isLogout = false,
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: (isLogout || isDanger) ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        (isLogout || isDanger) ? Icons.arrow_forward_ios : Icons.chevron_right,
        color: (isLogout || isDanger) ? Colors.red : Colors.grey[400],
        size: 18,
      ),
      onTap: onTap,
      tileColor: (isLogout || isDanger) ? Colors.red.withValues(alpha: 0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ============================================================
  // USER INITIAL
  // ============================================================

  String _getInitial(UserModel? user) {
    if (user?.name != null && user!.name!.isNotEmpty) {
      return user.name!.substring(0, 1).toUpperCase();
    }
    if (user?.email != null && user!.email.isNotEmpty) {
      return user.email.substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}