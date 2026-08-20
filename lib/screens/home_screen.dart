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
  bool _isLoading = true;

  WebViewController? _webViewController;

  Timer? _openWebViewTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAndOpenWebView();
    });
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
          // ----------------------------------------------------
          // PAGE STARTED
          // ----------------------------------------------------

          onPageStarted: (String url) {
            debugPrint('WEBVIEW STARTED: $url');
          },

          // ----------------------------------------------------
          // PAGE FINISHED
          // ----------------------------------------------------

          onPageFinished: (String url) {
            debugPrint('WEBVIEW FINISHED: $url');
          },

          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

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

            debugPrint(
              'ERROR URL: ${error.url}',
            );
          },

          // ----------------------------------------------------
          // NAVIGATION
          // ----------------------------------------------------

          onNavigationRequest:
              (NavigationRequest request) async {
            final url = request.url;

            debugPrint(
              'NAVIGATION REQUEST: $url',
            );

            // --------------------------------------------------
            // PDF / DOWNLOAD
            // --------------------------------------------------

            if (_isPdfOrDownloadUrl(url)) {
              debugPrint(
                'PDF/DOWNLOAD URL DETECTED',
              );

              await _openExternalUrl(url);

              return NavigationDecision.prevent;
            }

            // --------------------------------------------------
            // NORMAL WEB PAGE
            // --------------------------------------------------

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

    debugPrint(
      'CHECKING URL: $lowerUrl',
    );

    // Direct PDF
    if (lowerUrl.endsWith('.pdf')) {
      return true;
    }

    // PDF with query parameters
    if (lowerUrl.contains('.pdf?')) {
      return true;
    }

    // Your actual ZeeCV URL:
    //
    // /resume/download-pdf/preview/3200912
    //
    // /resume/download-pdf/3200912
    //

    if (lowerUrl.contains('/resume/download-pdf/')) {
      return true;
    }

    // Generic download URL
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

      debugPrint(
        'OPENING EXTERNAL URL: $uri',
      );

      // --------------------------------------------------------
      // IMPORTANT
      //
      // First try external browser/application.
      // --------------------------------------------------------

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      debugPrint(
        'LAUNCH RESULT: $launched',
      );

      if (launched) {
        return;
      }

      // --------------------------------------------------------
      // If launchUrl fails
        // --------------------------------------------------------

      debugPrint(
        'External browser could not be opened.',
      );

      if (!mounted) return;

      _showBrowserError();

    } catch (e, stackTrace) {
      debugPrint(
        'OPEN EXTERNAL URL ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

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
  // PREPARE WEBVIEW
  // ============================================================

  Future<void> _prepareAndOpenWebView() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    final user = authProvider.user;

    // ----------------------------------------------------------
    // CHECK USER
    // ----------------------------------------------------------

    if (user == null ||
        user.loginToken == null ||
        user.loginToken!.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    // ----------------------------------------------------------
    // LOGIN URL
    // ----------------------------------------------------------

    final url =
        'https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';

    debugPrint(
      'LOGIN URL: $url',
    );

    // ----------------------------------------------------------
    // CREATE CONTROLLER
    // ----------------------------------------------------------

    final controller =
        _createWebViewController();

    _webViewController = controller;

    // ----------------------------------------------------------
    // LOAD WEBSITE
    // ----------------------------------------------------------

    await controller.loadRequest(
      Uri.parse(url),
    );

    // ----------------------------------------------------------
    // SHOW WEBVIEW AFTER 2 SECONDS
    // ----------------------------------------------------------

    _openWebViewTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _showWebView = true;
        });
      },
    );
  }

  // ============================================================
  // OPEN WEBVIEW MANUALLY
  // ============================================================

  void _openWebView(UserModel user) {
    if (user.loginToken == null ||
        user.loginToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login token is not available',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final url =
        'https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';

    final controller =
        _createWebViewController();

    _webViewController = controller;

    controller.loadRequest(
      Uri.parse(url),
    );

    setState(() {
      _showWebView = true;
    });
  }

  // ============================================================
  // CLOSE WEBVIEW
  // ============================================================

  void _closeWebView() {
    setState(() {
      _showWebView = false;
      _webViewController = null;
    });
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
    final authProvider =
        Provider.of<AuthProvider>(context);

    final user = authProvider.user;

    // ==========================================================
    // LOADING SCREEN
    // ==========================================================

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,

        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------

                Container(
                  width: 90,
                  height: 90,

                  decoration: BoxDecoration(
                    color:
                        AppColors.primaryBackground,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),

                  child: const Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                const Text(
                  'Welcome to ZeeCV',

                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------

                Text(
                  'Preparing your ZeeCV account...',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // LOADER
                // ------------------------------------------------

                const SizedBox(
                  width: 35,
                  height: 35,

                  child:
                      CircularProgressIndicator(
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

    // ==========================================================
    // WEBVIEW
    // ==========================================================

    if (_showWebView &&
        _webViewController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ZEECV'),

          // ----------------------------------------------------
          // CLOSE APPLICATION
          // ----------------------------------------------------

          leading: IconButton(
            icon: const Icon(Icons.close),

            onPressed: () {
             _showExitConfirmationDialog(context);
            },
          ),

          // ----------------------------------------------------
          // REFRESH
          // ----------------------------------------------------

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
          controller:
              _webViewController!,
        ),
      );
    }

    // ==========================================================
    // NORMAL HOME SCREEN
    // ==========================================================

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.appName,
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    AppStrings.logoutSuccess,
                  ),
                  backgroundColor:
                      AppColors.success,
                ),
              );

              context.go('/login');
            },

            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              // ------------------------------------------------
              // USER AVATAR
              // ------------------------------------------------

              CircleAvatar(
                radius: 60,

                backgroundColor:
                    AppColors.primaryBackground,

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
                      fontWeight:
                          FontWeight.bold,
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
                  color:
                      AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // USER ID
              // ------------------------------------------------

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color:
                      AppColors.primaryBackground,

                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Text(
                  'ID: ${user?.id ?? 'N/A'}',

                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // OPEN ZEECV
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,

                child:
                    ElevatedButton.icon(
                  onPressed: user == null
                      ? null
                      : () =>
                          _openWebView(user),

                  icon: const Icon(
                    Icons.language,
                  ),

                  label: const Text(
                    'Open ZEECV',
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
    if (user?.name != null &&
        user!.name!.isNotEmpty) {
      return user.name!
          .substring(0, 1)
          .toUpperCase();
    }

    if (user?.email != null &&
        user!.email!.isNotEmpty) {
      return user.email!
          .substring(0, 1)
          .toUpperCase();
    }

    return 'U';
  }
}
void _showExitConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              exit(0); // Exit app
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      );
    },
  );
}