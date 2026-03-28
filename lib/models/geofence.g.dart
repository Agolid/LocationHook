// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Geofence _$GeofenceFromJson(Map<String, dynamic> json) => Geofence(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      enterCount: (json['enterCount'] as num?)?.toInt() ?? 0,
      exitCount: (json['exitCount'] as num?)?.toInt() ?? 0,
      isInside: json['isInside'] as bool? ?? false,
    );

Map<String, dynamic> _$GeofenceToJson(Geofence instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radiusMeters': instance.radiusMeters,
      'enterCount': instance.enterCount,
      'exitCount': instance.exitCount,
      'isInside': instance.isInside,
    };
