import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6A1B9A);
    const accentOrange = Color(0xFFFF8F00);

    // 📍 SAMPLE MARKERS
    final Set<Marker> markers = {
      const Marker(
        markerId: MarkerId('1'),
        position: LatLng(14.5995, 120.9842),
        infoWindow: InfoWindow(title: 'Quiapo WiFi Ads'),
      ),
      const Marker(
        markerId: MarkerId('2'),
        position: LatLng(14.6091, 121.0223),
        infoWindow: InfoWindow(title: 'QC WiFi Ads'),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: primaryPurple,
      ),
      backgroundColor: const Color(0xFFF8F5FC),

      // 🔥 IMPORTANT: use scroll instead of Center
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // 🔥 LOGO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: accentOrange.withOpacity(0.4),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, size: 80);
                  },
                ),
              ),

              const SizedBox(height: 25),

              // 🎯 APP NAME
              const Text(
                "Yes Ads Rewards",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),

              const SizedBox(height: 10),

              // 💡 DESCRIPTION
              const Text(
                "Yes Ads Rewards is a smart advertising platform where users earn points by engaging with ads and redeem them for exciting rewards.\n\nBoost visibility. Earn rewards. Grow together.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              // 🗺️ MAP TITLE
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "WiFi Ad Locations",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🗺️ MAP
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(14.5995, 120.9842),
                      zoom: 12,
                    ),
                    markers: markers,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔥 VERSION
              const Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 