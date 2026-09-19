import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/core/constants/app_colors.dart';
import 'package:zeecv/core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
class SinginInapp extends StatefulWidget {
  const SinginInapp({Key? key}) : super(key: key);

  @override
  State<SinginInapp> createState() => _SinginInappState();
}

class _SinginInappState extends State<SinginInapp> {
  String? _url;
  InAppWebViewController? _webViewController;

  double _progress = 0;

  // Prevents the token from being processed twice
  bool _tokenHandled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;



      final extra =
          GoRouterState.of(context).extra as Map<String, dynamic>?;

      final url = extra?['url'] as String? ?? '';

  

      if (url.isEmpty) {
        _showSnackBar(
          'ERROR: URL is empty',
          color: Colors.red,
        );
        return;
      }

      setState(() {
        _url = url;
      });

    });
  }

  void _showSnackBar(
    String message, {
    Color? color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: color ?? Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGIN SUCCESS HELPERS
  // ---------------------------------------------------------------------------

  /// True when URL contains `mobile-app-login-successful` anywhere in path/host.
  bool _isLoginSuccessUrl(WebUri uri) {
     final is_success=uri.path.contains('mobile-app-login-successful') ||
        uri.host.contains('mobile-app-login-successful');
    return is_success;
  }
  bool _isJobsUrl(WebUri uri) {
     final is_success=uri.path.contains('jobs') ||
        uri.host.contains('jobs');
    return is_success;
  }

  /// Extracts the token from the success URL.
  /// Supports:
  ///   https://zeecv.com/mobile-app-login-successful/<token>
  ///   https://zeecv.com/mobile-app-login-successful?token=<token>
  ///   zeecv://mobile-app-login-successful/<token>
  String _extractToken(WebUri uri) {
    // 1) Token as path segment after the marker
    final segments = uri.pathSegments;
    final idx = segments.indexWhere(
      (s) => s.contains('mobile-app-login-successful'),
    );
    if (idx != -1 && idx + 1 < segments.length) {
      return Uri.decodeComponent(segments[idx + 1]);
    }

    // 2) Token as query param
    final qToken = uri.queryParameters['token'];
    if (qToken != null && qToken.isNotEmpty) return qToken;

    // 3) Fallback: last non-empty path segment
    if (segments.isNotEmpty) {
      return Uri.decodeComponent(segments.last);
    }

    return '';
  }

  /// Called when the WebView hits the login-success URL.
  Future<void> _handleCloseWebview(String backUrl) async {
         if (!mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Login cancelled'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 2),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 500));
  if (!mounted) return;

  context.go(backUrl);
  }
  Future<void> _handleSuccessfulLogin(WebUri uri, String backUrl) async {
    if (_tokenHandled) return;
    _tokenHandled = true;

    final token = _extractToken(uri);

    if (token.isEmpty) {
      _showSnackBar(
        'Login failed: missing token',
        color: Colors.red,
      );
      return;
    }



    // -------------------------------------------------------------------------
    // TODO: persist the token here.
    // Example:
    //   final authProvider = context.read<AuthProvider>();
    //   await authProvider.loginWithToken(token);
    // -------------------------------------------------------------------------

    // Stop the WebView from loading the token URL.
    _webViewController?.stopLoading();

    // Give the snackbar a moment, then leave the WebView.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return; // ⬅️ critical: context may be gone after await
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
     final success = await authProvider.signInWithToken(token:token);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.loginSuccess),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.go('/dashboard');
                      }
  }

  @override
  Widget build(BuildContext context) {
    final extra =
        GoRouterState.of(context).extra as Map<String, dynamic>?;

    final backUrl =
        extra?['back_url'] as String? ?? '/home/find-jobs';

    final title =
        extra?['title'] as String? ?? 'Zeecv';

    if (_url == null || _url!.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(backUrl);
          },
        ),

        
      ),

      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(_url!),
              ),

              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
              ),

              // ==============================
              // WEBVIEW CREATED
              // ==============================

              onWebViewCreated: (controller) {
                _webViewController = controller;
              },

              // ==============================
              // LOAD START  ← SUCCESS LOGIN HERE
              // ==============================

              onLoadStart: (controller, url) {
                setState(() {
                  _progress = 0;
                });

                if (url == null) return;

                debugPrint('🌐 onLoadStart: $url');

                // ✅ Detect the login-success URL
                if (_isLoginSuccessUrl(url)) {
                  _handleSuccessfulLogin(url, backUrl);
                }
                if (_isJobsUrl(url)) {
                  _handleCloseWebview(backUrl);
                }
              },

              // ==============================
              // LOAD STOP
              // ==============================

              onLoadStop: (controller, url) {
                setState(() {
                  _progress = 1;
                });

                if (url == null) return;

              },

              // ==============================
              // PROGRESS
              // ==============================

              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },

              // ==============================
              // URL HISTORY
              // ==============================

              onUpdateVisitedHistory:
                  (controller, url, isReload) {
                // Uncomment if you want noisy logs:
                // _showSnackBar(
                //   'HISTORY UPDATED\n$url',
                //   color: Colors.purple,
                // );

                if (url != null && _isLoginSuccessUrl(url)) {
                  _handleSuccessfulLogin(url, backUrl);
                }
                if (url != null && _isJobsUrl(url)) {
                  _handleCloseWebview(backUrl);
                }
              },

              // ==============================
              // NAVIGATION
              // ==============================

              shouldOverrideUrlLoading:
                  (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                final url = uri?.toString() ?? '';

                debugPrint('➡️ shouldOverrideUrlLoading: $url');

                // ✅ Intercept the success URL before it loads
                if (uri != null && _isLoginSuccessUrl(uri)) {
                  await _handleSuccessfulLogin(uri, backUrl);
                  return NavigationActionPolicy.CANCEL;
                }
                if (uri != null && _isJobsUrl(uri)) {
                  _handleCloseWebview(backUrl);
                }

                return NavigationActionPolicy.ALLOW;
              },

              // ==============================
              // WEBVIEW ERROR
              // ==============================

              onReceivedError:
                  (controller, request, error) {
                // _showSnackBar(
                //   'WEBVIEW ERROR\n'
                //   '${request.url}\n'
                //   '${error.description}',
                //   color: Colors.red,
                // );
              },

              // ==============================
              // HTTP ERROR
              // ==============================

              onReceivedHttpError:
                  (controller, request, response) {
                // _showSnackBar(
                //   'HTTP ERROR\n'
                //   '${request.url}\n'
                //   'Status: ${response.statusCode}',
                //   color: Colors.red,
                // );
              },
            ),

            // ==============================
            // PROGRESS BAR
            // ==============================

            if (_progress < 1.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}