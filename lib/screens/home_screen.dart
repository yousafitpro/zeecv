// lib/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zeecv/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'find_job_screen.dart';

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  final Widget? tabNavigator;
  const HomeScreen({super.key, this.tabNavigator});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWebView = false;
  bool _isLoading = false;
  String _webViewTitle = 'ZEECV';
  String _webViewUrl = '';

  WebViewController? _webViewController;

  Timer? _openWebViewTimer;

  // ============================================================
  // GET SELECTED INDEX BASED ON CURRENT ROUTE
  // ============================================================

  int get _selectedIndex {
    try {
      final routerState = GoRouterState.of(context);
      final location = routerState.matchedLocation;
      
      if (location.contains('/home/find-jobs')) return 0;
      if (location.contains('/home/my-jobs')) return 1;
      if (location.contains('/home/resume')) return 2;
      if (location.contains('/home/profile')) return 3;
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
    return 0;
  }

  // ============================================================
  // CHECK IF ON JOB DETAIL
  // ============================================================

  bool get _isOnJobDetail {
    try {
      final routerState = GoRouterState.of(context);
      final location = routerState.matchedLocation;
      return location.contains('/job-detail');
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // GET TITLE BASED ON SELECTED INDEX
  // ============================================================

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Find Jobs';
      case 1:
        return 'My Jobs';
      case 2:
        return 'Resume';
      case 3:
        return 'Profile';
      default:
        return AppStrings.appName;
    }
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
  }


  void _showBrowserError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open the PDF. Please make sure a browser is installed.',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

 
  // ============================================================
  // OPEN WEBVIEW FOR TERMS & CONDITIONS
  // ============================================================

  void _openTermsAndConditions() {
    // _openWebViewForUrl(
    //   'https://zeecv.com/terms?is_app=yes',
    //   'Terms & Conditions',
    // );
  }

  // ============================================================
  // OPEN WEBVIEW FOR PRIVACY POLICY
  // ============================================================

  void _openPrivacyPolicy() {
    // _openWebViewForUrl(
    //   'https://zeecv.com/privacy-policy?is_app=yes',
    //   'Privacy Policy',
    // );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.logoutSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
                
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                
                context.go('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LAUNCH URL (For PDFs and external links)
  // ============================================================

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _openWebViewTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;


    // Check if on job detail
    final isJobDetail = _isOnJobDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(isJobDetail ? 'Job Detail' : _getTitle(_selectedIndex)),
        elevation: 0,
        leading: isJobDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.go('/home/find-jobs');
                },
              )
            : null,
      ),
      body: widget.tabNavigator ?? const FindJobScreen(),
      bottomNavigationBar: isJobDetail
          ? null // Hide bottom nav on job detail
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home/find-jobs');
                    break;
                  case 1:
                    context.go('/home/my-jobs');
                    break;
                  case 2:
                    context.go('/in-app/edit-resume');
                    break;
                  case 3:
                    context.go('/home/profile');
                    break;
                }
              },
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Find Job',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'My Jobs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Edit Resume',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}