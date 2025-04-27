import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_services/auth_service.dart';
import '../screens/main_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ambulanceNumberController = TextEditingController();
  final licenseController = TextEditingController();
  final hospitalIdController = TextEditingController();
  final hospitalNameController = TextEditingController();
  final hospitalAddressController = TextEditingController();
  final ambulanceTypeController = TextEditingController();

  String selectedAmbulanceType = 'Normal'; // Default value for ambulance type
  bool isLogin = true;
  bool isLoggedIn = false;

  final List<String> ambulanceTypes = ['ICU', 'Normal'];

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final ambulanceId = prefs.getString('ambulanceId');
    if (ambulanceId != null) {
      setState(() {
        isLoggedIn = true;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  // Clear all input fields
  void clearFields() {
    for (final controller in [
      emailController,
      passwordController,
      nameController,
      phoneController,
      ambulanceNumberController,
      licenseController,
      hospitalIdController,
      hospitalNameController,
      hospitalAddressController,
    ]) {
      controller.clear();
    }
    setState(() {
      selectedAmbulanceType = 'Normal';
    });
  }

  bool _validateFields() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }
    if (!isLogin &&
        (nameController.text.isEmpty ||
            phoneController.text.isEmpty ||
            ambulanceNumberController.text.isEmpty ||
            licenseController.text.isEmpty)) {
      return false;
    }

    return true;
  }

  void showSnack(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> onSubmit() async {
    if (!_validateFields()) {
      showSnack("Please fill in all required fields");
      return;
    }

    try {
      final authService = AuthService();
      final result =
          isLogin
              ? await authService.login(
                emailController.text,
                passwordController.text,
              )
              : await authService.register(
                name: nameController.text,
                email: emailController.text,
                password: passwordController.text,
                phone: phoneController.text,
                ambulanceNumber: ambulanceNumberController.text,
                licenseNumber: licenseController.text,
                ambulanceType: selectedAmbulanceType,
                hospitalId: hospitalIdController.text,
                hospitalName: hospitalNameController.text,
                hospitalAddress: hospitalAddressController.text,
              );

      if (result['success']) {
        clearFields();
        final prefs = await SharedPreferences.getInstance();
        // String? ambulanceId = prefs.getString('ambulanceId') ?? '1';

        if (isLogin) {
          // await prefs.setString('jwt_token', result['data']['token']);
          await prefs.setString('ambulanceId', result['data']['ambulanceId']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          setState(() => isLogin = true);
          showSnack(
            "Account created successfully! Please log in.",
            Colors.green,
          );
        }
      }
    } catch (e) {
      showSnack("Error: ${e.toString()}");
    }
  }

  Widget _authTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        const Icon(
                          Icons.local_hospital,
                          size: 60,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isLogin
                              ? "Welcome Back!"
                              : "Ambulance Driver Sign-Up",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!isLogin) ...[
                          _section("Personal Information", [
                            _authTextField(
                              nameController,
                              "Full Name",
                              Icons.person,
                            ),
                            _authTextField(
                              phoneController,
                              "Phone Number",
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ]),
                          _section("Ambulance Details", [
                            _authTextField(
                              ambulanceNumberController,
                              "Ambulance Number",
                              Icons.local_shipping,
                            ),
                            _authTextField(
                              licenseController,
                              "License Number",
                              Icons.badge,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: DropdownButtonFormField<String>(
                                value: selectedAmbulanceType,
                                decoration: InputDecoration(
                                  labelText: "Ambulance Type",
                                  prefixIcon: const Icon(Icons.local_pharmacy),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedAmbulanceType = value;
                                    });
                                  }
                                },
                                items:
                                    ambulanceTypes.map((type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ]),
                          _section("Hospital Information", [
                            _authTextField(
                              hospitalIdController,
                              "Hospital ID",
                              Icons.local_hospital,
                            ),
                            _authTextField(
                              hospitalNameController,
                              "Hospital Name",
                              Icons.apartment,
                            ),
                            _authTextField(
                              hospitalAddressController,
                              "Hospital Address",
                              Icons.location_on,
                            ),
                          ]),
                        ],
                        _section("Login Credentials", [
                          _authTextField(
                            emailController,
                            "Email",
                            Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _authTextField(
                            passwordController,
                            "Password",
                            Icons.lock,
                            obscureText: true,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                          ),
                          child: Text(
                            isLogin ? "Login" : "Register",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap:
                              () => setState(() {
                                clearFields();
                                isLogin = !isLogin;
                              }),
                          child: Text(
                            isLogin
                                ? "Don't have an account? Register"
                                : "Already registered? Login",
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
