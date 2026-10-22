import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

class FeaturedPlacesService {
  static const _key = 'tripspot_featured_places';
  Future<List<Place>> getFeatured() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(places.map((p) => p.toJson()).toList()),
    );
  }

  
String _normalizeName(String? name) {
  return (name ?? '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
}


  bool _isDuplicate(Place existing, Place newPlace) {
    return _normalizeName(existing.name) ==
            _normalizeName(newPlace.name) &&
        _normalizeName(existing.description) ==
            _normalizeName(newPlace.description);
  }

  Future<List<Place>> add(Place place) async {
    final current = await getFeatured();
    final alreadyExists = current.any(
      (existing) => _isDuplicate(existing, place),
    );

    if (alreadyExists) {
      throw StateError(
        'Este lugar ya se encuentra registrado.',
      );
    }

    current.add(place);
    await _save(current);
    return current;
  }

  Future<List<Place>> remove(String placeId) async {
    final current = await getFeatured();
    current.removeWhere((p) => p.id == placeId);
    await _save(current);
    return current;
  }
}
