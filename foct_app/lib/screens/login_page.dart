import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_background.dart';
import '../navigation/main_navigation.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController =
      TextEditingController();
  final TextEditingController codeController =
      TextEditingController();

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

  await prefs.setString(
    "token",
    data["token"] ?? "",
  );

  await prefs.setString(
    "name",
    data["user"]?["name"] ?? "",
  );

  await prefs.setString(
    "email",
    data["user"]?["email"] ?? "",
  );

  await prefs.setString(
    "phone",
    data["user"]?["phone"] ?? "",
  );

  await prefs.setString(
    "address",
    data["user"]?["address"] ?? "",
  );

  await prefs.setString(
    "member_code",
    data["user"]?["member_code"] ?? "",
  );

  await prefs.setInt(
    "total_points",
    data["user"]?["total_points"] ?? 0,
  );

  print(
    "NAME: ${prefs.getString("name")}"
  );

  print(
    "MEMBER CODE: ${prefs.getString("member_code")}"
  );

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const MainNavigation(),
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18),
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
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
            children: [
              const SizedBox(height: 15),

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Welcome back! Please login\n to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 40),

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

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
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
                  padding:
                      const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7B2CBF),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Image.network(
                    "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                    height: 22,
                  ),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.facebook,
                    color: Colors.blue,
                  ),
                  label: const Text(
                    "Continue with Facebook",
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF7B2CBF),
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 150),
            ],
          ),),
        ),
      ),
    );
  }
}