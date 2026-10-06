import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'api_service.dart';

class DermatologistServiceException implements Exception {
  const DermatologistServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DermatologistService {
  static Future<bool> requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DermatologistServiceException(
        'Turn on location services to find dermatologists near you.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DermatologistServiceException(
        'Location permission is disabled. Enable it in your device settings and try again.',
      );
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (error) {
      throw DermatologistServiceException(
        'Unable to get your location. Check that location services are on and try again. ($error)',
      );
    }
  }

  static Future<List<Dermatologist>> getNearbyDermatologists({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
  }) async {
    final uri = Uri.parse(
      '${AppTheme.backendBaseUrl}/api/dermatologists/nearby',
    ).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius': radiusMeters.toString(),
      },
    );

    late final http.Response response;
    try {
      response = await http
          .get(uri, headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 40));
    } on Exception catch (error) {
      throw DermatologistServiceException(
        'Could not reach dermatologist search. Check your connection and ensure the backend is running. ($error)',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const DermatologistServiceException(
        'The dermatologist service returned an invalid response.',
      );
    }

    if (response.statusCode != 200) {
      final message =
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : 'Dermatologist search failed (${response.statusCode}).';
      throw DermatologistServiceException(message);
    }

    if (decoded is! Map || decoded['results'] is! List) {
      throw const DermatologistServiceException(
        'The dermatologist service returned an invalid results list.',
      );
    }

    return (decoded['results'] as List)
        .whereType<Map>()
        .map((place) => Dermatologist.fromJson(place))
        .toList(growable: false);
  }
}

class Dermatologist {
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

  factory Dermatologist.fromJson(Map<dynamic, dynamic> json) {
    final rawHours = json['opening_hours'];
    final rawRating = json['rating'];
    final rawTotalRatings = json['total_ratings'];
    final rawOpen = json['is_open_now'];
    return Dermatologist(
      placeId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Dermatologist',
      address: json['address']?.toString() ?? 'Address not available',
      rating: rawRating is num ? rawRating.toDouble() : null,
      totalRatings: rawTotalRatings is num ? rawTotalRatings.toInt() : 0,
      isOpenNow: rawOpen is bool ? rawOpen : null,
      phoneNumber: json['phone_number']?.toString(),
      website: json['website']?.toString(),
      openingHours:
          rawHours is List
              ? rawHours.whereType<String>().toList(growable: false)
              : null,
      lat: (json['latitude'] as num?)?.toDouble() ?? 0,
      lng: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

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
}
