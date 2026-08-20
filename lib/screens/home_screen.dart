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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWebView = false;
  bool _isLoading = false;

  WebViewController? _webViewController;

  Timer? _openWebViewTimer;

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
  // OPEN WEBVIEW
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
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _logout(BuildContext context) {
    // Show confirmation dialog
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
                Navigator.of(context).pop(); // Close dialog
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.logoutSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
                
                // Close drawer
                Navigator.of(context).pop();
                
                // Navigate to login
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
  // OPEN TERMS & CONDITIONS
  // ============================================================

  void _openTermsAndConditions() {
    _launchURL('https://zeecv.com/terms-and-conditions');
  }

  // ============================================================
  // OPEN PRIVACY POLICY
  // ============================================================

  void _openPrivacyPolicy() {
    _launchURL('https://zeecv.com/privacy-policy');
  }

  // ============================================================
  // LAUNCH URL
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
          title: const Text('ZEECV'),
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
    // NORMAL HOME SCREEN
    // ==========================================================

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
      // ==========================================================
      // DRAWER
      // ==========================================================
      drawer: Drawer(
        child: Column(
          children: [
            // ------------------------------------------------
            // DRAWER HEADER
            // ------------------------------------------------
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _getInitial(user),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // ------------------------------------------------
            // DRAWER ITEMS
            // ------------------------------------------------
            
            // Profile Item
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                // You can navigate to profile or show user info
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile section coming soon!'),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // Edit Resume
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text('Edit Resume'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                if (user != null) {
                  _openWebView(user);
                }
              },
            ),
            
            const Divider(),
            
            // Terms & Conditions
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms & Conditions'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                _openTermsAndConditions();
              },
            ),
            
            // Privacy Policy
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                _openPrivacyPolicy();
              },
            ),
            
            const Spacer(),
            
            const Divider(),
            
            // Logout
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () => _logout(context),
            ),
            
            const SizedBox(height: 16),
            
            // Version info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ------------------------------------------------
              // USER AVATAR
              // ------------------------------------------------

              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryBackground,
                child: Text(
                  _getInitial(user),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // NAME
              // ------------------------------------------------

              Text(
                'Welcome, ${user?.name ?? 'User'}!',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // EMAIL
              // ------------------------------------------------

              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // USER ID
              // ------------------------------------------------

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: ${user?.id ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // EDIT RESUME BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: user == null ? null : () => _openWebView(user),
                  icon: const Icon(Icons.edit_document),
                  label: const Text(
                    'Edit Resume',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // OPEN ZEECV (Optional additional button)
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: user == null ? null : () => _openWebView(user),
                  icon: const Icon(Icons.language),
                  label: const Text('Open ZEECV'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email!.substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}