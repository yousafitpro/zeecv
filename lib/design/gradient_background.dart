import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
const GradientBackground({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAD0C4), // Soft pink
            Color(0xFFFFD1FF), // Light purple
          ],
        ),
        ),
      );
  }
}