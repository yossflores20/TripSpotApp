import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';

class MapScreen extends StatelessWidget {
  final Position? position;
  final List<Place> places;

  const MapScreen({
    super.key,
    required this.position,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obteniendo tu ubicación actual...'),
          ],
        ),
      );
    }

    final center = LatLng(
      position!.latitude,
      position!.longitude,
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tripspot.cloud',
        ),

        MarkerLayer(
          markers: [
            // Ubicación actual del usuario
            Marker(
              point: center,
              width: 50,
              height: 50,
              child: Tooltip(
                message: 'Mi ubicación actual',
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 35,
                ),
              ),
            ),

            // Marcadores de lugares cercanos
            ...places.map(
              (place) => Marker(
                point: LatLng(
                  place.lat,
                  place.lon,
                ),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    _showPlaceInfo(context, place);
                  },
                  child: Icon(
                    place.isFeatured
                        ? Icons.star
                        : Icons.location_on,
                    color: place.isFeatured
                        ? Colors.amber
                        : const Color(0xFF3AA6B9),
                    size: 38,
                  ),
                ),
              ),
            ),
          ],
        ),

        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }

  void _showPlaceInfo(
    BuildContext context,
    Place place,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '${place.category.emoji} '
                  '${place.category.label}',
                ),

                if (place.isFeatured) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '⭐ Lugar destacado',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                if (place.address != null &&
                    place.address!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '📍 ${place.address}',
                  ),
                ],

                if (place.description != null &&
                    place.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(place.description!),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

