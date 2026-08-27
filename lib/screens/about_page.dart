import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

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

  final String apiUrl =
      "http://54.255.150.15/mobile-api/location";

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    try {
      debugPrint("Loading locations...");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Accept": "application/json",
        },
      );

      debugPrint("Location API status: ${response.statusCode}");
      debugPrint("Location API response: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint(
          "Location API failed with status ${response.statusCode}",
        );
        return;
      }

      final data = jsonDecode(response.body);

      if (data["success"] != true) {
        debugPrint(
          "Location API returned success=false: ${data["message"]}",
        );
        return;
      }

      final locations = data["locations"];

      if (locations is! List) {
        debugPrint("Invalid locations response");
        return;
      }

      final Set<Marker> newMarkers = {};

      for (final item in locations) {
        try {
          final latitude = double.tryParse(
            item["latitude"]?.toString() ?? "",
          );

          final longitude = double.tryParse(
            item["longitude"]?.toString() ?? "",
          );

          // Skip locations without valid coordinates
          if (latitude == null || longitude == null) {
            debugPrint(
              "Skipping location ${item["id"]}: invalid coordinates",
            );
            continue;
          }

          final locationName =
              item["location_name"]?.toString() ?? "WiFi Location";

          final branchName =
              item["branch_name"]?.toString() ?? "";

          final address =
              item["address"]?.toString() ?? "";

          final wifiSsid =
              item["wifi_ssid"]?.toString() ?? "";

          String snippet = address;

          if (branchName.isNotEmpty) {
            snippet = branchName;
          }

          if (address.isNotEmpty) {
            snippet = snippet.isEmpty
                ? address
                : "$snippet • $address";
          }

          if (wifiSsid.isNotEmpty) {
            snippet = snippet.isEmpty
                ? "WiFi: $wifiSsid"
                : "$snippet\nWiFi: $wifiSsid";
          }

          newMarkers.add(
            Marker(
              markerId: MarkerId(
                item["id"].toString(),
              ),
              position: LatLng(
                latitude,
                longitude,
              ),
              infoWindow: InfoWindow(
                title: locationName,
                snippet: snippet,
              ),
            ),
          );
        } catch (e) {
          debugPrint(
            "Error processing location: $e",
          );
        }
      }

      if (mounted) {
        setState(() {
          markers = newMarkers;
        });
      }

      debugPrint(
        "Loaded ${newMarkers.length} locations",
      );
    } catch (e, stackTrace) {
      debugPrint(
        "LOAD LOCATIONS ERROR: $e",
      );
      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/logo1.png',
                  width: 100,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return const Icon(
                      Icons.image,
                      size: 80,
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "Yes Free WiFi is a smart advertising platform "
                "where users earn points by engaging with ads "
                "and redeem them for exciting rewards.\n\n"
                "Boost visibility. Earn rewards. Grow together.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
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
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(16),
                  child: kIsWeb
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.map,
                              size: 64,
                              color: Colors.black26,
                            ),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition:
                              const CameraPosition(
                            target:
                                LatLng(14.5995, 120.9842),
                            zoom: 12,
                          ),
                          markers: markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          onMapCreated:
                              (controller) {
                            mapController =
                                controller;
                          },
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Available Locations (${markers.length})",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              markers.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_off,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No available locations",
                            style:
                                GoogleFonts.poppins(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: markers.length,
                        itemBuilder:
                            (context, index) {
                          final marker =
                              markers.elementAt(index);

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              title: Text(
                                marker.infoWindow.title ??
                                    "",
                                style:
                                    GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                marker.infoWindow.snippet ??
                                    "",
                                style:
                                    GoogleFonts.poppins(
                                  color: Colors.black54,
                                ),
                              ),
                              onTap: () {
                                mapController
                                    ?.animateCamera(
                                  CameraUpdate
                                      .newLatLngZoom(
                                    marker.position,
                                    16,
                                  ),
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
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}