import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medi_1/api_services/api_services.dart';
import 'package:medi_1/helper/Helper.dart';

class RouteMapScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationAddress;

  const RouteMapScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.destinationAddress,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  late GoogleMapController _mapController;
  late PolylinePoints _polylinePoints;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];
  StreamSubscription<Position>? _positionStream;

  BitmapDescriptor? _customLiveIcon;
  LatLng? _currentLiveLocation;
  int? _distanceMeters;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints();
    _loadCustomIcon();
    _requestLocationPermission();
    _initializeMarkers();
    _fetchRoute();
    _startLiveLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomIcon() async {
    _customLiveIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(20, 20)),
      'assets/ambulance.png',
    );
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _initializeMarkers() {
    _addMarker('origin', widget.origin);
    _addMarker('destination', widget.destination);
  }

  void _addMarker(String id, LatLng position, {BitmapDescriptor? icon}) {
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        icon:
            icon ??
            (id == 'origin'
                ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                )
                : id == 'destination'
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : BitmapDescriptor.defaultMarker),
        infoWindow: InfoWindow(
          title:
              id == 'origin'
                  ? 'Start'
                  : id == 'destination'
                  ? 'Destination'
                  : '',
        ),
      ),
    );
  }

  void _startLiveLocationUpdates() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position position) async {
      final newLocation = LatLng(position.latitude, position.longitude);
      _currentLiveLocation = newLocation;

      // Update live marker
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'live_location',
      );
      _addMarker(
        'live_location',
        newLocation,
        icon:
            _customLiveIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );

      // Animate map
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLocation, zoom: 16, tilt: 50),
        ),
      );

      // Update route
      _polylines.clear();
      await _fetchRoute(newOrigin: newLocation);
    });
  }

  Future<void> _fetchRoute({LatLng? newOrigin}) async {
    final origin = newOrigin ?? widget.origin;

    try {
      final routeData = await ApiServices.fetchRoute(
        origin: origin,
        destination: widget.destination,
      );

      if (routeData != null) {
        _decodePolyline(routeData.encodedPolyline);
        setState(() {
          _distanceMeters = routeData.distanceMeters;
          _duration = routeData.duration;
        });
      } else {
        _showSnackBar("Unable to get route details.");
      }
    } catch (e) {
      debugPrint("Route fetching failed: $e");
      _showSnackBar("Failed to fetch route. Please try again.");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _decodePolyline(String encodedPolyline) {
    final result = _polylinePoints.decodePolyline(encodedPolyline);
    _polylineCoordinates
      ..clear()
      ..addAll(result.map((e) => LatLng(e.latitude, e.longitude)));

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: _polylineCoordinates,
        ),
      );
    });
  }

  Widget _buildBottomSheet() {
    final distance =
        _distanceMeters != null
            ? (_distanceMeters! / 1000).toStringAsFixed(2)
            : "--";
    final duration =
        _duration != null ? Helper.formatDuration(_duration!) : "--";
    final location = _currentLiveLocation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(
                Icons.route_rounded,
                "$distance Km",
                Icons.access_time_filled_rounded,
                duration,
              ),
              const Divider(thickness: 1, height: 20),
              _locationRow(Icons.location_on, widget.destinationAddress),
              const SizedBox(height: 6),
              _locationRow(
                Icons.my_location_rounded,
                location != null
                    ? 'Lat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}'
                    : 'Waiting for location...',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon1, String text1, IconData icon2, String text2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon1, color: Colors.green),
            const SizedBox(width: 8),
            Text(text1, style: _infoTextStyle),
          ],
        ),
        Row(
          children: [
            Icon(icon2, color: Colors.blue),
            const SizedBox(width: 8),
            Text(text2, style: _infoTextStyle),
          ],
        ),
      ],
    );
  }

  Widget _locationRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: icon == Icons.location_on ? Colors.red : Colors.black54,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  TextStyle get _infoTextStyle =>
      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.warning_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "EMERGENCY - AMBULANCE IN TRANSIT",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 6,
        leading: const Icon(Icons.local_hospital_rounded),
        title: const Text(
          "Live Ambulance Route",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),

      body: Column(
        children: [
          _buildEmergencyBanner(),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.origin,
                    zoom: 15,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: _buildBottomSheet(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
