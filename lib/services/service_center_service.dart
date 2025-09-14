import 'dart:convert';
import 'package:http/http.dart' as http;
import '../shared/constants/app_constants.dart';

class ServiceCenter {
  final String name;
  final double lat;
  final double lng;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final String? placeId;

  ServiceCenter({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.rating,
    this.userRatingsTotal,
    this.placeId,
  });
}

class ServiceCenterService {
  static const String _nearbyUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  Future<List<ServiceCenter>> findNearbyServiceCenters({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    final uri = Uri.parse(_nearbyUrl).replace(queryParameters: {
      'location': '$latitude,$longitude',
      'radius': radiusMeters.toString(),
      'type': 'car_repair',
      'key': AppConstants.googleMapsApiKey,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Google Places request failed: HTTP ${response.statusCode}');
    }

    final map = json.decode(response.body) as Map<String, dynamic>;
    if (map['status'] != 'OK' && map['status'] != 'ZERO_RESULTS') {
      throw Exception('Google Places error: ${map['status']}');
    }
    final results = (map['results'] as List? ?? []);
    return results.map((e) {
      final geometry = e['geometry']?['location'];
      return ServiceCenter(
        name: e['name']?.toString() ?? 'Unknown',
        lat: (geometry?['lat'] as num?)?.toDouble() ?? 0,
        lng: (geometry?['lng'] as num?)?.toDouble() ?? 0,
        address: e['vicinity']?.toString(),
        rating: (e['rating'] as num?)?.toDouble(),
        userRatingsTotal: (e['user_ratings_total'] as num?)?.toInt(),
        placeId: e['place_id']?.toString(),
      );
    }).toList();
  }
}


