
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/user.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;

  bool _loading = true;
  bool _loggingOut = false;

  static const String _sessionPreferenceKey =
      'tripspot_keep_session';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // CARGAR DATOS DEL USUARIO
  Future<void> _load() async {
    try {
      final user =
          await AppServices.instance.auth.currentUser();

      if (!mounted) return;

      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'No se pudo cargar el perfil.',
        isError: true,
      );
    }
  }

  // MOSTRAR MENSAJES
  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // CONFIRMAR CIERRE DE SESIÓN
  Future<void> _confirmLogout() async {
    if (_loggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Estás seguro de que deseas cerrar '
            'tu sesión en TripSpot?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) return;

    await _logout();
  }

  // CERRAR SESIÓN
  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      // Cerrar sesión de Firebase y Google.
      await AppServices.instance.auth.logout();

      // Desactivar la preferencia de sesión.
      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setBool(
        _sessionPreferenceKey,
        false,
      );

      if (!mounted) return;

      // Eliminar las pantallas anteriores.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );

      // Mostrar confirmación en el nuevo login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTripSpotMessage(
          'Has cerrado sesión correctamente.',
        );
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'No se pudo cerrar la sesión. '
        'Inténtalo nuevamente.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
        });
      }
    }
  }

  // EDITAR PERFIL
  Future<void> _editProfile() async {
    if (_user == null || _loggingOut) return;

    final emailCtrl = TextEditingController(
      text: _user!.email,
    );

    final passCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Ingresa un correo';
                      }

                      final regex = RegExp(
                        r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                      );

                      if (!regex.hasMatch(value.trim())) {
                        return 'Correo electrónico inválido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText:
                          'Nueva contraseña (opcional)',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                      ),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      emailCtrl.dispose();
      passCtrl.dispose();
      return;
    }

    if (result != true) {
      emailCtrl.dispose();
      passCtrl.dispose();
      return;
    }

    final newEmail = emailCtrl.text.trim();
    final newPassword = passCtrl.text;

    emailCtrl.dispose();
    passCtrl.dispose();

    try {
      final updated =
          await AppServices.instance.auth.updateProfile(
        currentEmail: _user!.email,
        newEmail: newEmail,
        newPassword:
            newPassword.isEmpty ? null : newPassword,
      );

      if (!mounted) return;

      setState(() {
        _user = updated;
      });

      _showMessage(
        'Solicitud de actualización procesada. '
        'Si cambiaste el correo, revisa tu bandeja '
        'para confirmar el cambio.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // INFORMACIÓN DEL USUARIO
        Row(
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(
                Icons.person,
                size: 32,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _user?.name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (_user?.isAdmin == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text('Administrador'),
                        visualDensity:
                            VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // EDITAR PERFIL
        OutlinedButton.icon(
          onPressed:
              _user == null || _loggingOut
                  ? null
                  : _editProfile,
          icon: const Icon(Icons.edit),
          label: const Text(
            'Editar correo / contraseña',
          ),
        ),

        const SizedBox(height: 12),

        // CERRAR SESIÓN
        OutlinedButton.icon(
          onPressed:
              _loggingOut ? null : _confirmLogout,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          icon: _loggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.logout),
          label: Text(
            _loggingOut
                ? 'Cerrando sesión...'
                : 'Cerrar sesión',
          ),
        ),
      ],
    );
  }
}

