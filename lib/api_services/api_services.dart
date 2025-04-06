import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medi_1/constants/constants.dart';
import 'package:medi_1/models/place_from_coordinates.dart';

import '../models/route_response.dart';

class ApiServices {
  static Future<RouteResponse?> fetchRouteDetails(
    String originAddress,
    String destinationAddress,
  ) async {
    const apiKey = Constants.googleAPIKey; // Replace with your actual API key
    const url = 'https://routes.googleapis.com/directions/v2:computeRoutes';

    final body = jsonEncode({
      "origin": {"address": originAddress},
      "destination": {"address": destinationAddress},
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return RouteResponse.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to load route: ${response.statusCode}');
      return null;
    }
  }

  static Future<PlaceFromCoordinates> getPlaceFromCoordinates(
    double lat,
    double lng,
  ) async {
    Uri url = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?key=${Constants.googleAPIKey}&latlng=$lat,$lng",
    );

    print("Fetching from URL: $url"); // Debugging

    var response = await http.get(url);

    // print("API Response Body: ${response.body}"); // Debugging

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      if (jsonData["status"] == "OK") {
        return PlaceFromCoordinates.fromJson(jsonData);
      } else {
        print(
          "Google Maps API Error: ${jsonData["status"]} - ${jsonData["error_message"]}",
        );
        throw Exception("Google Maps API Error: ${jsonData["status"]}");
      }
    } else {
      throw Exception(
        "API Error: getPlaceFromCoordinates, Status Code: ${response.statusCode}",
      );
    }
  }
}
