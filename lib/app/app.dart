import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/services/api_service.dart';
import '../core/themes/theme.dart';
import '../providers/auth_provider.dart';
import 'router.dart';

class ZeeCVApp extends StatelessWidget {
  const ZeeCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'ZeeCV',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return PopScope(
          // ✅ Let the app handle back normally — we decide in the callback
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // 1. If the router can go back → pop normally
            if (AppRouter.router.canPop()) {
              AppRouter.router.pop();
              return;
            }

            // 2. Otherwise we're at the root — ask before exiting
            final shouldExit = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Exit app?'),
                content: const Text('Do you really want to close ZeeCV?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );

            if (shouldExit == true) {
              SystemNavigator.pop();
            }
          },
          child: child!,
        );
      },
    );
  }
}