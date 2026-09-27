import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const PlaceDetailScreen({
    super.key,
    required this.place,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(place.lat, place.lon),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tripspot.cloud',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(place.lat, place.lon),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Color(0xFF3AA6B9), size: 36),
                  ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${place.category.emoji} ${place.category.label}',
                        style: const TextStyle(fontSize: 16)),
                    if (place.isFeatured) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('Destacado'),
                        avatar: Icon(Icons.verified, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (place.address?.isNotEmpty == true)
                  Text(place.address!,
                      style: TextStyle(color: Colors.grey.shade700)),
                if (place.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(place.description!,
                      style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
