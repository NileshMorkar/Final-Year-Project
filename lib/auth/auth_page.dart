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
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool isLogin = true;
  bool _isCheckingLogin = true;

  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController ambulanceNumberController;
  late final TextEditingController licenseController;
  late final TextEditingController hospitalIdController;
  late final TextEditingController hospitalNameController;
  late final TextEditingController hospitalAddressController;

  String selectedAmbulanceType = 'Normal';
  static const List<String> ambulanceTypes = ['ICU', 'Normal'];

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    ambulanceNumberController = TextEditingController();
    licenseController = TextEditingController();
    hospitalIdController = TextEditingController();
    hospitalNameController = TextEditingController();
    hospitalAddressController = TextEditingController();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    ambulanceNumberController.dispose();
    licenseController.dispose();
    hospitalIdController.dispose();
    hospitalNameController.dispose();
    hospitalAddressController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('ambulanceId') != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      setState(() => _isCheckingLogin = false);
    }
  }

  void _showSnack(String message, [Color color = Colors.red]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    phoneController.clear();
    ambulanceNumberController.clear();
    licenseController.clear();
    hospitalIdController.clear();
    hospitalNameController.clear();
    hospitalAddressController.clear();
    selectedAmbulanceType = 'Normal';
  }

  bool _isLoading = false;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack("Please fill all fields properly");
      return;
    }
    setState(() => _isLoading = true); // Start loading

    try {
      final result =
          isLogin
              ? await _authService.login(
                emailController.text,
                passwordController.text,
              )
              : await _authService.register(
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
        _clearFields();
        final prefs = await SharedPreferences.getInstance();
        if (isLogin) {
          await prefs.setString('ambulanceId', result['data']['ambulanceId']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          setState(() => isLogin = true);
          _showSnack(
            "Account created successfully! Please login.",
            Colors.green,
          );
        }
      }
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false); // Stop loading
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  List<Step> _buildSteps() => [
    Step(
      title: const Text('Personal Information'),
      content: Column(
        children: [
          _buildTextField(
            controller: nameController,
            label: 'Full Name',
            icon: Icons.person,
          ),
          _buildTextField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            type: TextInputType.phone,
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    ),
    Step(
      title: const Text('Ambulance Information'),
      content: Column(
        children: [
          _buildTextField(
            controller: ambulanceNumberController,
            label: 'Ambulance Number',
            icon: Icons.local_shipping,
          ),
          _buildTextField(
            controller: licenseController,
            label: 'License Number',
            icon: Icons.badge,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              value: selectedAmbulanceType,
              decoration: InputDecoration(
                labelText: "Ambulance Type",
                prefixIcon: const Icon(Icons.local_pharmacy),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items:
                  ambulanceTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null)
                  setState(() => selectedAmbulanceType = value);
              },
            ),
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    ),
    Step(
      title: const Text('Hospital Information'),
      content: Column(
        children: [
          _buildTextField(
            controller: hospitalIdController,
            label: 'Hospital ID',
            icon: Icons.local_hospital,
          ),
          _buildTextField(
            controller: hospitalNameController,
            label: 'Hospital Name',
            icon: Icons.apartment,
          ),
          _buildTextField(
            controller: hospitalAddressController,
            label: 'Hospital Address',
            icon: Icons.location_on,
          ),
        ],
      ),
      isActive: _currentStep >= 2,
    ),
    Step(
      title: const Text('Login Credentials'),
      content: Column(
        children: [
          _buildTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email,
            type: TextInputType.emailAddress,
          ),
          _buildTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock,
            obscure: true,
          ),
        ],
      ),
      isActive: _currentStep >= 3,
    ),
  ];

  Widget _buildStepper() {
    return SingleChildScrollView(
      child: Stepper(
        type: StepperType.vertical,
        physics: const ClampingScrollPhysics(),
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < _buildSteps().length - 1) {
            setState(() => _currentStep++);
          } else {
            if (_formKey.currentState!.validate()) {
              _onSubmit();
            } else {
              _showSnack("Please fill all fields properly");
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: _buildSteps(),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade300,
                      // Teal theme
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 45),
                      // Width x Height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4, // Slight shadow
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade300,
                    // Teal theme
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 45),
                    // Width x Height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4, // Slight shadow
                  ),
                  child: Text(
                    _currentStep == _buildSteps().length - 1
                        ? 'Register'
                        : 'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toggleLoginRegister() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _clearFields();
          isLogin = !isLogin;
          _currentStep = 0;
        });
      },
      child: Container(
        margin: EdgeInsets.only(top: 20),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isLogin
              ? "Don't have an account? Register"
              : "Already registered? Login",
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00897B), // Softer teal at top
              Color(0xFFB2DFDB), // Light teal at bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_hospital,
                          size: 60,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 20),
                        isLogin
                            ? Column(
                              children: [
                                _buildTextField(
                                  controller: emailController,
                                  label: 'Email',
                                  icon: Icons.email,
                                  type: TextInputType.emailAddress,
                                ),
                                _buildTextField(
                                  controller: passwordController,
                                  label: 'Password',
                                  icon: Icons.lock,
                                  obscure: true,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _onSubmit();
                                            } else {
                                              _showSnack(
                                                "Please fill all fields properly",
                                              );
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade400,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 6,
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                          : const Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                ),
                              ],
                            )
                            : _buildStepper(),
                        // const SizedBox(height: 10),
                        _toggleLoginRegister(),
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
