
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';

class PlacesService {
  static const String _overpassUrl =
      'https://overpass.kumi.systems/api/interpreter';

  Future<List<Place>> searchNearby({
    required double lat,
    required double lon,
    required List<PlaceCategory> categories,
    int radiusMeters = 1500,
  }) async {
    if (categories.isEmpty) return [];

    if (!lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      throw ArgumentError('Coordenadas inválidas.');
    }

    if (radiusMeters <= 0) {
      throw ArgumentError('El radio debe ser mayor que cero.');
    }

    final filters = categories.map((category) {
      final key = category.osmKey;
      final value = category.osmValue;

      return '''
        nwr["$key"="$value"](around:$radiusMeters,$lat,$lon);
      ''';
    }).join('\n');

    final query = '''
      [out:json][timeout:35];
      (
        $filters
      );
      out center;
    ''';

    final response = await http
        .post(
          Uri.parse(_overpassUrl),
          headers: {
            'Content-Type':
                'application/x-www-form-urlencoded; charset=UTF-8',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los lugares. '
        'Código: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta de Overpass no es válida.',
      );
    }

    final elements = decoded['elements'];

    if (elements is! List) {
      return [];
    }

    final places = <Place>[];
    final processedIds = <String>{};

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;

      final rawTags = element['tags'];

      if (rawTags is! Map) continue;

      final tags = Map<String, dynamic>.from(rawTags);

      if (_isInactive(tags)) continue;

      final name = tags['name']?.toString().trim() ?? '';

      if (name.isEmpty) continue;

      final placeLat = _coordinate(
        element['lat'] ?? (element['center'] as Map?)?['lat'],
      );

      final placeLon = _coordinate(
        element['lon'] ?? (element['center'] as Map?)?['lon'],
      );

      if (placeLat == null || placeLon == null) continue;

      final distance = Geolocator.distanceBetween(
        lat,
        lon,
        placeLat,
        placeLon,
      );

      if (distance > radiusMeters) continue;

      PlaceCategory? matchedCategory;

      for (final category in categories) {
        if (tags[category.osmKey]?.toString() ==
            category.osmValue) {
          matchedCategory = category;
          break;
        }
      }

      if (matchedCategory == null) continue;

      final type = element['type']?.toString() ?? 'node';
      final osmId = element['id']?.toString();

      if (osmId == null) continue;

      final uniqueId = 'osm_${type}_$osmId';

      if (!processedIds.add(uniqueId)) continue;

      final addressParts = [
        tags['addr:street'],
        tags['addr:housenumber'],
        tags['addr:city'],
      ]
          .where((value) =>
              value != null &&
              value.toString().trim().isNotEmpty)
          .map((value) => value.toString().trim())
          .toList();

      final address = addressParts.isEmpty
          ? null
          : addressParts.join(', ');

      final details = <String>[];

      final openingHours = tags['opening_hours'];
      final website = tags['website'] ?? tags['contact:website'];
      final phone = tags['phone'] ?? tags['contact:phone'];

      if (openingHours != null) {
        details.add('Horario: $openingHours');
      }

      if (phone != null) {
        details.add('Teléfono: $phone');
      }

      if (website != null) {
        details.add('Sitio web: $website');
      }

      places.add(
        Place(
          id: uniqueId,
          name: name,
          lat: placeLat,
          lon: placeLon,
          category: matchedCategory,
          address: address,
          description:
              details.isEmpty ? null : details.join('\n'),
        ),
      );
    }

    places.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        lat,
        lon,
        a.lat,
        a.lon,
      );

      final distanceB = Geolocator.distanceBetween(
        lat,
        lon,
        b.lat,
        b.lon,
      );

      return distanceA.compareTo(distanceB);
    });

    return places;
  }

  static double? _coordinate(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _isInactive(Map<String, dynamic> tags) {
    const inactiveValues = {
      'yes',
      'true',
      '1',
    };

    const inactivePrefixes = [
      'disused:',
      'abandoned:',
      'demolished:',
      'removed:',
      'razed:',
    ];

    for (final key in [
      'disused',
      'abandoned',
      'demolished',
      'removed',
      'razed',
    ]) {
      final value =
          tags[key]?.toString().trim().toLowerCase();

      if (inactiveValues.contains(value)) {
        return true;
      }
    }

    for (final key in tags.keys) {
      if (inactivePrefixes.any(key.startsWith)) {
        return true;
      }
    }

    final shop = tags['shop']?.toString().toLowerCase();

    if (shop == 'vacant' || shop == 'closed') {
      return true;
    }

    final openingHours =
        tags['opening_hours']?.toString().trim().toLowerCase();

    if (openingHours == 'closed' ||
        openingHours == 'off') {
      return true;
    }

    return false;
  }
}

