import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6A1B9A);
    const accentOrange = Color(0xFFFF8F00);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC),

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: primaryPurple,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔥 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Color(0xFF6A1B9A)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "User",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Logged User",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  ProfileMenu(title: "Edit Profile", icon: Icons.edit),
                  ProfileMenu(title: "Transaction History", icon: Icons.history),
                  ProfileMenu(title: "Notifications", icon: Icons.notifications),
                  ProfileMenu(title: "Settings", icon: Icons.settings),
                  ProfileMenu(title: "Logout", icon: Icons.logout),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
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

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      await http.post(
        Uri.parse("https://artbiglobalph.com/api/logout.php"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    } catch (_) {
      // ignore error, still logout locally
    }

    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (title == "Logout") {
            logout(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$title clicked")),
            );
          }
        },
      ),
    );
  }
}