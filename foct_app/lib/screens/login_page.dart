import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../navigation/main_navigation.dart';
import '../widgets/app_background.dart';
import 'signup_page.dart'; // ✅ ADD THIS

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final memberCode = identifierController.text.trim();
    final code = codeController.text.trim();

    if (memberCode.isEmpty || code.isEmpty) {
      setState(() {
        error = "All fields are required";
        isLoading = false;
      });
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("https://artbiglobalph.com/api/sign_in.php"), // 🔥 CHANGE THIS
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_code": memberCode,
          "code": code,
        }),
      );

      // ✅ Handle non-200 response
      if (res.statusCode != 200) {
        setState(() {
          error = "Server error (${res.statusCode})";
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", data["token"]);
        await prefs.setString("member_code", data["member_code"]);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        setState(() {
          error = data["message"] ?? "Login failed";
        });
      }
    } catch (e) {
  setState(() {
    error = "Error: $e";
  });
}

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    identifierController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/logo.png",
                    height: 60,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.lock, size: 60),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Login using your Member Code",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller: identifierController,
                    decoration: InputDecoration(
                      hintText: "Member Code (e.g. A7X9Q2)",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: codeController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Unique Code",
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6F00),
                            Color(0xFF6A1B9A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Login"),
                      ),
                    ),
                  ),

                  // 🔥 NEW SIGNUP BUTTON
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}