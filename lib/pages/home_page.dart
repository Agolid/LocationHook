import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/geofence.dart';
import '../models/location_point.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'geofence_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  double? _accuracy;
  double? _speed;
  StreamSubscription<LocationPoint>? _locationSub;
  final MapController _mapController = MapController();
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService.init();
    await _locationService.init();

    _locationSub = _locationService.locationStream.listen((point) {
      setState(() {
        _currentLocation = LatLng(point.latitude, point.longitude);
        _accuracy = point.accuracy;
        _speed = point.speed;
      });
      if (!_userInteracted && _currentLocation != null) {
        _mapController.move(_currentLocation!, 16);
      }
    });

    // Get initial position
    try {
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _accuracy = pos.accuracy;
        _speed = pos.speed;
      });
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _locationService.isTracking;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocationHook'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeofencePage(
                    locationService: _locationService,
                    currentLocation: _currentLocation,
                  ),
                ),
              );
            },
            tooltip: 'Geofences',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(39.9, 116.4),
                initialZoom: 14,
                onMapEvent: (event) {
                  if (event.source == MapEventSource.mapController) return;
                  if (event is! MapEventMove && event is! MapEventRotate && event is! MapEventFlingAnimation && event is! MapEventScrollWheelZoom) return;
                  if (!_userInteracted) setState(() => _userInteracted = true);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                  subdomains: const ['1', '2', '3', '4'],
                  userAgentPackageName: 'com.agolid.locationhook',
                ),
                CircleLayer(
                  circles: [
                    if (_currentLocation != null && _accuracy != null)
                      CircleMarker(
                        point: _currentLocation!,
                        radius: _accuracy!,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.15),
                        borderColor: Colors.blue.withOpacity(0.5),
                        borderStrokeWidth: 1,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 20,
                        height: 20,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ..._buildGeofenceMarkers(),
                  ],
                ),
              ],
            ),
          ),

          // Location Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      _currentLocation != null
                          ? 'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}  Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}'
                          : 'Waiting for location...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      _accuracy != null
                          ? 'Accuracy: ${_accuracy!.toStringAsFixed(1)}m'
                          : '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _speed != null
                          ? 'Speed: ${(_speed! * 3.6).toStringAsFixed(1)} km/h'
                          : '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(tracking ? Icons.stop : Icons.play_arrow),
                    label: Text(tracking ? 'Stop Tracking' : 'Start Tracking'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tracking ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentLocation != null
          ? FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 16);
                setState(() => _userInteracted = false);
              },
              mini: true,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  List<Marker> _buildGeofenceMarkers() {
    return _locationService.geofences.map((fence) {
      return Marker(
        point: LatLng(fence.latitude, fence.longitude),
        width: 24,
        height: 24,
        child: GestureDetector(
          onTap: () => _showGeofenceInfo(fence),
          child: Icon(
            fence.isInside ? Icons.check_circle : Icons.radio_button_unchecked,
            color: fence.isInside ? Colors.green : Colors.orange,
            size: 24,
          ),
        ),
      );
    }).toList();
  }

  void _showGeofenceInfo(Geofence fence) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(fence.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Radius: ${fence.radiusMeters.toStringAsFixed(0)}m'),
            Text('Status: ${fence.isInside ? "Inside ✅" : "Outside ❌"}'),
            Text('Entered: ${fence.enterCount} times'),
            Text('Exited: ${fence.exitCount} times'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTracking() {
    if (_locationService.isTracking) {
      _locationService.stopTracking();
    } else {
      _locationService.startTracking();
    }
    setState(() {});
  }
}
