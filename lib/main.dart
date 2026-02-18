import 'package:flutter/material.dart';
import 'package:flutter_amap/flutter_amap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}
