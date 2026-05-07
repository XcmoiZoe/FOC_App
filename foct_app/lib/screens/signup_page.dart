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
  String? message;

  Future<void> signup() async {

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      message = null;
    });

    try {

      final fname =
          fnameController.text.trim();

      final email =
          emailController.text.trim();

      final phone =
          phoneController.text.trim();

      final address =
          addressController.text.trim();

      // ✅ REQUIRED VALIDATION
      if (
          fname.isEmpty ||
          email.isEmpty ||
          phone.isEmpty ||
          address.isEmpty
      ) {

        setState(() {

          message =
          "All fields are required";

          isLoading = false;
        });

        return;
      }

      // ✅ API REQUEST
      final res = await http.post(

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

      ).timeout(
        const Duration(seconds: 15),
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      // ✅ SERVER ERROR
      if (res.statusCode != 200) {

        setState(() {
          message =
          "Server error (${res.statusCode})";
        });

        return;
      }

      final data = jsonDecode(res.body);

      // ✅ SUCCESS
      if (data["success"] == true) {

        final memberCode =
        data["member_code"];

        final generatedCode =
        data["generated_code"];

        if (!mounted) return;

        showDialog(

          context: context,

          barrierDismissible: false,

          builder: (_) => AlertDialog(

            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),

            title: const Text(
              "Account Created",
            ),

            content: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                _infoRow(
                  "Member Code",
                  memberCode,
                ),

                const SizedBox(height: 12),

                _infoRow(
                  "Login Code",
                  generatedCode,
                ),

                const SizedBox(height: 16),

                const Text(

                  "⚠️ Save this login code carefully. "
                  "You will need it to sign in.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            actions: [

              // ✅ COPY
              TextButton(

                onPressed: () {

                  Clipboard.setData(

                    ClipboardData(
                      text:
                      "$memberCode / $generatedCode",
                    ),
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(
                      content: Text(
                        "Copied to clipboard",
                      ),
                    ),
                  );
                },

                child: const Text("Copy"),
              ),

              // ✅ CONTINUE
              TextButton(

                onPressed: () {

                  Navigator.pop(context);
                  Navigator.pop(context);
                },

                child: const Text("Continue"),
              ),
            ],
          ),
        );

      } else {

        setState(() {
          message =
              data["message"] ??
              "Signup failed";
        });
      }

    } catch (e) {

      print(e);

      setState(() {
        message = "Error: $e";
      });

    } finally {

      if (mounted) {

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _infoRow(
      String label,
      String value,
      ) {

    return Column(

      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 4),

        SelectableText(

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

        child: Center(

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(20),

            child: Container(

              width: 360,

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(

                color: Colors.white.withOpacity(0.95),

                borderRadius:
                BorderRadius.circular(20),

                boxShadow: [

                  BoxShadow(

                    color:
                    Colors.black.withOpacity(0.1),

                    blurRadius: 20,

                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text(

                    "Create Account",

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ FULL NAME
                  TextField(

                    controller: fnameController,

                    decoration: InputDecoration(

                      hintText: "Full Name",

                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          left: 14,
                          right: 10,
                        ),
                        child: Icon(
                          Icons.person_outline,
                        ),
                      ),

                      prefixIconConstraints:
                      const BoxConstraints(
                        minWidth: 45,
                        minHeight: 45,
                      ),

                      filled: true,

                      fillColor:
                      Colors.grey.shade100,

                      border: OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(12),

                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ EMAIL
                  TextField(

                    controller: emailController,

                    keyboardType:
                    TextInputType.emailAddress,

                    decoration: InputDecoration(

                      hintText: "Email",

                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          left: 14,
                          right: 10,
                        ),
                        child: Icon(
                          Icons.email_outlined,
                        ),
                      ),

                      prefixIconConstraints:
                      const BoxConstraints(
                        minWidth: 45,
                        minHeight: 45,
                      ),

                      filled: true,

                      fillColor:
                      Colors.grey.shade100,

                      border: OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(12),

                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ PHONE
                  TextField(

                    controller: phoneController,

                    keyboardType:
                    TextInputType.phone,

                    decoration: InputDecoration(

                      hintText: "Phone",

                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          left: 14,
                          right: 10,
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                        ),
                      ),

                      prefixIconConstraints:
                      const BoxConstraints(
                        minWidth: 45,
                        minHeight: 45,
                      ),

                      filled: true,

                      fillColor:
                      Colors.grey.shade100,

                      border: OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(12),

                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

          TextField(

  controller: addressController,

  maxLines: 2,

  decoration: InputDecoration(

    hintText: "Address",

    prefixIcon: const Icon(
      Icons.location_on_outlined,
    ),

    prefixIconConstraints:
    const BoxConstraints(
      minWidth: 50,
      minHeight: 50,
    ),

    contentPadding:
    const EdgeInsets.symmetric(
      vertical: 20,
      horizontal: 12,
    ),

    filled: true,

    fillColor: Colors.grey.shade100,

    border: OutlineInputBorder(

      borderRadius:
      BorderRadius.circular(12),

      borderSide: BorderSide.none,
    ),
  ),
),

                  const SizedBox(height: 20),

                  // ✅ MESSAGE
                  if (message != null)

                    Padding(

                      padding:
                      const EdgeInsets.only(
                        bottom: 10,
                      ),

                      child: Text(

                        message!,

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),

                  // ✅ BUTTON
                  SizedBox(

                    width: double.infinity,

                    child: ElevatedButton(

                      onPressed:
                      isLoading ? null : signup,

                      style: ElevatedButton.styleFrom(

                        backgroundColor:
                        const Color(0xFF7B1FA2),

                        foregroundColor:
                        Colors.white,

                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 14,
                        ),

                        shape: RoundedRectangleBorder(

                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),

                      child: isLoading

                          ? const SizedBox(

                        width: 20,
                        height: 20,

                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )

                          : const Text(
                        "Sign Up",
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(

                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text(
                      "Already have account? Login",
                    ),
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