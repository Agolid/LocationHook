import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const LocationHookApp());
}

class LocationHookApp extends StatelessWidget {
  const LocationHookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocationHook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationMessage = '获取位置中...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() {
        _locationMessage = '位置权限被拒绝';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _locationMessage =
            '纬度: ${position.latitude}, 经度: ${position.longitude}';
      });
    } catch (e) {
      setState(() {
        _locationMessage = '获取位置失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LocationHook'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              Text(
                _locationMessage,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_currentPosition != null)
                Column(
                  children: [
                    Text('精度: ${_currentPosition!.accuracy}米'),
                    Text('海拔: ${_currentPosition!.altitude}米'),
                    Text('速度: ${_currentPosition!.speed}m/s'),
                  ],
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('刷新位置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
