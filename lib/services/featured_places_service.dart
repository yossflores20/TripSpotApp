import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

/// Lugares destacados que el administrador cura y que ven todos los
/// usuarios de este dispositivo (guardado local, sin backend por ahora).
class FeaturedPlacesService {
  static const _key = 'tripspot_featured_places';

  Future<List<Place>> getFeatured() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(places.map((p) => p.toJson()).toList()));
  }

  Future<List<Place>> add(Place place) async {
    final current = await getFeatured();
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
