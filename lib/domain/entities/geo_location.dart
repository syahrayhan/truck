import 'package:equatable/equatable.dart';

/// Domain entity for geographic location
class GeoLocation extends Equatable {
  final double lat;
  final double lng;
  final double? accuracy;
  final DateTime? timestamp;

  const GeoLocation({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.timestamp,
  });

  GeoLocation copyWith({
    double? lat,
    double? lng,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return GeoLocation(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Calculate distance to another location in meters using Haversine formula
  double distanceTo(GeoLocation other) {
    return _haversineDistance(lat, lng, other.lat, other.lng);
  }

  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double deg) => deg * 3.14159265359 / 180;
  
  static double _sin(double x) {
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;
    double result = 0, term = x;
    for (int n = 0; n < 15; n++) {
      result += term;
      term *= -x * x / ((2 * n + 2) * (2 * n + 3));
    }
    return result;
  }
  
  static double _cos(double x) => _sin(x + 3.14159265359 / 2);
  
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 20; i++) g = (g + x / g) / 2;
    return g;
  }
  
  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (y > 0) return 3.14159265359 / 2;
    if (y < 0) return -3.14159265359 / 2;
    return 0;
  }
  
  static double _atan(double x) {
    if (x.abs() > 1) return (x > 0 ? 1 : -1) * 3.14159265359 / 2 - _atan(1 / x);
    double result = 0, term = x;
    for (int n = 0; n < 20; n++) {
      result += term / (2 * n + 1) * (n % 2 == 0 ? 1 : -1);
      term *= x * x;
    }
    return result;
  }

  @override
  List<Object?> get props => [lat, lng, accuracy, timestamp];

  @override
  String toString() => 'GeoLocation($lat, $lng)';
}


