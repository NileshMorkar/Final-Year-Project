import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:medi_1/constants/constants.dart';
import 'package:medi_1/helper/Helper.dart';

class RouteMapScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final int distanceMeters;
  final String duration;
  final String destinationAddress;

  const RouteMapScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.duration,

    required this.destinationAddress,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  GoogleMapController? _mapController;
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  String googleApiKey = Constants.googleAPIKey;
  BitmapDescriptor? _customLiveIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
    _requestLocationPermission();
    _setMarkers();
    _fetchRoute();
    _startLiveLocationUpdates();
  }

  Future<void> _loadCustomIcon() async {
    _customLiveIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'assets/ambulance.png',
    );
  }

  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLiveLocation;

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLiveLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentLiveLocation = LatLng(position.latitude, position.longitude);

        // Update marker
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'live_location',
        );
        _markers.add(
          Marker(
            markerId: MarkerId('live_location'),
            position: _currentLiveLocation!,
            icon:
                _customLiveIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
            infoWindow: InfoWindow(title: 'You are here'),
          ),
        );

        // Move camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLiveLocation!),
        );
      });
    });
  }

  void _setMarkers() {
    _markers.add(Marker(markerId: MarkerId("origin"), position: widget.origin));
    _markers.add(
      Marker(markerId: MarkerId("destination"), position: widget.destination),
    );
  }

  Future<void> _fetchRoute() async {
    final url = Uri.parse(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": googleApiKey,
      "X-Goog-FieldMask":
          "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline",
    };

    final body = jsonEncode({
      "origin": {
        "location": {
          "latLng": {
            "latitude": widget.origin.latitude,
            "longitude": widget.origin.longitude,
          },
        },
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": widget.destination.latitude,
            "longitude": widget.destination.longitude,
          },
        },
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": {
        "avoidTolls": false,
        "avoidHighways": false,
        "avoidFerries": false,
      },
      "languageCode": "en-US",
      "units": "IMPERIAL",
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String encodedPolyline =
            data["routes"][0]["polyline"]["encodedPolyline"];
        _decodePolyline(encodedPolyline);
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void _decodePolyline(String encodedPolyline) {
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
    polylineCoordinates.clear();

    for (var point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
    });
  }

  Widget _buildBottomSheet() {
    final distanceKm = (widget.distanceMeters / 1000).toStringAsFixed(2);
    final duration = Helper().formatDuration(widget.duration);

    String latLongText =
        _currentLiveLocation != null
            ? 'Lat: ${_currentLiveLocation!.latitude.toStringAsFixed(5)}, '
                'Lng: ${_currentLiveLocation!.longitude.toStringAsFixed(5)}'
            : 'Waiting for location...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.route, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    '$distanceKm Km',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '$duration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.destinationAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.gps_fixed, color: Colors.black54),
              SizedBox(width: 8),
              Text(
                latLongText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Maps - Route")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.origin,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }
}
