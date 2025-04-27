import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:medi_1/api_services/api_services.dart';
import 'package:medi_1/helper/Helper.dart';
import 'package:medi_1/models/hospital_places.dart';
import 'package:medi_1/screens/route_map_screen.dart';

import '../Constants/Constants.dart';

class HospitalSearchScreen extends StatefulWidget {
  const HospitalSearchScreen({super.key});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  List<HospitalPlace> hospitals = [];
  bool isLoading = false;
  TextEditingController searchPlaceController = TextEditingController();
  final AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  double startLat = 0.0;
  double startLng = 0.0;

  Future<void> fetchHospitalsByCoordinates(double lat, double lng) async {
    setState(() => isLoading = true);
    hospitals = await ApiServices.fetchNearbyHospitals(
      latitude: lat,
      longitude: lng,
    );

    // Step 1: Parallel geocoding for hospitals missing coordinates
    final geocodeFutures =
        hospitals.map((hospital) async {
          if (hospital.lat == null || hospital.lng == null) {
            try {
              final geoResult = await ApiServices.fetchCoordinatesFromAddress(
                hospital.address,
              );
              if (geoResult != null) {
                hospital.lat = geoResult.latitude;
                hospital.lng = geoResult.longitude;
              }
            } catch (e) {
              print("Geocoding error for ${hospital.address}: $e");
            }
          }
        }).toList();

    await Future.wait(geocodeFutures);

    // Step 2: Parallel route fetching
    final routeFutures =
        hospitals.map((hospital) async {
          if (hospital.lat != null && hospital.lng != null) {
            final LatLng hospitalLatLng = LatLng(hospital.lat!, hospital.lng!);
            final route = await ApiServices.fetchRoute(
              origin: LatLng(startLat, startLng),
              destination: hospitalLatLng,
            );

            if (route != null) {
              hospital.distance =
                  "${(route.distanceMeters / 1000).toStringAsFixed(2)} km";
              hospital.duration = Helper.formatDuration(route.duration);
            } else {
              print("Route not found for hospital: ${hospital.name}");
            }
          }
        }).toList();

    await Future.wait(routeFutures);

    setState(() => isLoading = false);
  }

  Future<void> searchByLocationName() async {
    String location = searchPlaceController.text.trim();
    if (location.isEmpty) return;

    try {
      List<geo.Location> locations = await geo.locationFromAddress(location);

      if (locations.isNotEmpty) {
        startLat = locations.first.latitude;
        startLng = locations.first.longitude;

        await fetchHospitalsByCoordinates(startLat, startLng);
      }
    } catch (e) {
      print("Geocoding error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to find that location.")),
      );
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location service is disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      startLat = position.latitude;
      startLng = position.longitude;
      await fetchHospitalsByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      print("Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get current location.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Find Nearby Hospitals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _buildLocationField(
              _formKey,
              searchPlaceController,
              "Search location...",
              "Enter a location",
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_vert, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  "OR",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Use Current Location"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text("Finding best hospitals near you..."),
            ] else if (hospitals.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "No hospitals found.\nTry searching another location.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: hospitals.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RouteMapScreen(
                                  origin: LatLng(startLat, startLng),
                                  destination: LatLng(
                                    hospital.lat!,
                                    hospital.lng!,
                                  ),
                                  destinationAddress: hospital.address,
                                ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hospital Icon
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.local_hospital,
                                  color: Colors.teal,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name
                                    Text(
                                      hospital.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 22,

                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            hospital.address,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Distance & Time Row
                                    Row(
                                      children: [
                                        if (hospital.distance != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.directions,
                                                size: 18,
                                                color: Colors.teal,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                hospital.distance!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(width: 16),
                                        if (hospital.duration != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 18,
                                                color: Colors.teal,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                hospital.duration!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(
    GlobalKey<FormState> formKey,
    TextEditingController controller,
    String hint,
    String label,
    IconData icon,
  ) {
    return Form(
      key: formKey,
      autovalidateMode: _autovalidateMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GooglePlacesAutoCompleteTextFormField(
          textEditingController: controller,
          debounceTime: 50,
          countries: ["in"],
          fetchCoordinates: true,
          googleAPIKey: Constants.googleAPIKey,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.red),
            hintText: hint,
            labelText: label,
            labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            suffixIcon:
                controller.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          controller.clear();
                          hospitals.clear();
                          FocusScope.of(context).unfocus();
                        });
                      },
                    )
                    : null,
          ),
          validator:
              (value) => value!.isEmpty ? 'Please enter a location' : null,
          maxLines: 1,
          overlayContainerBuilder:
              (child) => Material(
                elevation: 1.0,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
          onFieldSubmitted: (_) => searchByLocationName(),
          // <- KEY LINE
          onPlaceDetailsWithCoordinatesReceived: (prediction) async {
            startLat = double.tryParse(prediction.lat ?? "0") ?? 0.0;
            startLng = double.tryParse(prediction.lng ?? "0") ?? 0.0;

            if (startLat != 0.0 && startLng != 0.0) {
              await fetchHospitalsByCoordinates(startLat, startLng);
            }
          },
          onChanged: (String value) => setState(() {}),
          onSuggestionClicked: (Prediction prediction) {
            setState(() {
              controller.text = prediction.description!;
            });
          },
          minInputLength: 3,
        ),
      ),
    );
  }
}
