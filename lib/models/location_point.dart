import 'package:json_annotation/json_annotation.dart';

part 'location_point.g.dart';

@JsonSerializable()
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    required this.timestamp,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);
  Map<String, dynamic> toJson() => _$LocationPointToJson(this);
}
