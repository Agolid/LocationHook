import 'dart:math';
import '../models/geofence.dart';
import '../models/location_point.dart';

class GeofenceEvent {
  final Geofence geofence;
  final bool entered;
  final DateTime timestamp;

  GeofenceEvent({
    required this.geofence,
    required this.entered,
    required this.timestamp,
  });
}

class GeofenceService {
  /// Check all geofences against current location, return events for state changes.
  static List<GeofenceEvent> checkGeofences(
    List<Geofence> fences,
    LocationPoint point,
  ) {
    final events = <GeofenceEvent>[];

    for (int i = 0; i < fences.length; i++) {
      final fence = fences[i];
      final distance = _haversineDistance(
        point.latitude,
        point.longitude,
        fence.latitude,
        fence.longitude,
      );

      final wasInside = fence.isInside;
      final nowInside = distance <= fence.radiusMeters;

      if (!wasInside && nowInside) {
        fences[i] = fence.copyWith(
          isInside: true,
          enterCount: fence.enterCount + 1,
        );
        events.add(GeofenceEvent(
          geofence: fences[i],
          entered: true,
          timestamp: point.timestamp,
        ));
      } else if (wasInside && !nowInside) {
        fences[i] = fence.copyWith(
          isInside: false,
          exitCount: fence.exitCount + 1,
        );
        events.add(GeofenceEvent(
          geofence: fences[i],
          entered: false,
          timestamp: point.timestamp,
        ));
      }
    }

    return events;
  }

  /// Haversine distance in meters between two lat/lng points.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Calculate distance from a point to a geofence center.
  static double distanceToFence(LocationPoint point, Geofence fence) {
    return _haversineDistance(
      point.latitude,
      point.longitude,
      fence.latitude,
      fence.longitude,
    );
  }
}
