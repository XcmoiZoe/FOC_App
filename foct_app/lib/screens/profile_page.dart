import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'User';
  String memberCode = '';
  String email = '';
  String phone = '';
  String address = '';
  int totalPoints = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token == null ||
          token.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(
          'http://54.255.150.15/mobile-api/profile',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Content-Type':
              'application/json',
        },
      );

      final data =
          jsonDecode(response.body);

      if (data['success'] == true) {
        final user = data['user'];

        if (!mounted) return;

        setState(() {
          name =
              user['name'] ?? 'User';

          memberCode =
              user['member_code'] ?? '';

          email =
              user['email'] ?? '';

          phone =
              user['phone'] ?? '';

          address =
              user['address'] ?? '';

          totalPoints =
              (user['total_points'] ?? 0)
                  .toInt();

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'PROFILE ERROR: $e',
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                            20),
                    decoration:
                        const BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          Color(
                              0xFF6A1B9A),
                          Color(
                              0xFFFF8F00),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.only(
                        bottomLeft:
                            Radius.circular(
                                25),
                        bottomRight:
                            Radius.circular(
                                25),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                        const SizedBox(
                            height: 10),
                        Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(
                            height: 5),
                        Text(memberCode, style: GoogleFonts.poppins(color: Colors.white70)),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 20),

                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        ProfileInfo(
                          title: "Email",
                          value: email,
                        ),
                        ProfileInfo(
                          title: "Phone",
                          value: phone,
                        ),
                        ProfileInfo(
                          title: "Address",
                          value: address,
                        ),
                        ProfileInfo(
                          title:
                              "Total Points",
                          value:
                              totalPoints
                                  .toString(),
                        ),

                        const SizedBox(
                            height: 10),

                        const ProfileMenu(
                          title:
                              "Edit Profile",
                          icon:
                              Icons.edit,
                        ),
                        const ProfileMenu(
                          title:
                              "Transaction History",
                          icon:
                              Icons.history,
                        ),
                        const ProfileMenu(
                          title:
                              "Notifications",
                          icon: Icons
                              .notifications,
                        ),
                        const ProfileMenu(
                          title:
                              "Settings",
                          icon: Icons
                              .settings,
                        ),

                        Card(
                          child: ListTile(
                            leading:
                                const Icon(
                              Icons.logout,
                              color:
                                  Colors.red,
                            ),
                            title: const Text(
                              "Logout",
                            ),
                            trailing:
                                const Icon(
                              Icons
                                  .arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: logout,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                      height: 20),
                ],
              ),
            ),
    );
  }
}

class ProfileInfo extends StatelessWidget {
  final String title;
  final String value;

  const ProfileInfo({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600)),
        subtitle: Text(value.isEmpty ? '-' : value, style: GoogleFonts.poppins(color: Colors.black54)),
      ),
    );
  }
}

class ProfileMenu extends StatelessWidget {
  final String title;
  final IconData icon;

  const ProfileMenu({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryPurple),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title clicked")));
        },
      ),
    );
  }
}