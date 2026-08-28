
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zeecv/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditResumeInapp extends StatefulWidget {
  const EditResumeInapp({ Key? key }) : super(key: key);


  @override
  _EditResumeInappState createState() => _EditResumeInappState();

}

class _EditResumeInappState extends State<EditResumeInapp> {
  bool _showInAppBrowser = false;
  String? _inAppBrowserUrl;
  InAppWebViewController? _webViewController;
  double _progress = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
          final authProvider = Provider.of<AuthProvider>(context);
          final user = authProvider.user;
          if (user?.loginToken != null && user!.loginToken!.isNotEmpty) {
          setState(() {
            _inAppBrowserUrl='https://zeecv.com/mobile-app/login-using-token/${user.loginToken}';
          });
          }
    });
    }
  void _closeInAppBrowser() {
    setState(() {
      _showInAppBrowser = false;
      _inAppBrowserUrl ='';
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
    final back_url = extra?['back_url'] as String? ?? '/home/find-jobs';
    if (_showInAppBrowser && _inAppBrowserUrl != null) {
      return Scaffold(
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
              ),
              // Floating close button
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: _closeInAppBrowser,
                  ),
                ),
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
    return Scaffold(
        appBar: AppBar(
            title: Text("Your Resume"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: ()=>{
                context.go(back_url)
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                },
              ),
            ],
          ),
        body: SafeArea(
          child: Text("ok")
        )
        );
  }
}