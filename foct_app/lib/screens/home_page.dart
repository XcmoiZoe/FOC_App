import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final int totalPoints = 2475;
    final int loginPoints = 25;
    final int nextReward = 5000;
    final double progress = totalPoints / nextReward;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(
              const Duration(seconds: 1),
            );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi, Emman! 👋",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "Welcome back!",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Stack(
                            children: [

                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.notifications_none,
                                  size: 28,
                                ),
                              ),

                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// LOGIN REWARD CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F2DBD),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    "🎉 You earned",
                                    style:
                                        GoogleFonts.poppins(
                                      color:
                                          Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    "+$loginPoints",
                                    style:
                                        GoogleFonts.poppins(
                                      color:
                                          Colors.white,
                                      fontSize: 52,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    "LOGIN POINTS",
                                    style:
                                        GoogleFonts.poppins(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 90,
                              height: 90,
                              decoration:
                                  BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons
                                    .monetization_on,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Text(
                            "Total Points",
                            style:
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          const Icon(
                            Icons.monetization_on,
                            color: Colors.orange,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            NumberFormat('#,###')
                                .format(
                              totalPoints,
                            ),
                            style:
                                GoogleFonts.poppins(
                              color:
                                  Colors.deepOrange,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 34,
                            ),
                          ),

                          Text(
                            " PTS",
                            style:
                                GoogleFonts.poppins(
                              color:
                                  Colors.deepOrange,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// PROGRESS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(.04),
                        blurRadius: 10,
                      ),
                    ],
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
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style:
                                GoogleFonts.poppins(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 12,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                                  30),
                          child:
                              LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.grey.shade300,
                            valueColor:
                                const AlwaysStoppedAnimation(
                              Color(0xFF6F2DBD),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "${nextReward - totalPoints} PTS to next reward",
                        style:
                            GoogleFonts.poppins(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// REWARDS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      Row(
                        children: [

                          Expanded(
                            child: Text(
                              "Rewards You Can Redeem",
                              style:
                                  GoogleFonts.poppins(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "View All",
                            ),
                          ),
                        ],
                      ),

                      rewardTile(
                        Icons.local_cafe,
                        Colors.green,
                        "Free Coffee",
                        "1,000 PTS",
                      ),

                      rewardTile(
                        Icons.phone_android,
                        Colors.deepPurple,
                        "Mobile Load ₱50",
                        "2,500 PTS",
                      ),

                      rewardTile(
                        Icons.phone_android,
                        Colors.deepPurple,
                        "Mobile Load ₱100",
                        "5,000 PTS",
                      ),

                      rewardTile(
                        Icons.shopping_bag,
                        Colors.orange,
                        "Shopping Voucher ₱200",
                        "10,000 PTS",
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

  Widget rewardTile(
    IconData icon,
    Color color,
    String title,
    String points,
  ) {
    return InkWell(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [

            Icon(
              icon,
              color: color,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),

            Text(
              points,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

