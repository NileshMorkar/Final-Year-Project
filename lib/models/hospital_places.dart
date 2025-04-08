class HospitalPlace {
  final String name;
  final String address;
  final String? website;
  String? distance;
  String? duration;
  double? lat;
  double? lng;

  HospitalPlace({required this.name, required this.address, this.website});

  factory HospitalPlace.fromJson(Map<String, dynamic> json) {
    return HospitalPlace(
      name: json['displayName']?['text'] ?? 'No Name',
      address: json['formattedAddress'] ?? 'No Address',
      website: json['websiteUri'],
    );
  }
}
