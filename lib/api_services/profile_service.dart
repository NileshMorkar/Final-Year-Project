class ProfileService {
  Future<Map<String, dynamic>> getProfile() async {
    // Simulate a network delay
    await Future.delayed(Duration(seconds: 1));

    // Mocked response data
    final mockData = {
      'name': 'Nilesh Morkar',
      'email': 'ndmorkar@gmail.com',
      'phone': '9876543210',
      'ambulanceNumber': 'MH12AB1234',
      'licenseNumber': 'LIC123456789',
      'hospitalId': 'HOSP123',
      'hospitalName': 'City Hospital',
      'hospitalAddress': '123 Health Street, Pune',
    };

    return {'success': true, 'data': mockData};
  }

  // final String baseUrl = "https://your-api-url.com";
  //
  // Future<Map<String, dynamic>> getProfile() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('jwt_token');
  //
  //   final response = await http.get(
  //     Uri.parse("$baseUrl/api/driver/profile"),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     return {'success': true, 'data': json.decode(response.body)};
  //   } else {
  //     return {'success': false, 'message': 'Failed to load profile'};
  //   }
  // }
}
