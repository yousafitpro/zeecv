import 'dart:async';
import 'dart:io';

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
import 'my_jobs_screen.dart';
import 'resumes_screen.dart';
import 'profile_screen.dart';

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // Bottom navigation index
  int _selectedIndex = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
  }

  // ============================================================
  // CREATE WEBVIEW CONTROLLER
  // ============================================================

  WebViewController _createWebViewController() {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WEBVIEW STARTED: $url');
          },
          onPageFinished: (String url) {
            debugPrint('WEBVIEW FINISHED: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WEBVIEW ERROR: '
              '${error.errorCode} - '
              '${error.description}',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Load Error: ${error.description}")),
              );
            }
            debugPrint('ERROR URL: ${error.url}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            debugPrint('NAVIGATION REQUEST: $url');

            if (_isPdfOrDownloadUrl(url)) {
              debugPrint('PDF/DOWNLOAD URL DETECTED');
              await _openExternalUrl(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    return controller;
  }

  // ============================================================
  // CHECK PDF / DOWNLOAD URL
  // ============================================================

  bool _isPdfOrDownloadUrl(String url) {
    final lowerUrl = url.toLowerCase();
    debugPrint('CHECKING URL: $lowerUrl');

    if (lowerUrl.endsWith('.pdf')) {
      return true;
    }
    if (lowerUrl.contains('.pdf?')) {
      return true;
    }
    if (lowerUrl.contains('/resume/download-pdf/')) {
      return true;
    }
    if (lowerUrl.contains('/download/')) {
      return true;
    }
    if (lowerUrl.contains('/download?')) {
      return true;
    }

    return false;
  }

  // ============================================================
  // OPEN EXTERNAL URL
  // ============================================================

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('OPENING EXTERNAL URL: $uri');

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint('LAUNCH RESULT: $launched');

      if (launched) {
        return;
      }

      debugPrint('External browser could not be opened.');
      if (!mounted) return;
      _showBrowserError();
    } catch (e, stackTrace) {
      debugPrint('OPEN EXTERNAL URL ERROR: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      _showBrowserError();
    }
  }

  // ============================================================
  // SHOW BROWSER ERROR
  // ============================================================

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
  // OPEN WEBVIEW FOR RESUME
  // ============================================================

  void _openWebView(UserModel user) {
    if (user.loginToken == null || user.loginToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login token is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';
    
    setState(() {
      _isLoading = true;
      _webViewTitle = 'ZEECV';
      _webViewUrl = url;
    });

    final controller = _createWebViewController();
    _webViewController = controller;

    controller.loadRequest(Uri.parse(url)).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showWebView = true;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // ============================================================
  // OPEN WEBVIEW FOR TERMS & CONDITIONS
  // ============================================================

  void _openTermsAndConditions() {
    _openWebViewForUrl(
      'https://zeecv.com/terms?app=yes',
      'Terms & Conditions',
    );
  }

  // ============================================================
  // OPEN WEBVIEW FOR PRIVACY POLICY
  // ============================================================

  void _openPrivacyPolicy() {
    _openWebViewForUrl(
      'https://zeecv.com/privacy-policy?app=yes',
      'Privacy Policy',
    );
  }

  // ============================================================
  // OPEN WEBVIEW FOR ANY URL
  // ============================================================

  void _openWebViewForUrl(String url, String title) {
    setState(() {
      _isLoading = true;
      _webViewTitle = title;
      _webViewUrl = url;
    });

    final controller = _createWebViewController();
    _webViewController = controller;

    controller.loadRequest(Uri.parse(url)).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showWebView = true;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // ============================================================
  // CLOSE WEBVIEW
  // ============================================================

  void _closeWebView() {
    setState(() {
      _showWebView = false;
      _webViewController = null;
      _isLoading = false;
      _webViewTitle = 'ZEECV';
      _webViewUrl = '';
    });
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
                
                Navigator.of(context).pop();
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

    // ==========================================================
    // WEBVIEW
    // ==========================================================

    if (_showWebView && _webViewController != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_webViewTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeWebView,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _webViewController?.reload();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : WebViewWidget(
                controller: _webViewController!,
              ),
      );
    }

    // ==========================================================
    // BOTTOM NAVIGATION HOME SCREEN
    // ==========================================================

    // Define the screens for each tab
    final List<Widget> _screens = [
      const FindJobScreen(),
      const MyJobsScreen(),
      const ResumesScreen(),
      ProfileScreen(
        user: user,
        onLogout: () => _logout(context),
        onEditResume: _openWebView,
        onTermsAndConditions: _openTermsAndConditions,
        onPrivacyPolicy: _openPrivacyPolicy,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
            label: 'Resumes',
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