enum PlaceCategory {
  restaurante('amenity', 'restaurant', 'Restaurantes', '🍽️'),
  cafeteria('amenity', 'cafe', 'Cafeterías', '☕'),
  paleteria('shop', 'ice_cream', 'Paleterías', '🍦'),
  parque('leisure', 'park', 'Parques', '🌳'),
  plaza('shop', 'mall', 'Plazas', '🏬'),
  monumento('historic', 'monument', 'Monumentos', '🗿'),
  turistico('tourism', 'attraction', 'Sitios turísticos', '📸');

  final String osmKey;
  final String osmValue;
  final String label;
  final String emoji;

  const PlaceCategory(this.osmKey, this.osmValue, this.label, this.emoji);
}

class Place {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final PlaceCategory category;
  final String? address;
  final String? description;
  final bool isFeatured;

  Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.category,
    this.address,
    this.description,
    this.isFeatured = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'category': category.name,
        'address': address,
        'description': description,
        'isFeatured': isFeatured,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        category: PlaceCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => PlaceCategory.turistico,
        ),
        address: json['address'] as String?,
        description: json['description'] as String?,
        isFeatured: json['isFeatured'] as bool? ?? false,
      );
}
