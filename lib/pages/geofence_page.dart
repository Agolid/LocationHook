import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final fences = widget.locationService.geofences;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofences'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: fences.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio_button_unchecked,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No geofences yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + to create one',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: fences.length,
              itemBuilder: (context, index) {
                final fence = fences[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      fence.isInside ? Icons.check_circle : Icons.place,
                      color: fence.isInside ? Colors.green : Colors.orange,
                    ),
                    title: Text(fence.name),
                    subtitle: Text(
                      'Radius: ${fence.radiusMeters.toStringAsFixed(0)}m\n'
                      'Enter: ${fence.enterCount} | Exit: ${fence.exitCount}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteFence(fence),
                    ),
                    onTap: () => _showEditDialog(fence),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController(
      text: widget.currentLocation?.latitude.toStringAsFixed(6) ?? '',
    );
    final lngCtrl = TextEditingController(
      text: widget.currentLocation?.longitude.toStringAsFixed(6) ?? '',
    );
    final radiusCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Geofence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Home, Office',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: radiusCtrl,
              decoration:
                  const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text);
              final lng = double.tryParse(lngCtrl.text);
              final radius = double.tryParse(radiusCtrl.text) ?? 100;
              final name = nameCtrl.text.trim();

              if (name.isEmpty || lat == null || lng == null) return;

              widget.locationService.addGeofence(Geofence(
                id: const Uuid().v4(),
                name: name,
                latitude: lat,
                longitude: lng,
                radiusMeters: radius,
              ));

              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Geofence fence) {
    final nameCtrl = TextEditingController(text: fence.name);
    final radiusCtrl =
        TextEditingController(text: fence.radiusMeters.toStringAsFixed(0));

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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final radius = double.tryParse(radiusCtrl.text) ?? fence.radiusMeters;
              widget.locationService.updateGeofence(fence.copyWith(
                name: nameCtrl.text.trim(),
                radiusMeters: radius,
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

  void _deleteFence(Geofence fence) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Geofence'),
        content: Text('Remove "${fence.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.locationService.removeGeofence(fence.id);
              Navigator.pop(ctx);
              setState(() {});
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
