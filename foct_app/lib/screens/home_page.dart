import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int points = 1250;
  int level = 3;

  final List<Map<String, dynamic>> activities = [
    {"title": "Ad Viewed 1000x", "points": "+200"},
    {"title": "Posted New Ad", "points": "+150"},
    {"title": "Daily Login Bonus", "points": "+50"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yes Ads Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 POINTS CARD
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Points",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    points.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Level $level",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // 📊 PROGRESS BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Progress to next level"),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.6, // dynamic later
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🎁 REWARDS SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Rewards",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Rewards Cards
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  rewardCard("₱50 GCash", "1000 pts"),
                  rewardCard("₱100 Voucher", "2000 pts"),
                  rewardCard("Free Ad Boost", "1500 pts"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📜 ACTIVITY
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Recent Activity",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];

                return ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),
                  title: Text(item['title']),
                  trailing: Text(
                    item['points'],
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🔹 REWARD CARD WIDGET
  Widget rewardCard(String title, String cost) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 5, color: Colors.black12)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, color: Colors.red),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(
            cost,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}