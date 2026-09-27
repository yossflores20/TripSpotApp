import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

/// Favoritos guardados localmente, por dispositivo (no por usuario) —
/// suficiente mientras no haya backend en la nube.
class FavoritesService {
  static const _key = 'tripspot_favorites';

  Future<List<Place>> getFavorites() async {
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
    final current = await getFavorites();
    if (!current.any((p) => p.id == place.id)) {
      current.add(place);
      await _save(current);
    }
    return current;
  }

  Future<List<Place>> remove(String placeId) async {
    final current = await getFavorites();
    current.removeWhere((p) => p.id == placeId);
    await _save(current);
    return current;
  }
}
