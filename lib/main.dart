import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/places_service.dart';
import 'services/favorites_service.dart';
import 'services/featured_places_service.dart';
import 'screens/login_screen.dart';

class AppServices {
  AppServices._();
  static final AppServices instance = AppServices._();

  final AuthService auth = AuthService();
  final LocationService location = LocationService();
  final PlacesService places = PlacesService();
  final FavoritesService favorites = FavoritesService();
  final FeaturedPlacesService featuredPlaces = FeaturedPlacesService();
}

void main() {
  runApp(const TripSpotApp());
}

class TripSpotApp extends StatelessWidget {
  const TripSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromARGB(255, 47, 58, 148),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}
