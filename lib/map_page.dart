import 'package:flutter/material.dart';
import 'package:flutter_amap/flutter_amap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  AMapController? _mapController;
  LatLng? _currentLocation;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要位置权限才能使用地图功能')),
      );
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      final hasPermission = await Permission.locationWhenInUse.status.isGranted;
      if (!hasPermission) return;

      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _positionStreamSubscription = positionStream.listen((Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        if (_mapController != null) {
          _mapController!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation,
                zoom: 16,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Location tracking error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('位置钩子'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          AMapView(
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });

              if (_currentLocation != null) {
                controller.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentLocation,
                      zoom: 16,
                    ),
                  ),
                );
              }
            },
            onCameraMove: (cameraPosition) {
              debugPrint('Camera moved to: ${cameraPosition.target}');
            },
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            myLocationEnabled: true,
            myLocationStyleOptions: const MyLocationStyleOptions(
              myLocationIcon: MyLocationIcon.asset('assets/images/location_marker.png'),
            ),
            markers: _currentLocation != null
                ? [
                    Marker(
                      position: _currentLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    ),
                  ]
                : [],
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '当前位置',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '纬度: ${_currentLocation!.latitude.toStringAsFixed(6)}'),
                      Text(
                        '经度: ${_currentLocation!.longitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('添加钩子'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
