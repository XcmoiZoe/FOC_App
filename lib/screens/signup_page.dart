import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';
import '../widgets/purple_background.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController fnameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  bool isLoading = false;
  bool agreeTerms = false;
  String? message;

  // ============================================================
  // SIGNUP
  // ============================================================

  Future<void> signup() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final fname = fnameController.text.trim();
      final email =
          emailController.text.trim().toLowerCase();
      final phone = phoneController.text.trim();
      final address = addressController.text.trim();

      // ========================================================
      // REQUIRED FIELDS
      // ========================================================

      if (fname.isEmpty ||
          email.isEmpty ||
          phone.isEmpty ||
          address.isEmpty) {
        setState(() {
          message = 'All fields are required.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // NAME VALIDATION
      // ========================================================

      if (fname.length < 2) {
        setState(() {
          message =
              'Name must be at least 2 characters long.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // EMAIL VALIDATION
      // ========================================================

      final emailRegex = RegExp(
        r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
      );

      if (!emailRegex.hasMatch(email)) {
        setState(() {
          message =
              'Please enter a valid email address.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // PHONE VALIDATION
      // ========================================================
      //
      // Philippines:
      // 09171234567
      // 09981234567
      //
      // Korea:
      // 01012345678
      // 0111234567
      // 0161234567
      // 0171234567
      // 0181234567
      // 0191234567
      //
      // Must match the Next.js API.
      // ========================================================

      final phoneRegex = RegExp(
        r'^(09\d{9}|01[016789]\d{7,8})$',
      );

      if (!phoneRegex.hasMatch(phone)) {
        setState(() {
          message =
              'Please enter a valid Philippine or Korean mobile number.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // TERMS & CONDITIONS
      // ========================================================

      if (!agreeTerms) {
        setState(() {
          message =
              'Please accept Terms & Conditions.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // API REQUEST
      // ========================================================

      final uri = Uri.parse(
        'http://54.255.150.15/mobile-api/signup',
      );

      http.Response res;

      try {
        res = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'name': fname,
                'email': email,
                'phone': phone,
                'address': address,
              }),
            )
            .timeout(
              const Duration(seconds: 15),
            );
      } on http.ClientException catch (e) {
        debugPrint(
          '[SIGNUP] NETWORK ERROR: $e',
        );

        if (!mounted) return;

        setState(() {
          message =
              'Unable to connect to the server. Please check your internet connection and try again.';
          isLoading = false;
        });

        return;
      } catch (e) {
        debugPrint(
          '[SIGNUP] REQUEST ERROR: $e',
        );

        if (!mounted) return;

        setState(() {
          message =
              'Unable to connect to the server. Please try again.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // PARSE RESPONSE
      // ========================================================

      Map<String, dynamic> data;

      try {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          throw const FormatException(
            'Invalid server response',
          );
        }
      } catch (e) {
        debugPrint(
          '[SIGNUP] RESPONSE PARSE ERROR: $e',
        );

        debugPrint(
          '[SIGNUP] STATUS CODE: ${res.statusCode}',
        );

        debugPrint(
          '[SIGNUP] RESPONSE BODY: ${res.body}',
        );

        if (!mounted) return;

        setState(() {
          message =
              'The server returned an invalid response. Please try again.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // GET USER-FACING MESSAGE
      // ========================================================

      final serverMessage =
          data['message']?.toString().trim();

      // ========================================================
      // 409 - DUPLICATE
      // ========================================================

      if (res.statusCode == 409) {
        if (!mounted) return;

        setState(() {
          message = serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'Email or phone number already exists.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // 400 - VALIDATION ERROR
      // ========================================================

      if (res.statusCode == 400) {
        if (!mounted) return;

        setState(() {
          message = serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'Please check your information and try again.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // 500 / OTHER SERVER ERRORS
      // ========================================================

      if (res.statusCode != 200 &&
          res.statusCode != 201) {
        debugPrint(
          '[SIGNUP] SERVER ERROR ${res.statusCode}: ${res.body}',
        );

        if (!mounted) return;

        setState(() {
          message = serverMessage?.isNotEmpty == true
              ? serverMessage
              : 'Something went wrong. Please try again.';
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (data['success'] == true) {
        final memberCode =
            data['member_code']?.toString() ?? '';

        final generatedCode =
            data['login_code']?.toString() ?? '';

        if (!mounted) return;

        // ======================================================
        // ACCOUNT CREATED
        // ======================================================

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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

                const SizedBox(height: 16),

                Text(
                  'Your login details have also been sent to your email.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
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
                          '$memberCode / $generatedCode',
                    ),
                  );

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Copied to clipboard',
                      ),
                    ),
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
          ),
        );

        return;
      }

      // ========================================================
      // API RETURNED success:false
      // ========================================================

      if (!mounted) return;

      setState(() {
        message = serverMessage?.isNotEmpty == true
            ? serverMessage
            : 'Signup failed. Please try again.';
        isLoading = false;
      });
    } on FormatException catch (e) {
      debugPrint(
        '[SIGNUP] FORMAT ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        message =
            'Invalid data received from the server.';
        isLoading = false;
      });
    } on Exception catch (e) {
      debugPrint(
        '[SIGNUP] UNEXPECTED ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        message =
            'Something went wrong. Please try again.';
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '[SIGNUP] UNKNOWN ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        message =
            'Something went wrong. Please try again.';
        isLoading = false;
      });
    }

    // ========================================================
    // STOP LOADING
    // ========================================================

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: TextField(
        style: const TextStyle(
          color: Colors.black87,
        ),

        cursorColor:
            AppTheme.primaryPurple,

        controller: controller,

        keyboardType: keyboardType,

        inputFormatters:
            inputFormatters,

        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: hint,

          prefixIcon: Icon(
            icon,
            color: Colors.purple,
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    fnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          const PurpleBackground(),

          Align(
            alignment:
                Alignment.bottomCenter,

            child: SvgPicture.asset(
              'assets/footer.svg',
              fit: BoxFit.fitWidth,
              width: screenWidth,
            ),
          ),

          SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              child: Column(
                children: [
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,

                    decoration:
                        BoxDecoration(
                      color:
                          const Color.fromRGBO(
                        255,
                        255,
                        255,
                        0.96,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        28,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Color.fromRGBO(
                            0,
                            0,
                            0,
                            0.12,
                          ),
                          blurRadius: 24,
                          offset:
                              Offset(0, 12),
                        ),
                      ],
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .stretch,

                      children: [
                        Text(
                          'Create Account',
                          style:
                              GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppTheme
                                    .deepPurple,
                          ),
                          textAlign:
                              TextAlign.center,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          'Sign up to earn points and enjoy free WiFi.',
                          textAlign:
                              TextAlign.center,
                          style:
                              GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // NAME
                        buildField(
                          controller:
                              fnameController,
                          hint:
                              'Full Name',
                          icon: Icons
                              .person_outline,
                          keyboardType:
                              TextInputType
                                  .name,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // EMAIL
                        buildField(
                          controller:
                              emailController,
                          hint:
                              'Email Address',
                          icon: Icons
                              .email_outlined,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // PHONE
                        buildField(
                          controller:
                              phoneController,
                          hint:
                              'Phone Number',
                          icon: Icons
                              .phone_outlined,
                          keyboardType:
                              TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                            LengthLimitingTextInputFormatter(
                              11,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ADDRESS
                        buildField(
                          controller:
                              addressController,
                          hint:
                              'Address',
                          icon: Icons
                              .location_on_outlined,
                          keyboardType:
                              TextInputType
                                  .streetAddress,
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // TERMS
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .center,

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
                              child: Wrap(
                                crossAxisAlignment:
                                    WrapCrossAlignment
                                        .center,

                                children: [
                                  Text(
                                    'I agree to the ',
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      color:
                                          Colors
                                              .black,
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context:
                                            context,
                                        builder:
                                            (_) =>
                                                AlertDialog(
                                          backgroundColor:
                                              const Color(
                                            0xFF6A1B9A,
                                          ),

                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                              16,
                                            ),
                                          ),

                                          title:
                                              const Text(
                                            'YES! FREE WIFI',
                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.orange,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          content:
                                              const SingleChildScrollView(
                                            child:
                                                Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'By using this WiFi service you agree to the following terms.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      16,
                                                ),

                                                Text(
                                                  '• Free WiFi is intended for personal use only.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Watching advertisements may reward you with points.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Reward points are not redeemable for cash.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Points may expire based on promotional rules.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Internet sessions may have usage limits.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Abuse or fraudulent activity may suspend your account.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• Your information is protected under our privacy policy.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height:
                                                      8,
                                                ),

                                                Text(
                                                  '• YES! Free WiFi may update these terms without prior notice.',
                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(
                                                context,
                                              ),

                                              child:
                                                  const Text(
                                                'CLOSE',
                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors.orange,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },

                                    child:
                                        Text(
                                      'Terms & Conditions',
                                      style:
                                          GoogleFonts
                                              .poppins(
                                        color:
                                            AppTheme
                                                .primaryPurple,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ERROR MESSAGE
                        if (message != null)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 10,
                            ),

                            child: Container(
                              width:
                                  double.infinity,

                              padding:
                                  const EdgeInsets
                                      .all(
                                12,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .red
                                    .withOpacity(
                                  0.08,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  8,
                                ),

                                border:
                                    Border.all(
                                  color: Colors
                                      .red
                                      .withOpacity(
                                    0.25,
                                  ),
                                ),
                              ),

                              child: Text(
                                message!,

                                style:
                                    const TextStyle(
                                  color:
                                      Colors.red,
                                  fontSize:
                                      14,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(
                          height: 10,
                        ),

                        // SIGN UP BUTTON
                        SizedBox(
                          width:
                              double.infinity,

                          height: 52,

                          child:
                              ElevatedButton(
                            onPressed:
                                (!agreeTerms ||
                                        isLoading)
                                    ? null
                                    : signup,

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  AppTheme
                                      .primaryPurple,

                              disabledBackgroundColor:
                                  Colors.grey
                                      .shade400,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                            ),

                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors
                                          .white,
                                      strokeWidth:
                                          2.5,
                                    ),
                                  )
                                : Text(
                                    'SIGN UP',
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      color:
                                          Colors
                                              .white,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        Row(
                          children: [
                            const Expanded(
                              child:
                                  Divider(),
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 10,
                              ),

                              child: Text(
                                'or',
                                style:
                                    GoogleFonts
                                        .poppins(
                                  color: Colors
                                      .black45,
                                ),
                              ),
                            ),

                            const Expanded(
                              child:
                                  Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Text(
                              'Already have an account? ',
                              style:
                                  GoogleFonts
                                      .poppins(
                                fontSize: 16,
                                color: Colors
                                    .black87,
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                Navigator.pop(
                                    context);
                              },

                              child: Text(
                                'Login',
                                style:
                                    GoogleFonts
                                        .poppins(
                                  color: AppTheme
                                      .primaryPurple,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),
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