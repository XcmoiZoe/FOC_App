import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/app_background.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final phoneController = TextEditingController();
  bool isLoading = false;
  String? message;
  bool isSuccess = false;

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();

    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        isSuccess = false;
        message = "Phone number is required";
      });
      return;
    }

    setState(() {
      isLoading = true;
      isSuccess = false;
      message = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse("http://54.255.150.15/mobile-api/forgot"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"phone": phone}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      final success = response.statusCode == 200 && data["success"] == true;

      if (!mounted) return;

      if (success) {
        final result = <String, String>{};
        final memberCode = data["member_code"]?.toString();

        if (memberCode != null && memberCode.isNotEmpty) {
          result["member_code"] = memberCode;
        }

        setState(() {
          isSuccess = true;
          message = data["message"] ??
              "OTP sent. Please use the 6 digit code as your login code.";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message!)),
        );

        Navigator.pop(context, result);
      } else {
        setState(() {
          isSuccess = false;
          message = data["message"] ?? "Unable to send OTP";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSuccess = false;
        message = "Error: $e";
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter your phone number and we will send a 6 digit OTP.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 18),
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.grey,
                      ),
                      hintText: "Phone Number",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2CBF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "SEND LOGIN CODE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
