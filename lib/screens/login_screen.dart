
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/user.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _keepSession = false;

  String? _error;

  static const _sessionPreferenceKey =
      'tripspot_keep_session';

  static const _primaryColor =
      Color.fromARGB(255, 58, 64, 185);

  @override
  void initState() {
    super.initState();
    _loadSessionPreference();
  }

  // CARGAR PREFERENCIA DE SESIÓN
  Future<void> _loadSessionPreference() async {
    final preferences =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _keepSession =
          preferences.getBool(_sessionPreferenceKey) ?? false;
    });
  }

  // GUARDAR PREFERENCIA DE SESIÓN
  Future<void> _saveSessionPreference() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(
      _sessionPreferenceKey,
      _keepSession,
    );
  }

  // VALIDAR CORREO ELECTRÓNICO
  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return regex.hasMatch(email.trim());
  }

  // MOSTRAR MENSAJES
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // REDIRECCIÓN SEGÚN EL ROL
  void _navigateToHome(AppUser user) {
    if (!mounted) return;

    final destination = user.isAdmin
        ? AdminHomeScreen(onChanged: () {})
        : const HomeScreen();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
    );

    // Se muestra después de la navegación.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTripSpotMessage(
        '¡Bienvenido a TripSpot, ${user.name}! '
        'Has iniciado sesión correctamente.',
      );
    });
  }

  // INICIAR SESIÓN CON CORREO
  Future<void> _submit() async {
    if (_loading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AppServices.instance.auth.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await _saveSessionPreference();

      if (!mounted) return;

      _navigateToHome(user);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // INICIAR SESIÓN CON GOOGLE
  Future<void> _signInWithGoogle() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user =
          await AppServices.instance.auth.signInWithGoogle();

      // Si se cancela Google Sign-In, no navegamos.
      if (user == null) return;

      await _saveSessionPreference();

      if (!mounted) return;

      _navigateToHome(user);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // RECUPERAR CONTRASEÑA
  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(
      text: _emailCtrl.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Recuperar contraseña',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo electrónico '
                    'para recibir un enlace de '
                    'restablecimiento de contraseña.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                      ),
                      border: const OutlineInputBorder(),
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final enteredEmail =
                        emailController.text.trim();

                    if (!_isValidEmail(enteredEmail)) {
                      setDialogState(() {
                        dialogError =
                            'Ingresa un correo válido';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      enteredEmail,
                    );
                  },
                  child: const Text('Enviar enlace'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (!mounted || email == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppServices.instance.auth.resetPassword(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'Si el correo corresponde a una cuenta '
        'con contraseña, recibirás instrucciones '
        'para restablecerla.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 60),

                // TÍTULO PRINCIPAL
                const Text(
                  'Explora el mundo\nsin límites',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                // NOMBRE DE LA APLICACIÓN
                const Text(
                  'TripSpot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                // CORREO ELECTRÓNICO
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa tu correo electrónico';
                    }

                    if (!_isValidEmail(value)) {
                      return 'Ingresa un correo electrónico válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // CONTRASEÑA
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }

                    if (value.length < 8) {
                      return 'La contraseña debe tener mínimo 8 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // MANTENER SESIÓN INICIADA
                CheckboxListTile(
                  value: _keepSession,
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() {
                            _keepSession = value ?? false;
                          });
                        },
                  title: const Text(
                    'Mantener sesión iniciada',
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity:
                      ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: _primaryColor,
                ),

                // OLVIDÉ MI CONTRASEÑA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        _loading ? null : _forgotPassword,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                    ),
                  ),
                ),

                // MENSAJE DE ERROR
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // BOTÓN DE INICIO DE SESIÓN
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _primaryColor,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                        ),
                ),

                const SizedBox(height: 20),

                // SEPARADOR
                Row(
                  children: [
                    const Expanded(
                      child: Divider(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        'O continúa con',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BOTÓN GOOGLE SIGN-IN
                OutlinedButton.icon(
                  onPressed:
                      _loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    size: 24,
                  ),
                  label: const Text(
                    'Continuar con Google',
                  ),
                ),

                const SizedBox(height: 12),

                // BOTÓN DE REGISTRO
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final registered =
                              await Navigator.of(context)
                                  .push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RegisterScreen(),
                            ),
                          );

                          if (!context.mounted) return;

                          if (registered == true) {
                            _showMessage(
                              'Cuenta creada. '
                              'Ahora inicia sesión.',
                            );
                          }
                        },
                  child: const Text(
                    '¿No tienes cuenta? Registrarse',
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
