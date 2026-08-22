// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
// Import your screens
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/find_job_screen.dart';
import '../screens/my_jobs_screen.dart';
import '../screens/resume_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class AppRouter {
  // ============================================================
  // WEBVIEW HELPER FUNCTIONS
  // ============================================================

  // Check if URL is PDF or Download
  static bool _isPdfOrDownloadUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.endsWith('.pdf')) return true;
    if (lowerUrl.contains('.pdf?')) return true;
    if (lowerUrl.contains('/resume/download-pdf/')) return true;
    if (lowerUrl.contains('/download/')) return true;
    if (lowerUrl.contains('/download?')) return true;
    
    return false;
  }

  // Open external URL
  static Future<void> _openExternalUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
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
    } catch (e) {
      debugPrint('OPEN EXTERNAL URL ERROR: $e');
      if (context.mounted) {
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
    }
  }

  // Create WebViewController
  static WebViewController _createWebViewController(BuildContext context) {
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
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Load Error: ${error.description}")),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            debugPrint('NAVIGATION REQUEST: $url');

            if (_isPdfOrDownloadUrl(url)) {
              debugPrint('PDF/DOWNLOAD URL DETECTED');
              await _openExternalUrl(url, context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    return controller;
  }

  // ============================================================
  // OPEN WEBVIEW FOR RESUME
  // ============================================================

  static void _openEditResumeWebView(BuildContext context, UserModel user) {
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
    
    // Navigate to webview screen
    context.push('/webview', extra: {
      'url': url,
      'title': 'Edit Resume',
    });
  }

  // ============================================================
  // OPEN WEBVIEW FOR TERMS & CONDITIONS
  // ============================================================

  static void _openTermsAndConditions(BuildContext context) {
    context.push('/webview', extra: {
      'url': 'https://zeecv.com/terms?is_app=yes',
      'title': 'Terms & Conditions',
    });
  }

  // ============================================================
  // OPEN WEBVIEW FOR PRIVACY POLICY
  // ============================================================

  static void _openPrivacyPolicy(BuildContext context) {
    context.push('/webview', extra: {
      'url': 'https://zeecv.com/privacy-policy?is_app=yes',
      'title': 'Privacy Policy',
    });
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static void _logout(BuildContext context) {
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
              onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
                Navigator.of(context).pop();
                
                  
                  context.go('/login');
                await authProvider.logout();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.logoutSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
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
  // ROUTER CONFIGURATION
  // ============================================================

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isSignup = state.matchedLocation == '/signup';

      // If on splash screen
      if (isSplash) {
        return isAuthenticated ? '/home/find-jobs' : '/login';
      }

      // If authenticated and trying to access auth screens
      if (isAuthenticated && (isLogin || isSignup)) {
        return '/home/find-jobs';
      }

      // If not authenticated and trying to access home
      if (!isAuthenticated && state.matchedLocation.startsWith('/home')) {
        return '/login';
      }

      // Allow access
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // WebView route
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          final url = extra?['url'] ?? 'https://zeecv.com';
          final title = extra?['title'] ?? 'WebView';
          
          // Create webview controller
          final controller = _createWebViewController(context);
          controller.loadRequest(Uri.parse(url));
          
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    controller.reload();
                  },
                ),
              ],
            ),
            body: WebViewWidget(
              controller: controller,
            ),
          );
        },
      ),
      
      // Home shell route with tabs
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(
            tabNavigator: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const FindJobScreen(),
          ),
          GoRoute(
            path: '/home/find-jobs',
            name: 'find-jobs',
            builder: (context, state) => const FindJobScreen(),
          ),
          GoRoute(
            path: '/home/my-jobs',
            name: 'my-jobs',
            builder: (context, state) => const MyJobsScreen(),
          ),
          GoRoute(
            path: '/home/resume',
            name: 'resume',
            builder: (context, state) {
              final authProvider = Provider.of<AuthProvider>(context);
              final user = authProvider.user;
              return ResumeScreen(
                user: user,
                onEditResume: user != null 
                    ? () => _openEditResumeWebView(context, user)
                    : null,
              );
            },
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            builder: (context, state) {
              final authProvider = Provider.of<AuthProvider>(context);
              final user = authProvider.user;
              return ProfileScreen(
                user: user,
                onLogout: () => _logout(context),
                onEditResume: (user) => _openEditResumeWebView(context, user),
                onTermsAndConditions: () => _openTermsAndConditions(context),
                onPrivacyPolicy: () => _openPrivacyPolicy(context),
              );
            },
          ),
        ],
      ),
    ],
  );
}