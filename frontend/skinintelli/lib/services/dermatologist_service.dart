import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

const String _googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

class DermatologistService {
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status == PermissionStatus.granted;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<Dermatologist>> getNearbyDermatologists({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
  }) async {
    final nearbyUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radiusMeters'
      '&type=doctor'
      '&keyword=dermatologist+skin+clinic'
      '&key=$_googleApiKey',
    );

    final nearbyResponse = await http.get(nearbyUrl);
    if (nearbyResponse.statusCode != 200) return [];

    final nearbyData = jsonDecode(nearbyResponse.body);
    if (nearbyData['status'] != 'OK') return [];

    final results = nearbyData['results'] as List? ?? const [];
    final dermatologists = <Dermatologist>[];

    for (final place in results.take(15)) {
      if (place is! Map) continue;

      final placeId = place['place_id']?.toString() ?? '';
      if (placeId.isEmpty) continue;

      final detail = await _getPlaceDetail(placeId);
      dermatologists.add(
        Dermatologist(
          placeId: placeId,
          name: place['name']?.toString() ?? 'Unknown',
          address: place['vicinity']?.toString() ?? 'Address not available',
          rating: (place['rating'] as num?)?.toDouble(),
          totalRatings: place['user_ratings_total'] is int
              ? place['user_ratings_total'] as int
              : 0,
          isOpenNow: place['opening_hours']?['open_now'] as bool?,
          phoneNumber: detail['phone'] as String?,
          website: detail['website'] as String?,
          openingHours: (detail['hours'] as List?)?.cast<String>(),
          lat: (place['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0.0,
          lng: (place['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    }

    dermatologists.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return dermatologists;
  }

  static Future<Map<String, dynamic>> _getPlaceDetail(String placeId) async {
    try {
      final detailUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=formatted_phone_number,website,opening_hours'
        '&key=$_googleApiKey',
      );
      final response = await http.get(detailUrl);
      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body);
      final result = data['result'] ?? {};
      return {
        'phone': result['formatted_phone_number'],
        'website': result['website'],
        'hours': (result['opening_hours']?['weekday_text'] as List?)?.cast<String>(),
      };
    } catch (_) {
      return {};
    }
  }
}

class Dermatologist {
  final String placeId;
  final String name;
  final String address;
  final double? rating;
  final int totalRatings;
  final bool? isOpenNow;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;
  final double lat;
  final double lng;

  const Dermatologist({
    required this.placeId,
    required this.name,
    required this.address,
    this.rating,
    this.totalRatings = 0,
    this.isOpenNow,
    this.phoneNumber,
    this.website,
    this.openingHours,
    required this.lat,
    required this.lng,
  });
}
