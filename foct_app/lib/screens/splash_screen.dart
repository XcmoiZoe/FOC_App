import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../navigation/main_navigation.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (!mounted) return;

    // ❌ No token → go login
    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("http://YOUR_SERVER/profile.php"), // 🔥 replace
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        // ❌ Invalid/expired token → clear + login
        await prefs.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      // ❌ Network error → fallback to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFFFF6F00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 100,
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Yes Ads Rewards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Earn. Redeem. Repeat.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text(
                    'Reward System Ready',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }
}