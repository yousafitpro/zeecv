import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // App Logo/Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Forgot Password!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email to reset password',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Email Field
                AuthTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: AppStrings.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                // Error Message
                if (authProvider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => authProvider.clearError(),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Sign In Button
                AuthButton(
                  text: AppStrings.submit,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await authProvider.forgotPassword(
                        email: _emailController.text.trim(),
                      );
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.loginSuccess),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.go('/login');
                      }
                    }
                  },
                  isLoading: authProvider.isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.orO,
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text(AppStrings.signIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}