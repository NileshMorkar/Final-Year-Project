import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      'https://final-year-project-c1mv.onrender.com/api/user/auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String ambulanceNumber,
    required String licenseNumber,
    required String hospitalId,
    required String hospitalName,
    required String hospitalAddress,
    required String ambulanceType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'ambulanceNumber': ambulanceNumber,
        'licenseNumber': licenseNumber,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'hospitalAddress': hospitalAddress,
        'ambulanceType': ambulanceType,
      }),
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Unknown error'};
    }
  }
}
