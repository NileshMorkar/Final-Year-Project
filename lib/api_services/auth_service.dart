import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'https://ambulance-management-backend.onrender.com';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/ambulances/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body.containsKey('ambulanceId')) {
          return {
            'success': true,
            'data': {'ambulanceId': body['ambulanceId'].toString()},
          };
        } else if (body['message'] == 'Email Not Present!') {
          throw Exception('Email not found. Please check again.');
        } else if (body['message'] == 'Password Is Wrong!') {
          throw Exception('Wrong password. Please try again.');
        } else {
          throw Exception('Unknown response from server.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
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
      Uri.parse('$baseUrl/ambulances'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
        'password': password,
        'phoneNumber': phone,
        'ambulanceNumber': ambulanceNumber,
        'licenceNumber': licenseNumber,
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
