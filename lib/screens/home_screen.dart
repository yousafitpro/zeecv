import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWebView = false;
  bool _isLoading = true;

  WebViewController? _webViewController;

  Timer? _openWebViewTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAndOpenWebView();
    });
  }

  Future<void> _prepareAndOpenWebView() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null ||
        user.loginToken == null ||
        user.loginToken!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url =
        'https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';

    // Initialize WebView immediately.
    // This allows the website to start loading during the 2 second delay.
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView error: ${error.description}',
            );
          },
        ),
      );

    _webViewController = controller;

    // Start loading the website immediately.
    await controller.loadRequest(Uri.parse(url));

    // Wait 2 seconds before showing the WebView.
    _openWebViewTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _showWebView = true;
      });
    });
  }

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

    final url =
        'https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              'WebView error: ${error.description}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() {
      _webViewController = controller;
      _showWebView = true;
    });
  }

  void _closeWebView() {
    setState(() {
      _showWebView = false;
      _webViewController = null;
    });
  }

  @override
  void dispose() {
    _openWebViewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // ==========================================
    // LOADING SCREEN
    // ==========================================
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo / Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Welcome to ZeeCV',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Preparing your ZeeCV account...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                const SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Please wait...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================
    // WEBVIEW SCREEN
    // ==========================================
    if (_showWebView && _webViewController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ZEECV'),
          leading: IconButton(
            icon: const Icon(Icons.close),
              onPressed: () {
              exit(0);
            },
            // onPressed: _closeWebView,
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
        body: WebViewWidget(
          controller: _webViewController!,
        ),
      );
    }

    // ==========================================
    // NORMAL HOME SCREEN
    // ==========================================
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.logoutSuccess),
                  backgroundColor: AppColors.success,
                ),
              );

              context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: user == null
                      ? null
                      : () => _openWebView(user),
                  icon: const Icon(Icons.language),
                  label: const Text('Open ZEECV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
