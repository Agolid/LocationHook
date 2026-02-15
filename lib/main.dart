import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const LocationHookApp());
}

class LocationHookApp extends StatelessWidget {
  const LocationHookApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocationHook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isTracking = false;
  Position? _currentPosition;
  List<Position> _positionHistory = [];
  List<Geofence> _geofences = [];
  String _statusMessage = 'Waiting to start...';
  int _geofenceEnterCount = 0;
  int _geofenceExitCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadGeofences();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied) {
      setState(() {
        _statusMessage = 'Location permission denied';
      });
      return;
    }

    final alwaysStatus = await Permission.locationAlways.request();
    if (alwaysStatus.isGranted) {
      setState(() {
        _statusMessage = 'All permissions granted';
      });
    } else {
      setState(() {
        _statusMessage = 'Background location permission not granted';
      });
    }

    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      setState(() {
        _statusMessage = 'Notification permission denied';
      });
    }
  }

  Future<void> _loadGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final geofencesJson = prefs.getString('geofences');
    
    if (geofencesJson != null) {
      setState(() {
        _geofences = Geofence.parseList(geofencesJson!);
      });
    }
  }

  Future<void> _saveGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final geofencesJson = Geofence.encodeList(_geofences);
    await prefs.setString('geofences', geofencesJson);
  }

  Future<void> _startTracking() async {
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) {
        setState(() {
          _statusMessage = 'Please grant location permission';
        });
        return;
      }

      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      positionStream.listen((Position position) {
        setState(() {
          _currentPosition = position;
          _positionHistory.insert(0, position);
          if (_positionHistory.length > 100) {
            _positionHistory.removeLast();
          }
        });

        _checkGeofences(position);
      }).onError((error) {
        setState(() {
          _statusMessage = 'Tracking error: $error';
        });
      });

      setState(() {
        _isTracking = true;
        _statusMessage = 'Tracking started';
      });

      await NotificationService().showNotification(
        title: 'Location Tracking',
        body: 'Background tracking started',
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to start tracking: $e';
      });
    }
  }

  Future<void> _stopTracking() async {
    setState(() {
      _isTracking = false;
      _statusMessage = 'Tracking stopped';
    });

    await NotificationService().showNotification(
      title: 'Location Tracking',
      body: 'Background tracking stopped',
    );
  }

  Future<bool> _hasLocationPermission() async {
    final locationWhenInUse = await Permission.locationWhenInUse.status.isGranted;
    final locationAlways = await Permission.locationAlways.status.isGranted;
    return locationWhenInUse || locationAlways;
  }

  void _checkGeofences(Position position) {
    for (final geofence in _geofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      final wasInside = geofence.isInside;
      final isNowInside = distance <= geofence.radius;

      geofence.isInside = isNowInside;

      if (!wasInside && isNowInside) {
        setState(() {
          _geofenceEnterCount++;
        });

        NotificationService().showNotification(
          title: 'Geofence Entered',
          body: 'Entered: ${geofence.name}',
        );
      } else if (wasInside && !isNowInside) {
        setState(() {
          _geofenceExitCount++;
        });

        NotificationService().showNotification(
          title: 'Geofence Exited',
          body: 'Exited: ${geofence.name}',
        );
      }
    }

    _saveGeofences();
  }

  void _showAddGeofenceDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Geofence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Home, Office',
              ),
            ),
            TextField(
              controller: latController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Latitude'),
            ),
            TextField(
              controller: lngController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Longitude'),
            ),
            TextField(
              controller: radiusController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _geofences.add(Geofence(
                  name: nameController.text,
                  latitude: double.tryParse(latController.text) ?? 0,
                  longitude: double.tryParse(lngController.text) ?? 0,
                  radius: double.tryParse(radiusController.text) ?? 100,
                ));
                _saveGeofences();
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LocationHook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGeofenceDialog,
            tooltip: 'Add Geofence',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isTracking ? Icons.location_on : Icons.location_off,
                          color: _isTracking ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTracking ? null : _startTracking,
                            child: const Text('Start Tracking'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTracking ? _stopTracking : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Stop Tracking'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPosition != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(2)}m',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_currentPosition!.timestamp != null)
                        Text(
                          'Updated: ${DateTime.fromMillisecondsSinceEpoch(_currentPosition!.timestamp! * 1000).toString()}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Geofence Events',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 4),
                                Text('Entered: $_geofenceEnterCount'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.cancel, color: Colors.red),
                                const SizedBox(width: 4),
                                Text('Exited: $_geofenceExitCount'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Geofences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_geofences.isEmpty)
                      const Text('No geofences configured')
                    else
                      ..._geofences.map((geofence) => ListTile(
                            leading: Icon(
                              geofence.isInside ? Icons.place : Icons.map_outlined,
                              color: geofence.isInside ? Colors.green : Colors.grey,
                            ),
                            title: Text(geofence.name),
                            subtitle: Text(
                              'Lat: ${geofence.latitude.toStringAsFixed(4)}, '
                              'Lng: ${geofence.longitude.toStringAsFixed(4)}, '
                              'Radius: ${geofence.radius.toInt()}m',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _geofences.remove(geofence);
                                });
                                _saveGeofences();
                              },
                            ),
                          )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Geofence {
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  bool isInside;

  Geofence({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isInside = false,
  });

  static String encodeList(List<Geofence> geofences) {
    final json = geofences.map((g) => g.toJson()).toList();
    return '[${json.join(',')}]';
  }

  static List<Geofence> parseList(String json) {
    final geofences = <Geofence>[];
    
    final cleanJson = json.replaceAll('[', '').replaceAll(']', '');
    if (cleanJson.isEmpty) return geofences;

    final objects = cleanJson.split('},');
    for (final obj in objects) {
      final cleanObj = obj.replaceAll('{', '').replaceAll('}', '');
      final parts = cleanObj.split(',');
      
      String? name;
      double? lat;
      double? lng;
      double? radius;

      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('"name":')) {
          name = trimmed.split(':')[1].trim().replaceAll('"', '');
        } else if (trimmed.startsWith('"latitude":')) {
          lat = double.tryParse(trimmed.split(':')[1].trim());
        } else if (trimmed.startsWith('"longitude":')) {
          lng = double.tryParse(trimmed.split(':')[1].trim());
        } else if (trimmed.startsWith('"radius":')) {
          radius = double.tryParse(trimmed.split(':')[1].trim());
        }
      }

      if (name != null && lat != null && lng != null && radius != null) {
        geofences.add(Geofence(
          name: name!,
          latitude: lat!,
          longitude: lng!,
          radius: radius!,
        ));
      }
    }

    return geofences;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isInside': isInside,
    };
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;

  Future<void> initialize() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications!.initialize(initSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelShowBadge: false,
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications!.show(
      0,
      title,
      notificationDetails,
      payload: body,
    );
  }
}
