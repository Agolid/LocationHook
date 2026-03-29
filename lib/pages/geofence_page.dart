import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/geofence.dart';
import '../services/location_service.dart';

class GeofencePage extends StatefulWidget {
  final LocationService locationService;
  final LatLng? currentLocation;

  const GeofencePage({
    super.key,
    required this.locationService,
    this.currentLocation,
  });

  @override
  State<GeofencePage> createState() => _GeofencePageState();
}

class _GeofencePageState extends State<GeofencePage> {
  final MapController _mapController = MapController();
  StreamSubscription? _geofencesSub;

  // Drawing state
  bool _isDrawing = false;
  LatLng? _drawCenter;
  double _drawRadius = 100;
  bool _listExpanded = true;

  List<Geofence> get _fences => widget.locationService.geofences;

  @override
  void initState() {
    super.initState();
    _geofencesSub = widget.locationService.geofencesStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _geofencesSub?.cancel();
    super.dispose();
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthR = 6371000.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earthR * math.asin(math.sqrt(h));
  }

  double _deg2rad(double d) => d * math.pi / 180;

  void _onLongPress(TapPosition tapPos, LatLng point) {
    if (_isDrawing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDrawing = true;
      _drawCenter = point;
      _drawRadius = 100;
    });
  }

  void _onTapDuringDrawing(TapPosition tapPos, LatLng point) {
    if (!_isDrawing || _drawCenter == null) return;
    _drawRadius = _distanceMeters(_drawCenter!, point).clamp(20, 50000);
    setState(() {});
  }

  void _finishDrawing() {
    if (_drawCenter == null) return;
    _showNameDialog(_drawCenter!, _drawRadius);
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawing = false;
      _drawCenter = null;
    });
  }

  void _showNameDialog(LatLng center, double radius) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Geofence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Home, Office',
              ),
              onSubmitted: (_) => _saveFence(nameCtrl, center, radius, ctx),
            ),
            const SizedBox(height: 8),
            Text(
              'Radius: ${radius.toStringAsFixed(0)}m',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _saveFence(nameCtrl, center, radius, ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveFence(TextEditingController nameCtrl, LatLng center, double radius, BuildContext ctx) {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.locationService.addGeofence(Geofence(
      id: const Uuid().v4(),
      name: name,
      latitude: center.latitude,
      longitude: center.longitude,
      radiusMeters: radius,
    ));
    Navigator.pop(ctx);
    setState(() {
      _isDrawing = false;
      _drawCenter = null;
    });
  }

  void _deleteFence(Geofence fence) {
    widget.locationService.removeGeofence(fence.id);
    setState(() {});
  }

  void _showEditDialog(Geofence fence) {
    final nameCtrl = TextEditingController(text: fence.name);
    final radiusCtrl = TextEditingController(text: fence.radiusMeters.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${fence.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: radiusCtrl,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              widget.locationService.removeGeofence(fence.id);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () {
              widget.locationService.updateGeofence(fence.copyWith(
                name: nameCtrl.text.trim(),
                radiusMeters: double.tryParse(radiusCtrl.text) ?? fence.radiusMeters,
              ));
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofences'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isDrawing)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('How to create'),
                  content: const Text('1. Long press to set center\n2. Tap another point to set radius\n3. Tap ✓ to save'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.currentLocation ?? const LatLng(39.9, 116.4),
              initialZoom: 15,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onLongPress: _isDrawing ? null : _onLongPress,
              onTap: _isDrawing ? _onTapDuringDrawing : null,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.agolid.locationhook',
              ),
              CircleLayer(circles: _buildGeofenceCircles()),
              MarkerLayer(markers: _buildGeofenceMarkers()),
              // Drawing preview
              if (_isDrawing && _drawCenter != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _drawCenter!,
                    radius: _drawRadius,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ]),
              if (_isDrawing && _drawCenter != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _drawCenter!,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          // Drawing toolbar
          if (_isDrawing)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.blue.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_unchecked, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Radius: ${_drawRadius.toStringAsFixed(0)}m',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _cancelDrawing,
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _finishDrawing,
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
                        child: const Text('✓ Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom geofence list (collapsible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomList(),
          ),
        ],
      ),
    );
  }

  List<CircleMarker> _buildGeofenceCircles() {
    return _fences.map((f) => CircleMarker(
      point: LatLng(f.latitude, f.longitude),
      radius: f.radiusMeters,
      useRadiusInMeter: true,
      color: (f.isInside ? Colors.green : Colors.orange).withOpacity(0.12),
      borderColor: f.isInside ? Colors.green : Colors.orange,
      borderStrokeWidth: 2,
    )).toList();
  }

  List<Marker> _buildGeofenceMarkers() {
    return _fences.map((f) => Marker(
      point: LatLng(f.latitude, f.longitude),
      width: 24,
      height: 24,
      child: GestureDetector(
        onTap: () => _showEditDialog(f),
        child: Icon(
          f.isInside ? Icons.check_circle : Icons.place,
          color: f.isInside ? Colors.green : Colors.orange,
          size: 24,
        ),
      ),
    )).toList();
  }

  Widget _buildBottomList() {
    if (_fences.isEmpty && !_isDrawing) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: const Center(
          child: Text('Long press the map to create a geofence', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: _listExpanded ? 220 : 52,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _listExpanded = !_listExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('Geofences', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('(${_fences.length})', style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  Icon(_listExpanded ? Icons.expand_more : Icons.expand_less),
                ],
              ),
            ),
          ),
          if (_listExpanded)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _fences.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final f = _fences[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      f.isInside ? Icons.check_circle : Icons.place,
                      color: f.isInside ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    title: Text(f.name, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('r=${f.radiusMeters.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteFence(f),
                    ),
                    onTap: () => _showEditDialog(f),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
