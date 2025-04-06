import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:medi_1/polylines/route_map_screen.dart';

import '../api_services/api_services.dart';
import '../constants/constants.dart';
import '../permissions/location_permission.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key});

  @override
  State<SearchLocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<SearchLocationScreen> {
  TextEditingController searchPlaceController1 = TextEditingController(),
      searchPlaceController2 = TextEditingController();
  final _yourGoogleAPIKey = Constants.googleAPIKey;
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>(),
      _formKey2 = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  double startLat = 0, startLng = 0;
  double endLat = 0, endLng = 0;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: const Icon(Icons.location_on, color: Colors.white),
        backgroundColor: Colors.greenAccent.shade700,
        title: const Text(
          "Select Location",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLocationField(
              _formKey1,
              searchPlaceController1,
              'Enter Current Location ...',
              'Current Location',
              Icons.my_location,
            ),

            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_vert, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  "OR",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _buildCurrentLocationButton(),
            const SizedBox(height: 22),
            Divider(thickness: 2, color: Colors.grey.shade400),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  "To",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLocationField(
              _formKey2,
              searchPlaceController2,
              'Enter Destination ...',
              'Choose destination',
              Icons.location_on,
            ),
            const SizedBox(height: 14),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(
    GlobalKey<FormState> formKey,
    TextEditingController controller,
    String hint,
    String label,
    IconData icon,
  ) {
    return Form(
      key: formKey,
      autovalidateMode: _autovalidateMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GooglePlacesAutoCompleteTextFormField(
          textEditingController: controller,
          debounceTime: 50,
          countries: ["in"],
          fetchCoordinates: true,
          googleAPIKey: _yourGoogleAPIKey,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.greenAccent.shade700),
            hintText: hint,
            labelText: label,
            labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            suffixIcon:
                controller.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed:
                          () => setState(() {
                            controller.clear();
                            FocusScope.of(context).unfocus();
                          }),
                    )
                    : null,
          ),
          validator:
              (value) => value!.isEmpty ? 'Please enter a location' : null,
          maxLines: 1,
          overlayContainerBuilder:
              (child) => Material(
                elevation: 1.0,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
          onPlaceDetailsWithCoordinatesReceived: (prediction) {
            if (controller == searchPlaceController1) {
              startLat = double.tryParse(prediction.lat ?? "0") ?? 0.0;
              startLng = double.tryParse(prediction.lng ?? "0") ?? 0.0;
            } else {
              endLat = double.tryParse(prediction.lat ?? "0") ?? 0.0;
              endLng = double.tryParse(prediction.lng ?? "0") ?? 0.0;
            }
          },
          onChanged: (String value) => setState(() {}),
          onSuggestionClicked:
              (Prediction prediction) => setState(() {
                controller.text = prediction.description!;
              }),
          minInputLength: 3,
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLoading = true;
        });
        determinePosition().then((value) {
          startLat = value.latitude;
          startLng = value.longitude;
          ApiServices.getPlaceFromCoordinates(
            value.latitude,
            value.longitude,
          ).then(
            (value) => {
              setState(() {
                searchPlaceController1.text =
                    value.results?[0].formattedAddress ?? "";
                isLoading = false;
              }),
            },
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade700,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade600,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              isLoading
                  ? [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ]
                  : const [
                    Icon(Icons.my_location, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Use Current Location",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey1.currentState!.validate() &&
              _formKey2.currentState!.validate()) {
            setState(() => isLoading = true);

            final routeResponse = await ApiServices.fetchRouteDetails(
              searchPlaceController1.text,
              searchPlaceController2.text,
            );

            setState(() => isLoading = false);

            if (routeResponse != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RouteMapScreen(
                        origin: LatLng(startLat, startLng),
                        destination: LatLng(endLat, endLng),
                        distanceMeters: routeResponse.distanceMeters,
                        duration: routeResponse.duration,
                        destinationAddress: searchPlaceController2.text,
                      ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to fetch route info")),
              );
            }
          } else {
            setState(() {
              _autovalidateMode = AutovalidateMode.always;
            });
          }
        },

        child: const Text(
          'Submit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
