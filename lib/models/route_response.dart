class RouteResponse {
  final int distanceMeters;
  final String duration;
  final String encodedPolyline;

  RouteResponse({
    required this.distanceMeters,
    required this.duration,
    required this.encodedPolyline,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    return RouteResponse(
      distanceMeters: route['distanceMeters'],
      duration: route['duration'],
      encodedPolyline: route['polyline']['encodedPolyline'],
    );
  }
}
