import 'package:json_annotation/json_annotation.dart';

part 'geofence.g.dart';

@JsonSerializable()
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  int enterCount;
  int exitCount;
  bool isInside;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.enterCount = 0,
    this.exitCount = 0,
    this.isInside = false,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => _$GeofenceFromJson(json);
  Map<String, dynamic> toJson() => _$GeofenceToJson(this);

  Geofence copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    int? enterCount,
    int? exitCount,
    bool? isInside,
  }) {
    return Geofence(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      enterCount: enterCount ?? this.enterCount,
      exitCount: exitCount ?? this.exitCount,
      isInside: isInside ?? this.isInside,
    );
  }
}
