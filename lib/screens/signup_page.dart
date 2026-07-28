import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;

import '../widgets/purple_background.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

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
final email = emailController.text.trim().toLowerCase();
final phone = phoneController.text.trim();
final address = addressController.text.trim();

// Validate required fields first
if (fname.isEmpty ||
    email.isEmpty ||
    phone.isEmpty ||
    address.isEmpty) {
  setState(() {
    message = 'All fields are required';
    isLoading = false;
  });
  return;
}

// Email validation
final emailRegex = RegExp(
  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
);

if (!emailRegex.hasMatch(email)) {
  setState(() {
    message = 'Please enter a valid email address';
    isLoading = false;
  });
  return;
}

// Philippine mobile validation
if (!RegExp(r'^09\d{9}$').hasMatch(phone)) {
  setState(() {
    message = 'Please enter a valid phone number';
    isLoading = false;
  });
  return;
}

// Terms & Conditions
if (!agreeTerms) {
  setState(() {
    message = 'Please accept Terms & Conditions';
    isLoading = false;
  });
  return;
}

print("Sending Signup:");
print("Name: $fname");
print("Email: $email");
print("Phone: $phone");
print("Address: $address");
      final res = await http
          .post(
            Uri.parse('http://54.255.150.15/mobile-api/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': fname,
              'email': email,
              'phone': phone,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 409) {
        setState(() {
          message = data['message'] ?? 'Email or phone already exists';
          isLoading = false;
        });
        return;
      }

      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() {
          message = data['message'] ?? 'Server Error (${res.statusCode})';
          isLoading = false;
        });
        return;
      }

      if (data['success'] == true) {
        final memberCode = data['member_code'] ?? '';
        final generatedCode = data['login_code'] ?? '';

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  title: const Text(
    'Account Created',
    style: TextStyle(
      color: Colors.black,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Member Code',
        style: TextStyle(
          color: Colors.purple[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      SelectableText(
        memberCode,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Login Code',
        style: TextStyle(
          color: Colors.purple[600],
          fontWeight: FontWeight.w600,
        ),
      ),
      SelectableText(
        generatedCode,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
  actions: [
    TextButton(
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: '$memberCode / $generatedCode'),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
      child: const Text('Copy'),
    ),
    TextButton(
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
      child: const Text('Continue'),
    ),
  ],
)
        );
      } else {
        setState(() {
          message = data['message'] ?? 'Signup Failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: $e';
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.black87),
        cursorColor: AppTheme.primaryPurple,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.purple),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
                      boxShadow: const [
                        BoxShadow(
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
                        Text('Create Account', style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.deepPurple), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text('Sign up to earn points and enjoy free WiFi.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.black, fontSize: 15)),
                        const SizedBox(height: 28),
                        buildField(
                          controller: fnameController,
                          hint: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        buildField(
                          controller: emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        buildField(
                          controller: phoneController,
                          hint: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        buildField(
                          controller: addressController,
                          hint: 'Address',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: agreeTerms,
                              onChanged: (value) {
                                setState(() {
                                  agreeTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('I agree to the ', style: GoogleFonts.poppins(color: Colors.black)),
                         GestureDetector(
  onTap: () {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF6A1B9A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'YES! FREE WIFI',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By using this WiFi service you agree to the following terms.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 16),
              Text(
                '• Free WiFi is intended for personal use only.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Watching advertisements may reward you with points.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Reward points are not redeemable for cash.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Points may expire based on promotional rules.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Internet sessions may have usage limits.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Abuse or fraudulent activity may suspend your account.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• Your information is protected under our privacy policy.',
                style: TextStyle(color: Colors.orange),
              ),
              SizedBox(height: 8),
              Text(
                '• YES! Free WiFi may update these terms without prior notice.',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  },
  child: Text(
    'Terms & Conditions',
    style: GoogleFonts.poppins(
      color: AppTheme.primaryPurple,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              message!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (!agreeTerms || isLoading) ? null : signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('SIGN UP', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or', style: GoogleFonts.poppins(color: Colors.black45)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ', style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text('Login', style: GoogleFonts.poppins(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
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
