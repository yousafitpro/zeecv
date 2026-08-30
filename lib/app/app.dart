import 'package:flutter/material.dart';
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
    final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();
    // Wait for initialization
    if (!authProvider.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'ZeeCV 2',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}