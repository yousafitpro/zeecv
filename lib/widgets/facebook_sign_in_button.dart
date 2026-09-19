import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
class FacebookSignInButton extends StatelessWidget {
  const FacebookSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: authProvider.isLoading ? null : () async {
          context.go('/in-app/signin',extra: {
                            'url':'https://zeecv.com/facebook/auth?is_app=yes',
                            'back_url':'/login',
                            'title':'Facebook Signin'
                          });
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Logo (you can use asset or Text)
            Image.asset(
              'assets/images/facebook.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              authProvider.isLoading ? 'Signing in...' : 'Sign in with Google',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (authProvider.isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}