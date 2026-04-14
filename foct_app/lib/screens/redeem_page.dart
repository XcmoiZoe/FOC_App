import 'package:flutter/material.dart';

class RedeemPage extends StatelessWidget {
  const RedeemPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6A1B9A);
    const accentOrange = Color(0xFFFF8F00);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Rewards"),
        backgroundColor: primaryPurple,
      ),
      backgroundColor: const Color(0xFFF8F5FC),

      body: Column(
        children: [

          // 🔥 POINTS CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                )
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Points",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "1,250 pts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 🛍️ LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                RedeemItem(
                  title: "Atomy Toothpaste",
                  points: "300 pts",
                  image: "assets/atomy_toothpaste.png",
                ),
                RedeemItem(
                  title: "Atomy Vitamin C",
                  points: "500 pts",
                  image: "assets/atomy_vitc.png",
                ),
                RedeemItem(
                  title: "Atomy Skincare Set",
                  points: "1000 pts",
                  image: "assets/atomy_skincare.png",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RedeemItem extends StatelessWidget {
  final String title;
  final String points;
  final String image;

  const RedeemItem({
    super.key,
    required this.title,
    required this.points,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    const accentOrange = Color(0xFFFF8F00);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        // 🖼️ IMAGE (safe fallback)
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported);
            },
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text(points),

        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Redeemed $title"),
                backgroundColor: accentOrange,
              ),
            );
          },
          child: const Text("Redeem"),
        ),
      ),
    );
  }
}