import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;
  String? message;

  Future<void> signup() async {
    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final res = await http.post(
        Uri.parse("http://artbiglobalph.com/api/sign_up.php"), // 🔥 CHANGE THIS
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "phone": phoneController.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final memberCode = data["member_code"];
        final generatedCode = data["generated_code"];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Account Created"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow("Member Code", memberCode),
                const SizedBox(height: 10),
                _infoRow("Login Code", generatedCode),

                const SizedBox(height: 12),

                const Text(
                  "⚠️ Save this code. You will need it to login.",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: "$memberCode / $generatedCode"),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard")),
                  );
                },
                child: const Text("Copy"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // back to login
                },
                child: const Text("Continue"),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          message = data["message"] ?? "Signup failed";
        });
      }
    } catch (e) {
      setState(() {
        message = "Connection error";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: "Email (optional)",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      hintText: "Phone (optional)",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        message!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : signup,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Sign Up"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Already have account? Login"),
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