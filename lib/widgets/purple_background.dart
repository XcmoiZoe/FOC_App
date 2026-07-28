import 'package:flutter/material.dart';

class PurpleBackground extends StatelessWidget {
  const PurpleBackground({super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF230464),
            Color(0xFF230464),
            Color(0xFF230464),
          ],
        ),
      ),
    );
  }
}