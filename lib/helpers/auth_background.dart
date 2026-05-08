import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base white background
        Container(color: Colors.white),

        // Same pattern overlay as walkthrough
        Opacity(
          opacity: 0.3,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.multiply,
            ),
            child: SizedBox.expand(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Foreground screen
        child,
      ],
    );
  }
}