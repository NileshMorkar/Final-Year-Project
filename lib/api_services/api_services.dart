import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:medi_1/models/place_from_coordinates.dart';

import '../Constants/Constants.dart';
import '../models/hospital_places.dart';
import '../models/route_response.dart';

class ApiServices {
  /// Builds Google Maps LatLng JSON
  static Map<String, dynamic> _buildLatLng(LatLng latLng) => {
    "latitude": latLng.latitude,
    "longitude": latLng.longitude,
  };

  /// Fetches coordinates from a full address using Google Geocoding API
  static Future<LatLng?> fetchCoordinatesFromAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=${Constants.googleAPIKey}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else {
          print("Geocode: No results for address: $address");
        }
      } else {
        print("Geocode API error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception in fetchCoordinatesFromAddress: $e");
    }

    return null;
  }

  /// Fetches nearby hospitals from Google Places API
  static Future<List<HospitalPlace>> fetchNearbyHospitals({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      "https://places.googleapis.com/v1/places:searchNearby",
    );

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": Constants.googleAPIKey,
      "X-Goog-FieldMask":
          "places.displayName,places.formattedAddress,places.types,places.websiteUri",
    };

    final body = jsonEncode({
      "includedTypes": ["hospital"],
      "rankPreference": "DISTANCE",
      "maxResultCount": 10,
      "locationRestriction": {
        "circle": {
          "center": {"latitude": latitude, "longitude": longitude},
          "radius": 5000.0,
        },
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final places = data['places'] as List<dynamic>?;
        return places?.map((place) => HospitalPlace.fromJson(place)).toList() ??
            [];
      } else {
        print("Failed to fetch hospitals: ${response.body}");
        throw Exception("Hospital API error: ${response.body}");
      }
    } catch (e) {
      print("Exception in fetchNearbyHospitals: $e");
      rethrow;
    }
  }

  /// Fetches route info (distance, time, polyline) between origin and destination
  static Future<RouteResponse?> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );

    final headers = {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": Constants.googleAPIKey,
      "X-Goog-FieldMask":
          "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline",
    };

    final body = jsonEncode({
      "origin": {
        "location": {"latLng": _buildLatLng(origin)},
      },
      "destination": {
        "location": {"latLng": _buildLatLng(destination)},
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
        return RouteResponse.fromJson(jsonDecode(response.body));
      } else {
        print("Route API error: ${response.body}");
      }
    } catch (e) {
      print("Exception in fetchRoute: $e");
    }
    return null;
  }

  /// Reverse geocode coordinates to address using Google Geocoding API
  static Future<PlaceFromCoordinates> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${Constants.googleAPIKey}",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return PlaceFromCoordinates.fromJson(data);
        } else {
          print(
            "Reverse Geocode Error: ${data['status']} - ${data["error_message"] ?? "No message"}",
          );
          throw Exception("Reverse Geocode failed: ${data['status']}");
        }
      } else {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      print("Exception in getPlaceFromCoordinates: $e");
      rethrow;
    }
  }
}
