import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi_1/auth/auth_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String availabilityStatus = 'Available';
  String? ambulanceType;
  File? _profileImage;

  final List<String> availabilityOptions = ['Available', 'Busy'];
  final List<String> ambulanceTypeOptions = ["ICU", "Normal"];
  final ImagePicker _picker = ImagePicker();
  String selectedAmbulanceType = 'Normal'; // Default value

  @override
  void initState() {
    super.initState();
    loadStoredImage();
    fetchProfile();
  }

  Future<void> loadStoredImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null && File(path).existsSync()) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> fetchProfile() async {
    final result = await ProfileService().getProfile();
    if (result['success']) {
      setState(() {
        profileData = result['data'];
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final String fileName = "profile_image.jpg";
      final File localImage = await File(
        pickedFile.path,
      ).copy('$path/$fileName');

      setState(() {
        _profileImage = localImage;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', localImage.path);
    }
  }

  // Logout function with confirmation dialog
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthPage()),
                );
              },
              child: const Text("Log Out"),
            ),
          ],
        );
      },
    );
  }

  Widget buildProfileField(String label, String? value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          value ?? 'N/A',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text(
          "Driver Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () => _logout(
                  context,
                ), // Show confirmation dialog before logging out
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : profileData == null
              ? const Center(child: Text("Failed to load profile"))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.teal.shade100,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (profileData!['profileImageUrl'] !=
                                              null &&
                                          profileData!['profileImageUrl']
                                              .isNotEmpty)
                                      ? NetworkImage(
                                            profileData!['profileImageUrl'],
                                          )
                                          as ImageProvider
                                      : null,
                              child:
                                  (_profileImage == null &&
                                          (profileData!['profileImageUrl'] ==
                                                  null ||
                                              profileData!['profileImageUrl']
                                                  .isEmpty))
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.teal,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profileData!['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profileData!['email'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    // Availability Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.toggle_on_rounded,
                            color: Colors.teal,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Availability:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availabilityStatus,
                                isExpanded: true,
                                items:
                                    availabilityOptions
                                        .map(
                                          (status) => DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(status),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      availabilityStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Ambulance Type Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital,
                            color: Colors.teal,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Ambulance Type:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedAmbulanceType,
                                // This will store the selected value
                                isExpanded: true,
                                items:
                                    ambulanceTypeOptions
                                        .map(
                                          (type) => DropdownMenuItem<String>(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedAmbulanceType =
                                          value; // Update selected value
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 30, thickness: 1.2),
                    // Profile Fields
                    buildProfileField(
                      "Phone",
                      profileData!['phone'],
                      Icons.phone,
                    ),
                    buildProfileField(
                      "Ambulance Number",
                      profileData!['ambulanceNumber'],
                      Icons.local_shipping,
                    ),
                    buildProfileField(
                      "License Number",
                      profileData!['licenseNumber'],
                      Icons.badge,
                    ),
                    buildProfileField(
                      "Hospital ID",
                      profileData!['hospitalId'],
                      Icons.qr_code_2,
                    ),
                    buildProfileField(
                      "Hospital Name",
                      profileData!['hospitalName'],
                      Icons.local_hospital,
                    ),
                    buildProfileField(
                      "Hospital Address",
                      profileData!['hospitalAddress'],
                      Icons.location_on,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.all(17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _logout(context),
                        child: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
