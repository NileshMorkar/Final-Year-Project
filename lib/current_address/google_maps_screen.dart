import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medi_1/api_services/api_services.dart';
import 'package:medi_1/models/place_from_coordinates.dart';

class GoogleMapsScreen extends StatefulWidget {
  final double lat, lng;

  GoogleMapsScreen({super.key, required this.lat, required this.lng});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  double currentLat = 0.0;
  double currentLng = 0.0;

  PlaceFromCoordinates placeFromCoordinates = PlaceFromCoordinates();
  bool isLoading = true;

  getLocation() {
    ApiServices.getPlaceFromCoordinates(widget.lat, widget.lng).then((value) {
      setState(() {
        currentLat = value.results?[0].geometry?.location?.lat ?? 0;
        currentLng = value.results?[0].geometry?.location?.lng ?? 0;
        isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: const Text(
          "Current Address",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
              : Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLat, currentLng),
                      zoom: 14.5,
                    ),
                    onCameraIdle: () {
                      ApiServices.getPlaceFromCoordinates(
                            currentLat,
                            currentLng,
                          )
                          .then((value) {
                            if (value.results != null &&
                                value.results!.isNotEmpty) {
                              setState(() {
                                placeFromCoordinates = value;
                              });
                            } else {
                              setState(() {
                                placeFromCoordinates = PlaceFromCoordinates();
                              });
                            }
                          })
                          .catchError((error) {
                            setState(() {
                              placeFromCoordinates = PlaceFromCoordinates();
                            });
                          });
                    },
                    onCameraMove: (CameraPosition position) {
                      setState(() {
                        currentLat = position.target.latitude;
                        currentLng = position.target.longitude;
                      });
                    },
                  ),

                  // Location Pin Icon
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),

      // Bottom Sheet with Address Details
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                placeFromCoordinates.results == null
                    ? "Fetching address..."
                    : placeFromCoordinates.results!.isNotEmpty
                    ? placeFromCoordinates.results![0].formattedAddress ??
                        "No address found"
                    : "No address found",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
