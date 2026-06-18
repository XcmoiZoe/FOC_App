import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/app_background.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final fnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading = false;
  bool agreeTerms = false;

  String? message;

  Future<void> signup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final fname = fnameController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final address = addressController.text.trim();

      if (fname.isEmpty ||
          email.isEmpty ||
          phone.isEmpty ||
          address.isEmpty) {
        setState(() {
          message = "All fields are required";
          isLoading = false;
        });
        return;
      }

      if (!agreeTerms) {
        setState(() {
          message = "Please accept Terms & Conditions";
          isLoading = false;
        });
        return;
      }

      final res = await http
          .post(
            Uri.parse(
              "https://artbiglobalph.com/api/sign_up.php",
            ),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "fname": fname,
              "email": email,
              "phone": phone,
              "address": address,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (res.statusCode != 200) {
        setState(() {
          message =
              "Server Error (${res.statusCode})";
        });
        return;
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        final memberCode =
            data["member_code"] ?? "";

        final generatedCode =
            data["generated_code"] ?? "";

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text(
              "Account Created",
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Member Code",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SelectableText(
                  memberCode,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Login Code",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SelectableText(
                  generatedCode,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          "$memberCode / $generatedCode",
                    ),
                  );

                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Copied to clipboard",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Copy",
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Continue",
                ),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          message =
              data["message"] ??
                  "Signup Failed";
        });
      }
    } catch (e) {
      setState(() {
        message = "Error: $e";
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Sign up to earn points\nand enjoy free WiFi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              buildField(
                controller: fnameController,
                hint: "Full Name",
                icon:
                    Icons.person_outline,
              ),

              const SizedBox(height: 14),

              buildField(
                controller:
                    emailController,
                hint:
                    "Email Address",
                icon:
                    Icons.email_outlined,
                keyboardType:
                    TextInputType
                        .emailAddress,
              ),

              const SizedBox(height: 14),

              buildField(
                controller:
                    phoneController,
                hint:
                    "Phone Number",
                icon:
                    Icons.phone_outlined,
                keyboardType:
                    TextInputType.phone,
              ),

              const SizedBox(height: 14),

              buildField(
                controller:
                    addressController,
                hint: "Address",
                icon: Icons
                    .location_on_outlined,
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Checkbox(
                    value:
                        agreeTerms,
                    onChanged:
                        (value) {
                      setState(() {
                        agreeTerms =
                            value ??
                                false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text:
                          const TextSpan(
                        style:
                            TextStyle(
                          color: Colors
                              .black87,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "I agree to the ",
                          ),
                          TextSpan(
                            text:
                                "Terms & Conditions",
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF7B1FA2,
                              ),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (message != null)
                Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    bottom: 10,
                  ),
                  child: Text(
                    message!,
                    style:
                        const TextStyle(
                      color:
                          Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : signup,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF7B1FA2,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(
                              color: Colors
                                  .white,
                            )
                          : const Text(
                              "SIGN UP",
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: const [
                  Expanded(
                    child: Divider(),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(
                            horizontal:
                                10),
                    child: Text(
                      "or",
                    ),
                  ),
                  Expanded(
                    child: Divider(),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                          context);
                    },
                    child:
                        const Text(
                      "Login",
                      style:
                          TextStyle(
                        color: Color(
                          0xFF7B1FA2,
                        ),
                        fontWeight:
                            FontWeight
                                .bold,
                                fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}