import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class MapScreen extends StatelessWidget {
  final Position? position;
  final List<Place> places;

  const MapScreen({super.key, required this.position, required this.places});

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return const Center(child: Text('Obteniendo tu ubicación real…'));
    }

    final center = LatLng(position!.latitude, position!.longitude);

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 15),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tripspot.cloud',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location, color: Colors.blue, size: 34),
            ),
            ...places.map(
              (p) => Marker(
                point: LatLng(p.lat, p.lon),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  color: p.isFeatured ? Colors.amber : const Color(0xFF3AA6B9),
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
