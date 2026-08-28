import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zeecv/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditResumeInapp extends StatefulWidget {
  const EditResumeInapp({Key? key}) : super(key: key);

  @override
  _EditResumeInappState createState() => _EditResumeInappState();
}

class _EditResumeInappState extends State<EditResumeInapp> {
  bool _showInAppBrowser = false;
  String? _inAppBrowserUrl;
  String? _downloadUrl;
  InAppWebViewController? _webViewController;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if widget is still mounted
      if (!mounted) return;
      
      // Use listen: false to avoid unnecessary rebuilds
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      // Safe access to loginToken
      final token = user?.loginToken;
      if (token != null && token.isNotEmpty) {
        setState(() {
          _showInAppBrowser = true;
          _inAppBrowserUrl = 'https://zeecv.com/mobile-app/login-using-token/$token';
          _downloadUrl = 'https://zeecv.com/mobile-app/resume/download/$token';
        });
      } else {
        // Handle case where user is not logged in
        print('User not logged in or token is missing');
        // Optionally show a message or navigate to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to edit your resume'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _closeInAppBrowser() {
    setState(() {
      _showInAppBrowser = false;
      _inAppBrowserUrl = '';
      _webViewController = null;
      _progress = 0;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final backUrl = extra?['back_url'] as String? ?? '/home/find-jobs';

    // Show in-app browser if enabled and URL exists
    if (_showInAppBrowser && _inAppBrowserUrl != null && _inAppBrowserUrl!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
        title: const Text("Your Resume"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Use the back_url from extra parameters
            context.go(backUrl);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Handle download action
              if (_downloadUrl != null && _downloadUrl!.isNotEmpty) {
                // You can either open the download URL in the webview or handle download differently
                // Option 1: Navigate to download URL in the same webview
                if (_webViewController != null) {
                  _webViewController?.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(_downloadUrl!),
                    ),
                  );
                }
                // Option 2: Show a snackbar with the download link
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading resume...'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                _showError('Download URL not available');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the web view or reload data
              if (_webViewController != null) {
                _webViewController?.reload();
              } else {
                // If not in web view, reload the token and show browser
                final authProvider = context.read<AuthProvider>();
                final token = authProvider.user?.loginToken;
                if (token != null && token.isNotEmpty) {
                  setState(() {
                    _showInAppBrowser = true;
                    _inAppBrowserUrl = 'https://zeecv.com/mobile-app/login-using-token/$token';
                  });
                }
              }
            },
          ),
        ],
      ),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(_inAppBrowserUrl!),
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _inAppBrowserUrl = url?.toString();
                  });
                },
                onLoadError: (controller, url, code, message) {
                  _showError('Failed to load page: $message');
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  _showError('HTTP Error $statusCode: $description');
                },
              ),
              
              // Progress indicator at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main screen with AppBar
    return Scaffold(
      body: SafeArea(child: Container(child: Text(''),),
      ),
    );
  }
}