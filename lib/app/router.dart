// lib/app/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Import your screens (use correct paths)
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/find_job_screen.dart';
import '../screens/my_jobs_screen.dart';
import '../screens/resume_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isSignup = state.matchedLocation == '/signup';

      // If on splash screen
      if (isSplash) {
        return isAuthenticated ? '/home/find-jobs' : '/login';
      }

      // If authenticated and trying to access auth screens
      if (isAuthenticated && (isLogin || isSignup)) {
        return '/home/find-jobs';
      }

      // If not authenticated and trying to access home
      if (!isAuthenticated && state.matchedLocation.startsWith('/home')) {
        return '/login';
      }

      // Allow access
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Home shell route with tabs
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(
            tabNavigator: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home/find-jobs',
            name: 'find-jobs',
            builder: (context, state) => const FindJobScreen(),
          ),
          GoRoute(
            path: '/home/my-jobs',
            name: 'my-jobs',
            builder: (context, state) => const MyJobsScreen(),
          ),
          GoRoute(
            path: '/home/resume',
            name: 'resume',
            builder: (context, state) {
              final authProvider = Provider.of<AuthProvider>(context);
              final user = authProvider.user;
              return ResumeScreen(
                user: user,
                onEditResume: user != null 
                    ? () {
                        // This will be handled by the HomeScreen
                        // We need to access the HomeScreen state
                      }
                    : null,
              );
            },
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            builder: (context, state) {
              final authProvider = Provider.of<AuthProvider>(context);
              final user = authProvider.user;
              return ProfileScreen(
                user: user,
                onLogout: () {
                  // Handle logout
                },
                onEditResume: (user) {
                  // Handle edit resume
                },
                onTermsAndConditions: () {
                  // Handle terms
                },
                onPrivacyPolicy: () {
                  // Handle privacy
                },
              );
            },
          ),
        ],
      ),
    ],
  );
}