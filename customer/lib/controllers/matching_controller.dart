import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller: findes every provider who should receive a new request
///
/// The request goes to All of them at once, and the first to accept gets it

class MatchingController {
  MatchingController({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  ///only providers within this distance receive the request
  static const double radiusKm = 5;

  Future<List<String>> findAvailableProviders({
    required String categoryId,
    required String optionId,
    required double lat,
    required double lng,
  }) async {
    final snapshot = await _firestore
        .collection('providers')
        .where('status', isEqualTo: 'approved')
        .where('isAvailable', isEqualTo: true)
        .get();

    final nearby = <({String id, double km})>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!offersOption(data['servicesOffered'], categoryId, optionId))continue;

      final location = readLatLng(data['currentLocation']);
      if (location == null) continue;

      final km = distanceKm(lat, lng, location.lat, location.lng);
      if (km <= radiusKm) nearby.add((id: doc.id, km: km));
    }

    nearby.sort((a, b) => a.km.compareTo(b.km));
    return [for (final p in nearby) p.id];
  }

  static bool offersOption(
    dynamic servicesOffered,
    String categoryId,
    String optionId,
  ) {
    if (servicesOffered is! Map) return false;
    final category = servicesOffered[categoryId];
    if (category is! Map) return false;
    final options = category['options'];
    if (options is! List) return false;
    return options.any(
      (o) => o is Map && o['id'] == optionId && o['enabled'] == true,
    );
  }

  static ({double lat, double lng})? readLatLng(dynamic value) {
    if (value is GeoPoint) {
      return (lat: value.latitude, lng: value.longitude);
    }
    if (value is Map) {
      final lat = value['lat'];
      final lng = value['lng'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
    }
    return null;
  }

  /// Straight-line distance is Km between two point (Haversine formula)
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    double red(double deg) => deg * pi / 180;
    final dLat = red(lat2 - lat1);
    final dLng = red(lng2 - lng1);
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(red(lat1)) * cos(red(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * 6371 * asin(sqrt(h));
  }
}
