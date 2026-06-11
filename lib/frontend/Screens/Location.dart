import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выбор места"),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(58.6036, 49.6680), // Киров
          initialZoom: 12,
          onTap: (tapPosition, point) {
            setState(() {
              selectedPoint = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),

          if (selectedPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedPoint!,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectedPoint == null
            ? null
            : () => Navigator.pop(context, selectedPoint),
        child: const Icon(Icons.check),
      ),
    );
  }
}