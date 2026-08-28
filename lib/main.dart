import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/stores/my_job_store.dart';
import 'app/app.dart';
import 'providers/auth_provider.dart';
// 1. Import your ApiService
import 'services/api_service.dart'; 
import 'stores/job_store.dart';
import 'stores/my_job_store.dart';
void main() async {
  // 2. This is required to allow loading assets (the cert) before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize the ApiService and load the SSL certificate
  // This will fix the "CERTIFICATE_VERIFY_FAILED" error
  final apiService = ApiService();
  await apiService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<JobStore>(
          create: (_) => JobStore(),
        ),
        ChangeNotifierProvider<MyJobStore>(
          create: (_) => MyJobStore(),
        ),
        
      ],
      child: const ZeeCVApp(),
    ),
  );
}