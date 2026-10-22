import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _sessionPreferenceKey =
      'tripspot_keep_session';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // COMPROBAR SI DEBEMOS CONSERVAR LA SESIÓN
  Future<void> _bootstrap() async {
    try {
      final preferences =
          await SharedPreferences.getInstance();

      final keepSession =
          preferences.getBool(_sessionPreferenceKey) ?? false;

      // SI NO SE SELECCIONÓ MANTENER SESIÓN,
      // CERRAMOS LA SESIÓN GUARDADA POR FIREBASE.
      if (!keepSession) {
        await AppServices.instance.auth.logout();

        if (!mounted) return;

        _goToLogin();
        return;
      }

      // SI SE SELECCIONÓ MANTENER SESIÓN,
      // RECUPERAMOS EL PERFIL DEL USUARIO.
      final user =
          await AppServices.instance.auth.currentUser();

      if (!mounted) return;

      // NO EXISTE UNA SESIÓN VÁLIDA.
      if (user == null) {
        await AppServices.instance.auth.logout();

        if (!mounted) return;

        _goToLogin();
        return;
      }

      // REDIRECCIÓN SEGÚN EL ROL
      if (user.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdminHomeScreen(
              onChanged: () {},
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      // SI OCURRE UN ERROR, NO PERMITIMOS EL
      // ACCESO AUTOMÁTICO SIN VERIFICAR EL PERFIL.
      if (!mounted) return;

      _goToLogin();
    }
  }

  // NAVEGAR A LA PANTALLA DE INICIO DE SESIÓN
  void _goToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 69, 58, 185),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore,
              size: 72,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'TripSpot',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
