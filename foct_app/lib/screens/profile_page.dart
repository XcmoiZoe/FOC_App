import 'package:flutter/material.dart';

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

            // 🔥 HEADER (USER INFO)
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
                children: [

                  // 👤 PROFILE IMAGE
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.person, size: 50, color: primaryPurple),
                  ),

                  const SizedBox(height: 10),

                  // 🧑 NAME
                  const Text(
                    "Juan Dela Cruz",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // 📧 EMAIL
                  const Text(
                    "user@email.com",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 15),

                  // 💎 POINTS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Points: 1,250",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 STATS CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ProfileStat(title: "Ads Watched", value: "35"),
                  ProfileStat(title: "Total Earned", value: "₱120"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⚙️ MENU OPTIONS
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

// 📊 STATS COMPONENT
class ProfileStat extends StatelessWidget {
  final String title;
  final String value;

  const ProfileStat({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ⚙️ MENU ITEM
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title clicked")),
          );
        },
      ),
    );
  }
}