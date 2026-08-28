import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zeecv/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DefaultInapp extends StatefulWidget {
  const DefaultInapp({Key? key}) : super(key: key);

  @override
  _DefaultInappState createState() => _DefaultInappState();
}

class _DefaultInappState extends State<DefaultInapp> {
  bool _showInAppBrowser = false;
  String? _url;
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final url = extra?['url'] as String? ?? '';

      if (url.isNotEmpty) {
        setState(() {
          _url = url;
          _showInAppBrowser = true;
        });
      }
            

    });
  }

  void _closeInAppBrowser() {
    setState(() {
      _showInAppBrowser = false;
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final backUrl = extra?['back_url'] as String? ?? '/home/find-jobs';
    final title = extra?['title'] as String? ?? 'Zeecv';

    if (_showInAppBrowser && _url != null && _url!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title:  Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go(backUrl);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_webViewController != null) {
                  _webViewController?.reload();
                } else {
                  final authProvider = context.read<AuthProvider>();
                  final token = authProvider.user?.loginToken;
                  if (token != null && token.isNotEmpty) {
                    setState(() {
                      _showInAppBrowser = true;
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
              key: ValueKey(_url),
              initialUrlRequest: URLRequest(
                url: WebUri(_url!),
              ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  _showError('Failed to load page: $message');
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  _showError('HTTP Error $statusCode: $description');
                },
                // Add this to handle downloads from within WebView
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_progress < 1.0)
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
      body: SafeArea(
        child: Container(
          child: const Text(''),
        ),
      ),
    );
  }
}