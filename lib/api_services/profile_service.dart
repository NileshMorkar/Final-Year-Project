import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final String baseUrl = "https://ambulance-management-backend.onrender.com";

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? ambulanceId = prefs.getString('ambulanceId');
    // final token = prefs.getString('jwt_token');
    // print("------------- $ambulanceId");
    final response = await http.get(
      Uri.parse("$baseUrl/ambulances/$ambulanceId"),
      headers: {
        // 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(response.body)};
    } else {
      return {'success': false, 'message': 'Failed to load profile'};
    }
  }
}
