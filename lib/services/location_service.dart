import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences.dart';
import '../models/geofence.dart';
import '../models/location_point.dart';
import 'notification_service.dart';
import 'geofence_service.dart';

class LocationService {
  static const String _historyKey = 'location_history';
  static const int maxHistoryPoints = 100;

  StreamSubscription<Position>? _positionStream;
  final List<LocationPoint> _history = [];
  final List<Geofence> _geofences = [];

  final _locationController = StreamController<LocationPoint>.broadcast();
  final _geofencesController = StreamController<List<Geofence>>.broadcast();

  Stream<LocationPoint> get locationStream => _locationController.stream;
  Stream<List<Geofence>> get geofencesStream => _geofencesController.stream;
  List<LocationPoint> get history => List.unmodifiable(_history);
  List<Geofence> get geofences => List.unmodifiable(_geofences);
  bool get isTracking => _positionStream != null;

  Future<void> init() async {
    await _loadGeofences();
    await _loadHistory();
  }

  Future<void> startTracking() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPositionUpdate);
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<bool> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  void _onPositionUpdate(Position position) {
    final point = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      timestamp: position.timestamp,
    );

    _history.insert(0, point);
    if (_history.length > maxHistoryPoints) {
      _history.removeRange(maxHistoryPoints, _history.length);
    }
    _saveHistory();

    _locationController.add(point);

    // Check geofences
    final events = GeofenceService.checkGeofences(_geofences, point);
    for (final event in events) {
      _saveGeofences();
      _geofencesController.add(_geofences);
      NotificationService.showGeofenceNotification(event);
    }
  }

  // Geofence CRUD
  Future<void> addGeofence(Geofence fence) async {
    _geofences.add(fence);
    _saveGeofences();
    _geofencesController.add(_geofences);
  }

  Future<void> removeGeofence(String id) async {
    _geofences.removeWhere((f) => f.id == id);
    _saveGeofences();
    _geofencesController.add(_geofences);
  }

  Future<void> updateGeofence(Geofence updated) async {
    final idx = _geofences.indexWhere((f) => f.id == updated.id);
    if (idx >= 0) {
      _geofences[idx] = updated;
      _saveGeofences();
      _geofencesController.add(_geofences);
    }
  }

  // Persistence
  Future<void> _loadGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('geofences');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _geofences.clear();
      _geofences.addAll(list.map((e) => Geofence.fromJson(e as Map<String, dynamic>)));
    }
  }

  Future<void> _saveGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geofences', jsonEncode(_geofences));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _history.clear();
      _history.addAll(
        list.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(_history.take(maxHistoryPoints).toList()),
    );
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _geofencesController.close();
  }
}
