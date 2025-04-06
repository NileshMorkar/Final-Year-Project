import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medi_1/constants/constants.dart';

class PolylineDirectionScreen extends StatefulWidget {
  const PolylineDirectionScreen({super.key});

  @override
  State<PolylineDirectionScreen> createState() =>
      _PolylineDirectionScreenState();
}

class _PolylineDirectionScreenState extends State<PolylineDirectionScreen> {
  late GoogleMapController mapController;
  double _originLatitude = 6.5212402, _originLongitude = 3.3679965;
  double _destLatitude = 6.849660, _destLongitude = 3.648190;
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = Constants.googleAPIKey;

  @override
  void initState() {
    super.initState();

    /// origin marker
    _addMarker(
      LatLng(_originLatitude, _originLongitude),
      "origin",
      BitmapDescriptor.defaultMarker,
    );

    /// destination marker
    _addMarker(
      LatLng(_destLatitude, _destLongitude),
      "destination",
      BitmapDescriptor.defaultMarkerWithHue(90),
    );
    _getPolyline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text("0.0 KM"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_originLatitude, _originLongitude),
          zoom: 15,
        ),
        myLocationEnabled: true,
        tiltGesturesEnabled: true,
        compassEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        onMapCreated: _onMapCreated,
        markers: Set<Marker>.of(markers.values),
        polylines: Set<Polyline>.of(polylines.values),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
    );
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      width: 5, // Ensure polyline is thick enough
      points: polylineCoordinates,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleAPiKey,
      request: PolylineRequest(
        origin: PointLatLng(_originLatitude, _originLongitude),
        destination: PointLatLng(_destLatitude, _destLongitude),
        mode: TravelMode.driving,
        avoidTolls: false,
        avoidFerries: false,
        avoidHighways: false,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates =
            result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
        _addPolyLine();
      });
    } else {
      print("No polyline found: ${result.errorMessage}");
    }
  }
}
