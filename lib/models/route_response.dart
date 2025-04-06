class RouteResponse {
  final int distanceMeters;
  final String duration;

  RouteResponse({required this.distanceMeters, required this.duration});

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    return RouteResponse(
      distanceMeters: route['distanceMeters'],
      duration: route['duration'],
    );
  }
}
