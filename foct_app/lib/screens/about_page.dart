import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const Color primaryPurple = Color(0xFF6A1B9A);
  static const Color accentOrange = Color(0xFFFF8F00);

  GoogleMapController? mapController;
  Set<Marker> markers = {};

  final String apiUrl = "http://54.255.150.15/mobile-api/location";

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        final Set<Marker> newMarkers = {};

        for (final item in data["locations"]) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(item["id"].toString()),
              position: LatLng(
                double.parse(item["latitude"].toString()),
                double.parse(item["longitude"].toString()),
              ),
              infoWindow: InfoWindow(
                title: item["location_name"]?.toString() ?? "",
                snippet: item["address"]?.toString() ?? "",
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            markers = newMarkers;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: primaryPurple,
      ),
      backgroundColor: const Color(0xFFF8F5FC),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
              const Text(
                "Yes Ads Rewards",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Yes Ads Rewards is a smart advertising platform where users earn points by engaging with ads and redeem them for exciting rewards.\n\nBoost visibility. Earn rewards. Grow together.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
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
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Available Locations",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: markers.length,
                  itemBuilder: (context, index) {
                    final marker = markers.elementAt(index);

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        title: Text(marker.infoWindow.title ?? ""),
                        subtitle: Text(marker.infoWindow.snippet ?? ""),
                        onTap: () {
                          mapController?.animateCamera(
                            CameraUpdate.newLatLng(marker.position),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
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