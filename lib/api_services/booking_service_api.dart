import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  static Future<List<Map<String, dynamic>>> fetchDriverBookings() async {
    final prefs = await SharedPreferences.getInstance();
    String? ambulanceId = prefs.getString('ambulanceId') ?? '1';

    final url = Uri.parse(
      'https://ambulance-management-backend.onrender.com/ambulance/booking/driver?ambulanceId=$ambulanceId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((booking) => booking as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load booking history');
    }
  }
}
