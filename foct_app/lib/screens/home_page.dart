import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../screens/about_page.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

String formatActivityClaimDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

bool canClaimActivity(String? lastClaimDate, DateTime now) {
  if (lastClaimDate == null || lastClaimDate.isEmpty) {
    return true;
  }

  return lastClaimDate != formatActivityClaimDate(now);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final Map<int, bool> expandedRewards = {};
  String userName = "Member";
  String memberCode = "";
  int totalPoints = 0;
  String recentTitle = "No rewards yet";
  String recentDescription = "SPIN TO EARN POINTS";
  int recentPoints = 0;
  int activityCount = 0;
  List<dynamic> rewards = [];

  // Hotspot map
  GoogleMapController? hotspotMapController;
  Set<Marker> hotspotMarkers = {};
  final String hotspotApiUrl = "http://54.255.150.15/mobile-api/location";

  late AnimationController _spinController;
  bool _isSpinning = false;
  int earnedPoints = 0;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: const Duration(seconds: 4),
    );

    loadUser();
    loadRewards();
    loadRecentActivity();
    loadActivityCount();
    loadHotspotLocations();
  }

  Future<void> loadHotspotLocations() async {
    try {
      final response = await http.get(Uri.parse(hotspotApiUrl));
      final data = jsonDecode(response.body);

      if (data["success"] == true && data["locations"] != null) {
        final Set<Marker> newMarkers = {};

        for (final item in data["locations"]) {
          final lat = double.tryParse(item["latitude"].toString()) ?? 0.0;
          final lng = double.tryParse(item["longitude"].toString()) ?? 0.0;
          newMarkers.add(Marker(
            markerId: MarkerId(item["id"].toString()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: item["location_name"]?.toString() ?? '', snippet: item["address"]?.toString() ?? ''),
          ));
        }

        if (mounted) {
          setState(() {
            hotspotMarkers = newMarkers;
          });
        }
      }
    } catch (e) {
      debugPrint('Hotspot load error: $e');
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? getNextReward() {
    if (rewards.isEmpty) return null;

    final sorted = [...rewards];
    sorted.sort((a, b) => (a['points_required'] as int).compareTo(b['points_required'] as int));

    for (final reward in sorted) {
      if (reward['points_required'] > totalPoints) return reward as Map<String, dynamic>;
    }
    return null;
  }

  void showRoulettePopup() {
    final sectors = <dynamic>["Try again", 5, 10, 20, 50];

    int selectedIndex = 0;
    bool loading = false;

    int getTargetIndex(dynamic reward) {
      if (reward == "Try again") return 0;
      final idx = sectors.indexWhere((e) => e.toString() == reward.toString());
      return idx >= 0 ? idx : 0;
    }

    Future<void> spinAndShowResult(StateSetter setStateSB) async {
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Spin failed')));
          }
          return;
        }

        final dynamic reward = data['reward'];
        final int newTotal = (data['total_points'] as num).toInt();

        selectedIndex = getTargetIndex(reward);

        final int fullSpins = 6;
        final double sectorSize = 1 / sectors.length;

        // Pointer is at the top (12 o'clock)
        final double targetTurns = fullSpins + (1 - ((selectedIndex + 0.5) * sectorSize));

        _spinController
          ..duration = const Duration(milliseconds: 1800)
          ..value = 0.0;

        await _spinController.animateTo(targetTurns % 1, curve: Curves.decelerate);

        if (!mounted) return;

        setState(() {
          earnedPoints = reward is num ? reward.toInt() : 0;
          totalPoints = newTotal;
          _isSpinning = false;
        });

        Navigator.of(context).pop();

        showRewardDialog(reward);

       loadUser();
       loadRecentActivity();
       loadActivityCount();
      } catch (e) {
        setStateSB(() {
          loading = false;
          _isSpinning = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Roulette error: $e')));
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setStateSB) {
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
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Daily Roulette', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: _isSpinning ? null : () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                ]),
                const SizedBox(height: 8),
                Text('Spin to win points or try again', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 18),
                Stack(alignment: Alignment.topCenter, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, __) {
                        return Transform.rotate(angle: _spinController.value * 2 * math.pi, child: CustomPaint(painter: _WheelPainter(sectors), child: const SizedBox(width: 270, height: 270)));
                      },
                    ),
                  ),
                  Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: const Icon(Icons.arrow_drop_down, size: 34, color: Colors.black)),
                ]),
                const SizedBox(height: 18),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)), child: Text(_isSpinning ? 'Spinning...' : 'Tap spin to start your daily chance', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSpinning) ? null : () => spinAndShowResult(setStateSB),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 6),
                    child: _isSpinning
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                        : Text('SPIN NOW', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ]),
            ),
          );
        });
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: isTryAgain ? [const Color(0xFF374151), const Color(0xFF111827)] : [const Color(0xFF16A34A), const Color(0xFF14532D)])),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(isTryAgain ? Icons.refresh : Icons.celebration, color: Colors.white, size: 56),
              const SizedBox(height: 12),
              Text(isTryAgain ? 'Try Again' : 'Congratulations!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(isTryAgain ? 'No points this time. Come back tomorrow.' : 'You won $reward points!', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('OK')),
            ]),
          ),
        );
      },
    );
  }

  Future<void> showActivityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    await http.post(Uri.parse('http://54.255.150.15/mobile-api/read-notifications'), headers: {'Authorization': 'Bearer $token'});

    setState(() {
      activityCount = 0;
    });

    try {
      final response = await http.post(Uri.parse('http://54.255.150.15/mobile-api/activity-history'), headers: {'Authorization': 'Bearer $token'});
      final data = jsonDecode(response.body);
      if (data['success'] != true) return;
      final activities = data['activities'] as List<dynamic>;

      showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
        return Container(padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * .75, child: Column(children: [
          Text("Activity History", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: activities.isEmpty
                ? const Center(child: Text("No activity found", style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(itemCount: activities.length, itemBuilder: (context, index) {
                    final item = activities[index];
                    final points = item['points'] as int? ?? 0;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: points >= 0 ? Colors.green : Colors.red, child: Icon(points >= 0 ? Icons.add : Icons.remove, color: Colors.white)),
                      title: Text(item['title'] ?? ''),
                      subtitle: Text(item['description'] ?? ''),
                      trailing: Text("${points > 0 ? '+' : ''}$points", style: TextStyle(color: points > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    );
                  }),
          ),
        ]));
      });
    } catch (e) {
      debugPrint("History Error: $e");
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.post(Uri.parse('http://54.255.150.15/mobile-api/profile'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final user = data['user'];
        setState(() {
          userName = user['name'] ?? 'Member';
          memberCode = user['member_code'] ?? '';
          totalPoints = (user['total_points'] ?? 0).toInt();
        });

        final lastRouletteStr = user['last_roulette_at']?.toString();
        bool showRoulette = false;
        if (lastRouletteStr == null || lastRouletteStr.isEmpty) {
          showRoulette = true;
        } else {
          final lastRouletteDate = DateTime.tryParse(lastRouletteStr);
          if (lastRouletteDate == null) {
            showRoulette = true;
          } else {
            final today = DateTime.now();
            final isSameDay = lastRouletteDate.year == today.year && lastRouletteDate.month == today.month && lastRouletteDate.day == today.day;
            showRoulette = !isSameDay;
          }
        }

        if (showRoulette && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) showRoulettePopup();
        }
      }
    } catch (e) {
      debugPrint('Profile Load Error: $e');
    }
  }

  Future<void> loadRewards() async {
    try {
      final response = await http.get(Uri.parse('http://54.255.150.15/mobile-api/rewards'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          rewards = data['rewards'];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  List<dynamic> getSuggestedRewards() {
    final sorted = [...rewards];
    sorted.sort((a, b) => (a['points_required'] as int).compareTo(b['points_required'] as int));

    final affordable = sorted.where((r) => totalPoints >= r['points_required']).toList();
    final upcoming = sorted.where((r) => totalPoints < r['points_required']).toList();

    final result = <dynamic>[];
    if (affordable.isNotEmpty) result.add(affordable.last);
    result.addAll(upcoming.take(2));
    return result.take(3).toList();
  }

  Future<void> loadActivityCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.post(Uri.parse('http://54.255.150.15/mobile-api/activity-count'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          activityCount = data['total'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Activity Count Error: $e');
    }
  }

  Future<void> loadRecentActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.post(Uri.parse('http://54.255.150.15/mobile-api/activity'), headers: {'Authorization': 'Bearer $token'});
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['activity'] != null) {
        final activity = data['activity'];
        setState(() {
          recentTitle = activity['title'] ?? '';
          recentDescription = activity['description'] ?? '';
          recentPoints = activity['points'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('ACTIVITY ERROR: $e');
    }
  }

  Future<void> redeemReward(int rewardId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.post(Uri.parse('http://54.255.150.15/mobile-api/redeem'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'reward_id': rewardId}));
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        await loadUser();
        await loadRecentActivity();
        await loadActivityCount();
        showDialog(context: context, builder: (_) => AlertDialog(title: const Text("🎉 Redeemed"), content: Text("${data['reward']['title']} redeemed successfully!"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      debugPrint('Redeem Error: $e');
    }
  }

  Future<bool> _canClaimActivityToday(String activityKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimDate = prefs.getString(activityKey);
    return canClaimActivity(lastClaimDate, DateTime.now());
  }

  Future<void> _markActivityClaimed(String activityKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activityKey, formatActivityClaimDate(DateTime.now()));
  }

  Future<void> dailyLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    if (!await _canClaimActivityToday('daily_login')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily login already claimed today.')));
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://54.255.150.15/mobile-api/daily-login'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Daily login processed')));
      }

      if (data['success'] == true) {
        await _markActivityClaimed('daily_login');
        await loadUser();
        await loadRecentActivity();
        await loadActivityCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Daily login failed: $e')));
      }
    }
  }

  Future<void> watchVideo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    if (!await _canClaimActivityToday('watch_video')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video reward already claimed today.')));
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://54.255.150.15/mobile-api/watch-video'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Video reward processed')));
      }

      if (data['success'] == true) {
        await _markActivityClaimed('watch_video');
        await loadUser();
        await loadRecentActivity();
        await loadActivityCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video reward failed: $e')));
      }
    }
  }

  Future<void> inviteFriend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    if (!await _canClaimActivityToday('invite_friend')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite reward already claimed today.')));
      }
      return;
    }

    final shareLink = 'https://yesfreewifi.com/register?ref=$memberCode';

    try {
      final response = await http.post(
        Uri.parse('http://54.255.150.15/mobile-api/invite-friend'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'referral_code': memberCode}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invitation sent')));
      }

      if (data['success'] == true) {
        await SharePlus.instance.share(
          ShareParams(text: 'Join YES Free WiFi!\n$shareLink'),
        );
        await _markActivityClaimed('invite_friend');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invitation failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF200F46),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await loadUser();
            await loadRewards();
            await loadRecentActivity();
            await loadActivityCount();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Top Bar: logo left, notification with badge right
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo1.png', width: 90),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
                          onPressed: showActivityHistory,
                        ),
                        if (activityCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Center(
                                child: Text(activityCount > 99 ? '99+' : '$activityCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Header Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 220,
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  // Left content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('My Points', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(NumberFormat('#,###').format(totalPoints), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)),
                      const SizedBox(height: 4),
                      const Text('PTS', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 140,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: showActivityHistory,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text('View History'),
                        ),
                      ),
                    ]),
                  ),

                  // Robot overlapping right
                  Positioned(
                    right: -10,
                    bottom: -15,
                    child: Image.asset('assets/robot.png', width: 150),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Activities
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFF2A125A), borderRadius: BorderRadius.circular(24)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Daily Activities', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _activityTile(
                        icon: Icons.calendar_today,
                        label: 'Daily Login',
                        points: '+10 pts',
                        onTap: dailyLogin,
                      ),
                      _activityTile(
                        icon: Icons.play_circle_fill,
                        label: 'Watch Video',
                        points: '+20 pts',
                        onTap: watchVideo,
                      ),
                      _activityTile(
                        icon: Icons.autorenew,
                        label: 'Lucky Spin',
                        points: '+30 pts',
                        onTap: showRoulettePopup,
                      ),
                      _activityTile(
                        icon: Icons.group_add,
                        label: 'Invite Friend',
                        points: '+50 pts',
                        onTap: inviteFriend,
                      ),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Redeem CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF4A2490), borderRadius: BorderRadius.circular(24)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Redeem your points for exciting rewards!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    SizedBox(height: 52, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/redeem'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Redeem Now', style: GoogleFonts.poppins(color: const Color(0xFF4C1D95), fontWeight: FontWeight.bold)))),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Hotspots
                  // Map preview section (shows small map and opens About/Map)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Align(alignment: Alignment.centerLeft, child: Text('Find WiFi Hotspots', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black26, offset: Offset(0,1), blurRadius: 3)]))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF2A125A)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(children: [
                          // live Google Map preview (disabled on web)
                          Positioned.fill(
                            child: kIsWeb
                                ? Container(
                                    color: const Color(0xFF2A125A),
                                    child: const Center(
                                      child: Icon(Icons.map, color: Colors.white70, size: 48),
                                    ),
                                  )
                                : GoogleMap(
                                    initialCameraPosition: const CameraPosition(target: LatLng(12.8797, 121.7740), zoom: 5.5),
                                    markers: hotspotMarkers,
                                    myLocationEnabled: false,
                                    zoomControlsEnabled: false,
                                    onMapCreated: (controller) {
                                      hotspotMapController = controller;
                                    },
                                  ),
                          ),
                          // center label
                          Center(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text('Philippines', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Open Map'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Tap the map to open the full hotspot map', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ]),
              ),

              const SizedBox(height: 24),

              // Suggested rewards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Rewards You Can Redeem', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  if (getSuggestedRewards().isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No rewards available yet'))),
                  ...getSuggestedRewards().map((reward) {
                    final bool canRedeem = totalPoints >= reward['points_required'];
                    return Card(
                      elevation: 0,
                      color: Colors.transparent,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF8F2FF), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(reward['image_url'] ?? '', width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.image)))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(reward['title'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2A125A))),
                            const SizedBox(height: 6),
                            Text(reward['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF2A125A))),
                          ])),
                          const SizedBox(width: 12),
                          SizedBox(width: 110, height: 44, child: ElevatedButton(onPressed: canRedeem ? () => redeemReward(reward['id']) : null, style: ElevatedButton.styleFrom(backgroundColor: canRedeem ? const Color(0xFF6F2DBD) : Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 3), child: Text(canRedeem ? 'REDEEM' : '+${reward['points_required'] - totalPoints}', style: GoogleFonts.poppins(color: canRedeem ? Colors.white : const Color(0xFF4C1D95), fontWeight: FontWeight.bold)))),
                        ]),
                      ),
                    );
                  }).toList(),
                ]),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}

Widget _activityTile({
  required IconData icon,
  required String label,
  required String points,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF381B75), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, color: const Color(0xFFFFD54F), size: 28), const SizedBox(height: 10), Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)), const SizedBox(height: 8), Text(points, style: GoogleFonts.poppins(color: const Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    ),
  );
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

      final label = sectors[i].toString();
      final textSpan = TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
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
