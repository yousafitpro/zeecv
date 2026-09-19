import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
          body: Center(
            child: CircularProgressIndicator(),
          ),
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
          // Prevent Android from closing the app automatically
          canPop: false,

          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final shouldClose = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Close App'),
                  content: const Text(
                    'Are you sure you want to close the app?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      child: const Text('NO'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: const Text('YES'),
                    ),
                  ],
                );
              },
            );

            if (shouldClose == true) {
              SystemNavigator.pop();
            }
          },

          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}