import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/purple_background.dart';
import '../navigation/main_navigation.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
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
        Uri.parse("http://54.255.150.15/mobile-api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_code": memberCode,
          "code": code,
        }),
      );

      if (res.statusCode != 200) {
        setState(() {
          error = "Server Error (${res.statusCode})";
          isLoading = false;
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", data["token"] ?? "");
        await prefs.setString("member_code", memberCode);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(memberCode: memberCode),
          ),
        );
      } else {
        setState(() {
          error = data["message"] ?? "Login Failed";
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

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          prefixIcon: Icon(
            icon,
            color: Colors.grey,
          ),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // use theme background
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const PurpleBackground(),
          Align(
            alignment: Alignment.bottomCenter,
            child: SvgPicture.asset(
              'assets/footer.svg',
              fit: BoxFit.fitWidth,
              width: screenWidth,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.12),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Login",
                          style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.deepPurple),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Welcome back! Please login to continue.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 15),
                        ),
                        const SizedBox(height: 32),
                        buildTextField(
                          controller: identifierController,
                          hint: "Member Code",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        buildTextField(
                          controller: codeController,
                          hint: "Login Code",
                          icon: Icons.lock_outline,
                          obscure: obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final result = await Navigator.push<Map<String, String>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage(),
                                ),
                              );

                              final memberCode = result?["member_code"];
                              if (memberCode != null && memberCode.isNotEmpty) {
                                identifierController.text = memberCode;
                              }
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF7B2CBF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    "LOGIN",
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Color(0xFF6B6B86)),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPage(),
                                  ),
                                );
                              },
                              child: Text(
                                  "Sign Up",
                                  style: GoogleFonts.poppins(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
