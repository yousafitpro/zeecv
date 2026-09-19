import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
class LinkedinSignInButton extends StatelessWidget {
  const LinkedinSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: authProvider.isLoading ? null : () async {
          context.go('/in-app/signin',extra: {
                            'url':'https://zeecv.com/linkedin/auth?is_app=yes',
                            'back_url':'/login',
                            'title':'Linkedin Signin'
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
              'assets/images/linkedin.png',
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
          ],
        ),
      ),
    );
  }
}