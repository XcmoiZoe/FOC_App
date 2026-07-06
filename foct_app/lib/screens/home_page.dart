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

  final Map<int, bool> expandedRewards = {};
  String userName = "Member";
  String memberCode = "";
  int totalPoints = 0;
  String recentTitle = "No rewards yet";
  String recentDescription = "SPIN TO EARN POINTS";
  int recentPoints = 0;
  int activityCount = 0;
  List<dynamic> rewards = [];

  late AnimationController _spinController;
  bool _isSpinning = false;
  int earnedPoints = 0;
Map<String, dynamic>? getNextReward() {
  if (rewards.isEmpty) return null;

  final sorted = [...rewards];

  sorted.sort(
    (a, b) => (a['points_required'] as int)
        .compareTo(b['points_required'] as int),
  );

  for (final reward in sorted) {
    if (reward['points_required'] > totalPoints) {
      return reward;
    }
  }

  return null;
}
void showRoulettePopup() {
  final sectors = <dynamic>["Try again", 5, 10, 20, 50];

  int selectedIndex = 0;
  bool loading = false;

  int _getTargetIndex(dynamic reward) {
    if (reward == "Try again") return 0;
    final idx = sectors.indexWhere((e) => e.toString() == reward.toString());
    return idx >= 0 ? idx : 0;
  }

  Future<void> _spinAndShowResult(StateSetter setStateSB) async {
    if (_isSpinning) return;

    setStateSB(() {
      loading = true;
      _isSpinning = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setStateSB(() {
          loading = false;
          _isSpinning = false;
        });
        return;
      }

      final resp = await http.post(
        Uri.parse('http://54.255.150.15/mobile-api/roulette'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> data = jsonDecode(resp.body);

      if (data['success'] != true) {
        setStateSB(() {
          loading = false;
          _isSpinning = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Spin failed'),
            ),
          );
        }
        return;
      }

      final dynamic reward = data['reward'];
      final int newTotal = (data['total_points'] as num).toInt();

      selectedIndex = _getTargetIndex(reward);

      final int fullSpins = 6;

final double sectorSize = 1 / sectors.length;

// Pointer is at the top (12 o'clock)
final double targetTurns =
    fullSpins +
    (1 - ((selectedIndex + 0.5) * sectorSize));
      _spinController
  ..duration = const Duration(seconds: 10)
  ..value = 0.0;

await _spinController.animateTo(
  targetTurns,
  curve: Curves.decelerate,
);

      if (!mounted) return;

      setState(() {
        earnedPoints = reward is num ? reward.toInt() : 0;
        totalPoints = newTotal;
        _isSpinning = false;
      });

      Navigator.of(context).pop();

      showRewardDialog(reward);

      await loadUser();
      await loadRecentActivity();
      await loadActivityCount();

      _spinController.value = targetTurns % 1;
    } catch (e) {
      setStateSB(() {
        loading = false;
        _isSpinning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Roulette error: $e'),
          ),
        );
      }
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2E1065)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daily Roulette',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSpinning ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  Text(
                    'Spin to win points or try again',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: AnimatedBuilder(
                          animation: _spinController,
                          builder: (_, __) {
                            return Transform.rotate(
                              angle: _spinController.value * 2 * math.pi,
                              child: CustomPaint(
                                painter: _WheelPainter(sectors),
                                child: const SizedBox(width: 270, height: 270),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_drop_down,
                          size: 34,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _isSpinning
                          ? 'Spinning...'
                          : 'Tap spin to start your daily chance',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isSpinning || loading)
                          ? null
                          : () => _spinAndShowResult(setStateSB),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBBF24),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _isSpinning ? 'SPINNING...' : 'SPIN NOW',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void showRewardDialog(dynamic reward) {
  final isTryAgain = reward.toString() == 'Try again';

  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTryAgain
                  ? [const Color(0xFF374151), const Color(0xFF111827)]
                  : [const Color(0xFF16A34A), const Color(0xFF14532D)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTryAgain ? Icons.refresh : Icons.celebration,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                isTryAgain ? 'Try Again' : 'Congratulations!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTryAgain
                    ? 'No points this time. Come back tomorrow.'
                    : 'You won $reward points!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
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
  loadRewards();
  loadRecentActivity();
  loadActivityCount();
}

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }
Future<void> showActivityHistory() async {
  
  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  if (token == null) return;

await http.post(
  Uri.parse(
    'http://54.255.150.15/mobile-api/read-notifications',
  ),
  headers: {
    'Authorization': 'Bearer $token',
  },
);

setState(() {
  activityCount = 0;
});

  try {
    final response = await http.post(
      Uri.parse(
        'http://54.255.150.15/mobile-api/activity-history',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data =
        jsonDecode(response.body);

    if (data['success'] != true) return;

    final activities =
        data['activities'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding:
              const EdgeInsets.all(20),
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  .75,
          child: Column(
            children: [
              Text(
                "Activity History",
                style:
                    GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                  height: 15),
         Expanded(
  child: activities.isEmpty
      ? const Center(
          child: Text(
            "No activity found",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        )
      : ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final item = activities[index];
            final points = item['points'];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    points >= 0 ? Colors.green : Colors.red,
                child: Icon(
                  points >= 0
                      ? Icons.add
                      : Icons.remove,
                  color: Colors.white,
                ),
              ),
              title: Text(item['title'] ?? ''),
              subtitle: Text(item['description'] ?? ''),
              trailing: Text(
                "${points > 0 ? '+' : ''}$points",
                style: TextStyle(
                  color: points > 0
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
),
            ],
          ),
        );
      },
    );
  } catch (e) {
    debugPrint(
      "History Error: $e",
    );
  }
}
Future<void> loadUser() async {
  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  if (token == null || token.isEmpty) {
    return;
  }

  try {
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

      setState(() {
        userName =
            user['name'] ?? 'Member';
        memberCode =
            user['member_code'] ?? '';
        totalPoints =
            (user['total_points'] ?? 0)
                .toInt();
      });

      final lastRouletteStr =
          user['last_roulette_at']
              ?.toString();

      bool showRoulette = false;

      if (lastRouletteStr == null ||
          lastRouletteStr.isEmpty) {
        showRoulette = true;
      } else {
        final lastRouletteDate =
            DateTime.tryParse(
                lastRouletteStr);

        if (lastRouletteDate == null) {
          showRoulette = true;
        } else {
          final today =
              DateTime.now();

          final isSameDay =
              lastRouletteDate.year ==
                      today.year &&
                  lastRouletteDate.month ==
                      today.month &&
                  lastRouletteDate.day ==
                      today.day;

          showRoulette = !isSameDay;
        }
      }

      debugPrint(
          'LAST ROULETTE = $lastRouletteStr');
      debugPrint(
          'SHOW ROULETTE = $showRoulette');

      if (showRoulette && mounted) {
        await Future.delayed(
          const Duration(
              milliseconds: 500),
        );

        if (mounted) {
          showRoulettePopup();
        }
      }
    }
  } catch (e) {
    debugPrint(
      'Profile Load Error: $e',
    );
  }
}
Future<void> loadRewards() async {
  try {
    final response = await http.get(
      Uri.parse(
        'http://54.255.150.15/mobile-api/rewards',
      ),
    );

    final data =
        jsonDecode(response.body);

    if (data['success'] == true) {
      setState(() {
        rewards = data['rewards'];
      });
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}List<dynamic> getSuggestedRewards() {
  final sorted = [...rewards];

  sorted.sort(
    (a, b) => (a['points_required'] as int)
        .compareTo(b['points_required'] as int),
  );

  // Rewards user can afford
  final affordable = sorted.where(
    (r) => totalPoints >= r['points_required'],
  ).toList();

  // Rewards above current points
  final upcoming = sorted.where(
    (r) => totalPoints < r['points_required'],
  ).toList();

  final result = <dynamic>[];

  // Last reward user can afford
  if (affordable.isNotEmpty) {
    result.add(affordable.last);
  }

  // Next rewards
  result.addAll(upcoming.take(2));

  return result.take(3).toList();
}
Future<void> loadActivityCount() async {
  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  if (token == null || token.isEmpty) {
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(
        'http://54.255.150.15/mobile-api/activity-count',
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
      setState(() {
        activityCount =
            data['total'] ?? 0;
      });
    }

    print(
      'ACTIVITY COUNT = $activityCount',
    );
  } catch (e) {
    debugPrint(
      'Activity Count Error: $e',
    );
  }
}
Future<void> loadRecentActivity() async {
  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  if (token == null) return;

  try {
    final response = await http.post(
      Uri.parse(
        'http://54.255.150.15/mobile-api/activity',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data =
        jsonDecode(response.body);

    debugPrint(
        "ACTIVITY RESPONSE: ${response.body}");

  if (data['success'] == true &&
    data['activity'] != null) {

  final activity =
      data['activity'];

  setState(() {
    recentTitle =
        activity['title'] ?? '';

    recentDescription =
        activity['description'] ?? '';

    recentPoints =
        activity['points'] ?? 0;

    
  });
}
  } catch (e) {
    debugPrint(
      "ACTIVITY ERROR: $e",
    );
  }
}
Future<void> redeemReward(int rewardId) async {
  final prefs =
      await SharedPreferences.getInstance();

  final token =
      prefs.getString('token');

  if (token == null) return;

  try {
    final response = await http.post(
      Uri.parse(
        'http://54.255.150.15/mobile-api/redeem',
      ),
      headers: {
        'Authorization':
            'Bearer $token',
        'Content-Type':
            'application/json',
      },
      body: jsonEncode({
        'reward_id': rewardId,
      }),
    );

    final data =
        jsonDecode(response.body);

    if (data['success'] == true) {
      await loadUser();
      await loadRecentActivity();
      await loadActivityCount();
      showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text("🎉 Redeemed"),
    content: Text(
      "${data['reward']['title']} redeemed successfully!"
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text("OK"),
      ),
    ],
  ),
);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(data['message']),
        ),
      );
    }
  } catch (e) {
    debugPrint(
      'Redeem Error: $e',
    );
  }
}
  @override
  Widget build(BuildContext context) {
   final nextReward = getNextReward();

final int goal =
    nextReward == null
        ? totalPoints
        : nextReward['points_required'];

final double progress =
    goal == 0
        ? 1.0
        : (totalPoints / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
         onRefresh: () async {
  await loadUser();
  await loadRewards();
  await loadRecentActivity();
  await loadActivityCount();
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
                                        Stack(
  children: [
    IconButton(
      onPressed: () {
        showActivityHistory();
      },
      icon: const Icon(
  Icons.notifications_none,
  color: Color(0xFF6F2DBD),
),
    ),

    Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          activityCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
)
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F2DBD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Recent Activity",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                 Text(
                                  recentPoints == 0
                                      ? recentTitle
                                      : "${recentPoints > 0 ? '+' : ''}$recentPoints",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: recentPoints == 0 ? 24 : 52,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                               Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      recentTitle,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    Text(
      recentDescription,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 12,
      ),
    ),
  ],
),
                                ],
                              ),
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            "${NumberFormat('#,###').format(totalPoints)} / ${NumberFormat('#,###').format(goal)} PTS",
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
                     Builder(
  builder: (_) {
    final availableRewards = rewards
        .where((r) => totalPoints >= r['points_required'])
        .toList();

    if (availableRewards.isEmpty) {
      final next = rewards
          .where((r) => r['points_required'] > totalPoints)
          .toList();

      if (next.isEmpty) {
        return const SizedBox();
      }

      next.sort((a, b) => (a['points_required'] as int)
          .compareTo(b['points_required'] as int));

      final nextReward = next.first;

      return Text(
        "${nextReward['points_required'] - totalPoints} PTS to unlock ${nextReward['title']}",
        style: GoogleFonts.poppins(
          color: Colors.grey,
        ),
      );
    }

    availableRewards.sort((a, b) =>
        (b['points_required'] as int)
            .compareTo(a['points_required'] as int));

    return Column(
      children: [
        Text(
          "🎉 Ready to Redeem",
          style: GoogleFonts.poppins(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          availableRewards
              .take(3)
              .map((e) => e['title'])
              .join(", "),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ],
    );
  },
),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Rewards You Can Redeem",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 15),

     if (getSuggestedRewards().isEmpty)
  const Center(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        "No rewards available yet",
      ),
    ),
  ),


...getSuggestedRewards().map((reward) {
  final bool canRedeem =
      totalPoints >= reward['points_required'];

  return Card(
    elevation: 0,
    color: Colors.transparent,
    margin: const EdgeInsets.only(bottom: 15),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(12),
                          child: Image.network(
                            reward['image_url'] ?? '',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    Container(
                              width: 90,
                              height: 90,
                              color:
                                  Colors.grey.shade200,
                              child: const Icon(
                                Icons.image,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward['title'],
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                  height: 6),

                              Text(
                                reward['description'],
                                maxLines:
                                    expandedRewards[
                                                reward[
                                                    'id']] ==
                                            true
                                        ? null
                                        : 2,
                                overflow:
                                    expandedRewards[
                                                reward[
                                                    'id']] ==
                                            true
                                        ? TextOverflow
                                            .visible
                                        : TextOverflow
                                            .ellipsis,
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(
                                  height: 6),

                              InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedRewards[
                                            reward['id']] =
                                        !(expandedRewards[
                                                reward[
                                                    'id']] ??
                                            false);
                                  });
                                },
                                child: Text(
                                  expandedRewards[
                                              reward[
                                                  'id']] ==
                                          true
                                      ? "Read Less"
                                      : "Read More",
                                  style:
                                      GoogleFonts.poppins(
                                    color:
                                        const Color(
                                            0xFF6F2DBD),
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canRedeem
                            ? () => redeemReward(
                                reward['id'])
                            : null,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              canRedeem
                                  ? const Color(
                                      0xFF6F2DBD)
                                  : Colors
                                      .grey.shade300,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(30),
                          ),
                        ),
                        child: Text(
                          canRedeem
                              ? "REDEEM"
                              : "+${reward['points_required'] - totalPoints}",
                          style:
                              GoogleFonts.poppins(
                            color: canRedeem
                                ? Colors.yellow
                                : Colors.black54,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: Image.network(
                        reward['image_url'] ?? '',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                Container(
                          width: 90,
                          height: 90,
                          color:
                              Colors.grey.shade200,
                          child: const Icon(
                            Icons.image,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            reward['title'],
                            style:
                                GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            reward['description'],
                            maxLines:
                                expandedRewards[
                                            reward[
                                                'id']] ==
                                        true
                                    ? null
                                    : 2,
                            overflow:
                                expandedRewards[
                                            reward[
                                                'id']] ==
                                        true
                                    ? TextOverflow
                                        .visible
                                    : TextOverflow
                                        .ellipsis,
                            style:
                                GoogleFonts.poppins(
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 6),

                          InkWell(
                            onTap: () {
                              setState(() {
                                expandedRewards[
                                        reward['id']] =
                                    !(expandedRewards[
                                            reward[
                                                'id']] ??
                                        false);
                              });
                            },
                            child: Text(
                              expandedRewards[
                                          reward[
                                              'id']] ==
                                      true
                                  ? "Read Less"
                                  : "Read More",
                              style:
                                  GoogleFonts.poppins(
                                color:
                                    const Color(
                                        0xFF6F2DBD),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    SizedBox(
                      width: 140,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canRedeem
                            ? () => redeemReward(
                                reward['id'])
                            : null,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              canRedeem
                                  ? const Color(
                                      0xFF6F2DBD)
                                  : Colors
                                      .grey.shade300,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(30),
                          ),
                        ),
                        child: Text(
                          canRedeem
                              ? "REDEEM"
                              : "+${reward['points_required'] - totalPoints}",
                          style:
                              GoogleFonts.poppins(
                            color: canRedeem
                                ? Colors.yellow
                                : Colors.black54,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    ),
  );
}).toList(),
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
  final List<dynamic> sectors;

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
