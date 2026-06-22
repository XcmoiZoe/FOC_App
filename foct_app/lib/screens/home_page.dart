import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  String userName = "Member";
  String memberCode = "";
  int totalPoints = 0;
  late AnimationController _spinController;
  bool _isSpinning = false;
  final int nextReward = 5000;
  int earnedPoints = 0;

  void showRoulettePopup() {
    // Sectors used by the client. The server should return one of these values.
    final sectors = <int>[10, 25, 50, 100, 200, 25, 10, 50];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        double wheelTurns() => _spinController.value;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("🎉 Welcome Bonus"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Spin the roulette to win points!"),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, __) {
                        return Transform.rotate(
                          angle: wheelTurns() * 2 * 3.1415926535,
                          child: CustomPaint(
                            painter: _WheelPainter(sectors),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_drop_down, size: 36, color: Colors.black),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: _isSpinning
                      ? null
                      : () async {
                          setStateSB(() {
                            _isSpinning = true;
                          });

                          // Ask server for the reward first so we can animate to that sector
                          final resp = await http.post(
                            Uri.parse('http://54.255.150.15/mobile-api/roulette'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'member_code': memberCode}),
                          );

                          final Map data = jsonDecode(resp.body);
                          if (data['success'] != true) {
                            setStateSB(() => _isSpinning = false);
                            return;
                          }

                          final int reward = (data['reward'] as num).toInt();
                          final int newTotal = (data['total_points'] as num).toInt();

                          // Find target sector index. If not found, default to 0.
                          int targetIndex = sectors.indexOf(reward);
                          if (targetIndex < 0) targetIndex = 0;

                          // Compute target turns so wheel decelerates and lands on targetIndex
                          final spins = 6; // full spins before landing
                          final targetTurns = spins + (targetIndex / sectors.length);

                          // Ensure controller can animate to targetTurns by setting an ample upperBound
                          _spinController.duration = const Duration(seconds: 4);
                          _spinController.animateTo(
                            targetTurns,
                            curve: Curves.decelerate,
                          ).whenComplete(() async {
                            // Persist server response locally
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('earned_points', reward);
                            await prefs.setInt('total_points', newTotal);
                            await prefs.setString('last_login_at', DateTime.now().toIso8601String());

                            setState(() {
                              earnedPoints = reward;
                              totalPoints = newTotal;
                              _isSpinning = false;
                            });

                            Navigator.pop(context);
                            showRewardDialog(reward);

                            // reset controller to a small value to allow next spin
                            _spinController.value = targetTurns % 1;
                          });
                        },
                  child: Text(_isSpinning ? 'SPINNING...' : 'SPIN NOW'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showRewardDialog(int reward) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "🎉 Congratulations!",
          ),
          content: Text(
            "You won $reward points!",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 100.0,
      duration: const Duration(seconds: 4),
    );
    loadUser();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    setState(() {
      userName =
          prefs.getString("name") ?? "Member";

      memberCode =
          prefs.getString("member_code") ?? "";

      totalPoints =
          prefs.getInt("total_points") ?? 0;
      earnedPoints =
          prefs.getInt("earned_points") ?? 0;
    });

    final lastLoginStr =
        prefs.getString("last_login_at");

    bool showRoulette = false;

    if (lastLoginStr == null) {
      showRoulette = true;
    } else {
      final lastLoginDate =
          DateTime.parse(lastLoginStr);

      final today = DateTime.now();

      final isSameDay =
          lastLoginDate.year == today.year &&
          lastLoginDate.month == today.month &&
          lastLoginDate.day == today.day;

      showRoulette = !isSameDay;
    }

    print(
      "LAST LOGIN = $lastLoginStr",
    );

    print(
      "SHOW ROULETTE = $showRoulette",
    );

    if (showRoulette && mounted) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          showRoulettePopup();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
    (totalPoints / nextReward)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await loadUser();
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                            24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(.05),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  "Hi, $userName 👋",
                                  style:
                                      GoogleFonts
                                          .poppins(
                                    fontSize: 24,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                                Text(
                                  "Welcome back!",
                                  style:
                                      GoogleFonts
                                          .poppins(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  "Member Code: $memberCode",
                                  style:
                                      GoogleFonts
                                          .poppins(
                                    color:
                                        Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons
                                  .notifications_none,
                            ),
                          ),
                        ],
                      ),
                      if (earnedPoints > 0) ...[
                        const SizedBox(
                            height: 20),
                        Container(
                          padding:
                              const EdgeInsets.all(
                                  20),
                          decoration:
                              BoxDecoration(
                            color: const Color(
                                0xFF6F2DBD),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      "🎉 You earned",
                                      style:
                                          GoogleFonts
                                              .poppins(
                                        color: Colors
                                            .white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 8),
                                    Text(
                                      "+$earnedPoints",
                                      style:
                                          GoogleFonts
                                              .poppins(
                                        color: Colors
                                            .white,
                                        fontSize: 52,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    Text(
                                      "ROULETTE REWARD",
                                      style:
                                          GoogleFonts
                                              .poppins(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 90,
                                height: 90,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Colors.orange,
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .monetization_on,
                                  color:
                                      Colors.white,
                                  size: 50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(
                          height: 20),
                      Row(
                        children: [
                          Text(
                            "Total Points",
                            style:
                                GoogleFonts
                                    .poppins(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons
                                .monetization_on,
                            color:
                                Colors.orange,
                          ),
                          const SizedBox(
                              width: 4),
                          Text(
                            NumberFormat(
                                    '#,###')
                                .format(
                                    totalPoints),
                            style:
                                GoogleFonts
                                    .poppins(
                              color: Colors
                                  .deepOrange,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 34,
                            ),
                          ),
                          Text(
                            " PTS",
                            style:
                                GoogleFonts
                                    .poppins(
                              color: Colors
                                  .deepOrange,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            "$totalPoints / $nextReward PTS",
                            style:
                                GoogleFonts
                                    .poppins(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style:
                                GoogleFonts
                                    .poppins(
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                          height: 15),
                      LinearProgressIndicator(
                        value: progress,
                      ),
                      const SizedBox(
                          height: 12),
                      Text(
                        "${nextReward - totalPoints} PTS to next reward",
                        style:
                            GoogleFonts
                                .poppins(
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

class _WheelPainter extends CustomPainter {
  final List<int> sectors;
  _WheelPainter(this.sectors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    final sweep = 2 * math.pi / sectors.length;
    double start = -math.pi / 2;

    for (var i = 0; i < sectors.length; i++) {
      paint.color = (i % 2 == 0) ? const Color(0xFF6F2DBD) : Colors.orange;
      canvas.drawArc(rect, start, sweep, true, paint);

      // Draw label
      final label = sectors[i].toString();
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr);
      tp.layout();

      final angle = start + sweep / 2;
      final tx = center.dx + (radius * 0.6) * math.cos(angle) - tp.width / 2;
      final ty = center.dy + (radius * 0.6) * math.sin(angle) - tp.height / 2;
      tp.paint(canvas, Offset(tx, ty));

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}