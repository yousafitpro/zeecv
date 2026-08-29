import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -0.7), // 135deg angle (top-left to bottom-right)
          end: Alignment(0.7, 0.7),
          colors: [
            Color(0xFFFFF1EC), // #fff1ec - Very light peach
            Color(0xFFF3E7E9), // #f3e7e9 - Light pinkish gray
            Color(0xFFE3EEFF), // #e3eeff - Light blue
            Color(0xFFE0F2FE), // #e0f2fe - Very light sky blue
          ],
          stops: const [0.0, 0.25, 0.6, 1.0], // Match the percentage stops
        ),
      ),
    );
  }
}