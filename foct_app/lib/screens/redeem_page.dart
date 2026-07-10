import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RedeemPage extends StatefulWidget {
  final String memberCode;

  const RedeemPage({
    super.key,
    required this.memberCode,
  });

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  static const String baseUrl = 'http://54.255.150.15/mobile-api';
  // use centralized theme colors

  final TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';

  late Future<RewardResponse> rewardsFuture;
  List<Reward> allRewards = [];
  List<Reward> filteredRewards = [];
  List<String> categories = const ['All'];
  String searchText = '';
  int remainingPoints = 0;
  bool isRedeeming = false;

  @override
  void initState() {
    super.initState();
    rewardsFuture = fetchRewards();
    searchController.addListener(() {
      searchText = searchController.text;
      filterRewards();
    });
    fetchProfilePoints();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  int _parsePoints(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? remainingPoints;
    if (value is Map<String, dynamic>) {
      final inner = value['remaining_points'] ??
          value['remainingPoints'] ??
          value['total_points'] ??
          value['points'];
      return _parsePoints(inner);
    }
    return remainingPoints;
  }

  Future<void> fetchProfilePoints() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) return;

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['success'] == true && data['user'] != null) {
      final points = _parsePoints(data['user']['total_points']);
      if (mounted) {
        setState(() {
          remainingPoints = points;
        });
      }
    }
  }

  Future<RewardResponse> fetchRewards() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rewards?member_code=${widget.memberCode}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load rewards');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'API returned failure');
    }

    final rewardsJson = (data['rewards'] as List? ?? []);
    final rewards = rewardsJson.map((item) => Reward.fromJson(item)).toList();

    final apiCategories =
        (data['categories'] as List?)?.map((e) => e.toString()).toList() ??
            const ['All'];

    allRewards = rewards;
    categories = apiCategories.isEmpty ? const ['All'] : apiCategories;

    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'All';
    }

    filteredRewards = List.from(allRewards);
    return RewardResponse(rewards: rewards, categories: categories);
  }

  void filterRewards() {
    final query = searchText.toLowerCase().trim();

    setState(() {
      filteredRewards = allRewards.where((reward) {
        final matchesSearch = reward.title.toLowerCase().contains(query) ||
            reward.description.toLowerCase().contains(query);
        final matchesCategory =
            selectedCategory == 'All' || reward.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> redeemReward(Reward reward) async {
    if (isRedeeming) return;

    setState(() => isRedeeming = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: jsonEncode({
          'member_code': widget.memberCode,
          'reward_id': reward.id,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedPoints = _parsePoints(data['total_points']);

        setState(() {
          remainingPoints = updatedPoints;
          rewardsFuture = fetchRewards();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Reward redeemed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        await fetchProfilePoints();
        await rewardsFuture;

        if (mounted) filterRewards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to redeem reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redeem failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isRedeeming = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem Rewards', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<RewardResponse>(
        future: rewardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final displayPoints = remainingPoints;

          return RefreshIndicator(
            onRefresh: () async {
              await fetchProfilePoints();
              setState(() {
                rewardsFuture = fetchRewards();
              });
              await rewardsFuture;
              filterRewards();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search rewards...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (_) {
                              setState(() => selectedCategory = category);
                              filterRewards();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentAmber],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You have',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$displayPoints Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredRewards.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No rewards available')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reward = filteredRewards[index];
                          return RewardCard(
                            reward: reward,
                            currentPoints: displayPoints,
                            onRedeem: () => redeemReward(reward),
                          );
                        },
                        childCount: filteredRewards.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RewardResponse {
  final List<Reward> rewards;
  final List<String> categories;

  RewardResponse({required this.rewards, required this.categories});
}

class Reward {
  final int id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final int pointsRequired;
  final int stock;

  Reward({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.pointsRequired,
    required this.stock,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? 'All',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      pointsRequired: json['points_required'] ?? 0,
      stock: json['stock'] ?? 0,
    );
  }
}

class RewardCard extends StatelessWidget {
  final Reward reward;
  final int currentPoints;
  final VoidCallback onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    required this.currentPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final canRedeem = currentPoints >= reward.pointsRequired && reward.stock > 0;

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: reward.imageUrl.isNotEmpty
                      ? Image.network(
                          reward.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.card_giftcard, size: 36),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reward.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '⭐ ${reward.pointsRequired} pts',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Stock: ${reward.stock}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
                child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRedeem ? AppTheme.accentAmber : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: canRedeem ? onRedeem : null,
                child: const Text('Redeem'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}