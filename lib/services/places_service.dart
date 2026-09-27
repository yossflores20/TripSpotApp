import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class PlacesService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<Place>> searchNearby({
    required double lat,
    required double lon,
    required List<PlaceCategory> categories,
    int radiusMeters = 1500,
  }) async {
    final clauses = categories
        .map((c) =>
            'node["${c.osmKey}"="${c.osmValue}"](around:$radiusMeters,$lat,$lon);')
        .join('\n');

    final query = '''
[out:json][timeout:25];
(
$clauses
);
out center 60;
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'User-Agent': 'TripSpotApp/1.0 (proyecto escolar Flutter)',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': '*/*',
      },
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar lugares cercanos '
          '(HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>? ?? [];

    final places = <Place>[];
    for (final el in elements) {
      final map = el as Map<String, dynamic>;
      final tags = (map['tags'] as Map<String, dynamic>?) ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final category = categories.firstWhere(
        (c) => tags[c.osmKey] == c.osmValue,
        orElse: () => categories.first,
      );

      places.add(Place(
        id: '${map['type']}_${map['id']}',
        name: name,
        lat: (map['lat'] as num).toDouble(),
        lon: (map['lon'] as num).toDouble(),
        category: category,
        address: [
          tags['addr:street'],
          tags['addr:housenumber'],
        ].where((e) => e != null && e.toString().isNotEmpty).join(' '),
        description: _buildDescription(tags, category),
      ));
    }
    return places;
  }

  String _buildDescription(Map<String, dynamic> tags, PlaceCategory category) {
    final osmDescription = tags['description'] as String?;
    if (osmDescription != null && osmDescription.trim().isNotEmpty) {
      return osmDescription.trim();
    }
    final parts = <String>[];
    switch (category) {
      case PlaceCategory.restaurante:
        final cuisine = tags['cuisine'] as String?;
        parts.add(cuisine != null && cuisine.isNotEmpty
            ? 'Restaurante de comida ${cuisine.replaceAll('_', ' ')}.'
            : 'Restaurante cerca de tu ubicación.');
        break;
      case PlaceCategory.cafeteria:
        parts.add('Cafetería para tomar algo cerca de ti.');
        break;
      case PlaceCategory.paleteria:
        parts.add('Paletería / heladería cerca de ti.');
        break;
      case PlaceCategory.parque:
        parts.add('Parque o área verde para pasear o descansar.');
        break;
      case PlaceCategory.plaza:
        parts.add('Plaza o centro comercial cercano.');
        break;
      case PlaceCategory.monumento:
        parts.add('Monumento histórico de la zona.');
        break;
      case PlaceCategory.turistico:
        parts.add('Sitio turístico recomendado para visitar.');
        break;
        case PlaceCategory.evento:
        parts.add('!No te pierdas el siguiente evento mientras visitas ixmiquilpan!');
        break;
    }
    final openingHours = tags['opening_hours'] as String?;
    if (openingHours != null && openingHours.isNotEmpty) {
      parts.add('Horario: $openingHours.');
    }
    return parts.join(' ');
  }
}
