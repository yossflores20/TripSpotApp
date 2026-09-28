import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/places_service.dart';
import 'services/favorites_service.dart';
import 'services/featured_places_service.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  final AuthService auth = AuthService();
  final LocationService location = LocationService();
  final PlacesService places = PlacesService();
  final FavoritesService favorites = FavoritesService();
  final FeaturedPlacesService featuredPlaces =
      FeaturedPlacesService();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TripSpotApp());
}

class TripSpotApp extends StatelessWidget {
  const TripSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(
      255,
      58,
      64,
      185,
    );

    return MaterialApp(
      title: 'TripSpot',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // TIPOGRAFÍA GLOBAL
        textTheme: GoogleFonts.poppinsTextTheme(),

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF6F7FB),

        // CAMPOS DE TEXTO
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),

        // BOTONES
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // APPBAR
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF6F7FB),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}