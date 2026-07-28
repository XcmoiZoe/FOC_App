import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/main_navigation.dart';
import '../widgets/purple_background.dart';
import 'auth_choice_page.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  /// If true the splash will automatically navigate to the login page after [delaySeconds].
  final bool autoNavigate;

  /// Show or hide the robot image.
  final bool showRobot;

  /// Delay before navigation when [autoNavigate] is true.
  final int delaySeconds;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
    this.showRobot = true,
    this.delaySeconds = 3,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoNavigate) {
      Future.delayed(Duration(seconds: widget.delaySeconds), () async {
        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        final memberCode = prefs.getString('member_code');

        if (token != null && token.isNotEmpty && memberCode != null && memberCode.isNotEmpty) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainNavigation(memberCode: memberCode),
            ),
          );
        } else {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthChoicePage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            const PurpleBackground(),

            // Logo
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  "assets/logo1.png",
                  width: screenWidth * 0.70,
                ),
              ),
            ),

            // Footer (Always at bottom)
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.35,
                child: SvgPicture.asset(
                  "assets/footer.svg",
                  width: screenWidth,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),

            // Robot (position dynamically based on screen height)
            if (widget.showRobot)
              Positioned(
                left: 0,
                right: 0,
                bottom: screenHeight * 0.18, // responsive spacing above footer/skyline
                child: Center(
                  child: Image.asset(
                    "assets/robot.png",
                    width: screenWidth * 0.52,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}