import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeecv/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'package:go_router/go_router.dart'; // 👈 ADD THIS

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();

      await authProvider.openZeecvAndCloseApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? UserModel(
      name: 'Guest',
      id: 'N/A',
      email: 'No email',
    );
    
    if (user == null ) {
      print(user);
      
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            onPressed: () async {
              // await authProvider.signOut();
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
              // Profile Avatar
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
              
              // User ID (optional)
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
              
              const SizedBox(height: 48),
              
              // Resume Builder Coming Soon
              // Container(
              //   padding: const EdgeInsets.all(24),
              //   decoration: BoxDecoration(
              //     color: AppColors.primaryBackground,
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              //   ),
              //   child: Column(
              //     children: [
              //       Icon(
              //         Icons.build_circle_outlined,
              //         size: 64,
              //         color: AppColors.primary,
              //       ),
              //       const SizedBox(height: 16),
              //       const Text(
              //         'Resume Builder Coming Soon!',
              //         style: TextStyle(
              //           fontSize: 20,
              //           fontWeight: FontWeight.bold,
              //           color: AppColors.primary,
              //         ),
              //       ),
              //       const SizedBox(height: 8),
              //       const Text(
              //         'We\'re building the best resume maker for you. Stay tuned!',
              //         textAlign: TextAlign.center,
              //         style: TextStyle(
              //           fontSize: 14,
              //           color: AppColors.textSecondary,
              //         ),
              //       ),
              //       const SizedBox(height: 16),
              //       LinearProgressIndicator(
              //         value: 0.3,
              //         backgroundColor: AppColors.background,
              //         color: AppColors.primary,
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}