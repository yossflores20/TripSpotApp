import 'package:flutter/material.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return regex.hasMatch(email.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppServices.instance.auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(
                'Exception: ',
                '',
              );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Completa tus datos para comenzar a explorar TripSpot.',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 94, 94, 94),
                  ),
                ),

                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }

                    if (value.trim().length < 3) {
                      return 'Ingresa un nombre válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Correo
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType:
                      TextInputType.emailAddress,
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

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                    ),
                    border: OutlineInputBorder(),
                    helperText:
                        'Utiliza al menos 8 caracteres',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }

                    if (value.length < 8) {
                      return 'La contraseña debe tener mínimo 8 caracteres';
                    }

                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                FilledButton(
                  onPressed:
                      _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(48),
                    backgroundColor:
                        const Color.fromARGB(
                      255,
                      43,
                      47,
                      135,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Registrarse',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
