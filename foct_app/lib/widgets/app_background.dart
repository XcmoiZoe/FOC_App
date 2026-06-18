import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: child,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // move footer higher
            child: IgnorePointer(
              child: Image.asset(
                'assets/footer.png',
                fit: BoxFit.fitWidth,
                height: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}