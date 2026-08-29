// lib/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zeecv/models/user_model.dart';
import 'package:zeecv/widgets/bottom_tabs.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'find_job_screen.dart';

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

 int get _selectedIndex {
  try {
    final routerState = GoRouterState.of(context);
    final location = routerState.matchedLocation;

    if (location.contains('/home/home')) return 0;
    if (location.contains('/home/find-jobs')) return 1;
    if (location.contains('/home/my-jobs')) return 3;
    if (location.contains('/home/profile')) return 4;
    if (location.contains('/in-app/edit-resume')) return 2;
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
        return 'Find Jobs';
      case 2:
        return '';
      case 3:
        return 'My Jobs';
      case 4:
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
  backgroundColor: const Color.fromARGB(255, 252, 251, 251), // Light gray
  foregroundColor: Colors.black87,
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
      bottomNavigationBar:BottomTabs(selectedIndex: _selectedIndex),
    );
  }
}