import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWebView = false;
  late final WebViewController _webViewController;
  String _webUrl = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      
      if (user?.loginToken != null) {
        setState(() {
          _webUrl = 'https://zeecv.com/mobile-app/login-using-token/${user!.loginToken}';
          _showWebView = true;
        });
        
        // _webViewController = WebViewController()
        //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
        //   ..setBackgroundColor(const Color(0x00000000))
        //   ..setNavigationDelegate(
        //     NavigationDelegate(
        //       onPageFinished: (String url) {
        //         // Page loaded
        //       },
        //     ),
        //   )
        //   ..loadRequest(Uri.parse(_webUrl));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (_showWebView && _webUrl.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ZEECV Web'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showWebView = false;
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _webViewController.reload();
              },
            ),
          ],
        ),
        body: WebViewWidget(
          controller: _webViewController,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () async {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.logoutSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/login');
              }
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
                  user?.name?.substring(0, 1).toUpperCase() ?? 
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}