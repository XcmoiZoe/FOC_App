import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/about_page.dart';
import '../screens/redeem_page.dart';
import '../screens/market_page.dart';
import '../screens/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AboutPage(),
    RedeemPage(),
    MarketPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,

          // 🎨 THEME COLORS
          selectedItemColor: const Color(0xFFFF6F00), // ORANGE
          unselectedItemColor: Colors.grey,

          backgroundColor: Colors.white,
          elevation: 10,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),

          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'Learn',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Redeem',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Market',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}