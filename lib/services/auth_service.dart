import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';


class AuthService {
  static const _usersKey = 'tripspot_users';
  static const _sessionKey = 'tripspot_session_email';

  String _hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return regex.hasMatch(email.trim());
  }

  Future<List<AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);

    if (raw == null) {
      return [];
    }

    final list = jsonDecode(raw) as List<dynamic>;

    return list
        .map(
          (e) => AppUser.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _usersKey,
      jsonEncode(
        users.map((u) => u.toJson()).toList(),
      ),
    );
  }

Future<void> ensureAdmin({
  required String name,
  required String email,
  required String password,
}) async {
  final users = await _loadUsers();
  final normalizedEmail = email.trim().toLowerCase();

  final index = users.indexWhere(
    (u) => u.email == normalizedEmail,
  );

  final admin = AppUser(
    name: name.trim(),
    email: normalizedEmail,
    passwordHash: _hash(password),
    isAdmin: true,
  );

  if (index >= 0) {
    users[index] = admin;
  } else {
    users.add(admin);
  }

  await _saveUsers(users);
}

  /// Devuelve los usuarios registrados.
  /// Se utiliza en el panel administrativo.
  Future<List<AppUser>> getAllUsers() {
    return _loadUsers();
  }

  /// Registra un usuario normal.
  ///
  /// El registro público nunca puede crear administradores.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.length < 3) {
      throw Exception(
        'Ingresa un nombre válido.',
      );
    }

    if (!_isValidEmail(normalizedEmail)) {
      throw Exception(
        'Ingresa un correo electrónico válido.',
      );
    }

    if (password.length < 8) {
      throw Exception(
        'La contraseña debe tener mínimo 8 caracteres.',
      );
    }

    if (users.any(
      (u) => u.email == normalizedEmail,
    )) {
      throw Exception(
        'Ya existe una cuenta con ese correo.',
      );
    }

    final newUser = AppUser(
      name: normalizedName,
      email: normalizedEmail,
      passwordHash: _hash(password),

      // Todo registro público es usuario normal.
      isAdmin: false,
    );

    users.add(newUser);

    await _saveUsers(users);

    // No iniciamos sesión automáticamente.
    // El usuario debe regresar al Login.
    return newUser;
  }

  /// Inicia sesión y devuelve el usuario autenticado.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();

    final normalizedEmail =
        email.trim().toLowerCase();

    if (!_isValidEmail(normalizedEmail)) {
      throw Exception(
        'Correo electrónico inválido.',
      );
    }

    if (password.length < 8) {
      throw Exception(
        'La contraseña debe tener mínimo 8 caracteres.',
      );
    }

    final passwordHash = _hash(password);

    final match = users.where(
      (u) =>
          u.email == normalizedEmail &&
          u.passwordHash == passwordHash,
    );

    if (match.isEmpty) {
      throw Exception(
        'Correo o contraseña incorrectos.',
      );
    }

    final user = match.first;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _sessionKey,
      normalizedEmail,
    );

    return user;
  }

  /// Cierra la sesión actual.
  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_sessionKey);
  }

  /// Obtiene el usuario que inició sesión.
  Future<AppUser?> currentUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    final email =
        prefs.getString(_sessionKey);

    if (email == null) {
      return null;
    }

    final users = await _loadUsers();

    final match = users.where(
      (u) => u.email == email,
    );

    return match.isEmpty
        ? null
        : match.first;
  }

  /// Permite actualizar correo y/o contraseña.
  Future<AppUser> updateProfile({
    required String currentEmail,
    String? newEmail,
    String? newPassword,
  }) async {
    final users = await _loadUsers();

    final idx = users.indexWhere(
      (u) => u.email == currentEmail,
    );

    if (idx == -1) {
      throw Exception(
        'Usuario no encontrado.',
      );
    }

    String? normalizedNewEmail;

    if (newEmail != null &&
        newEmail.trim().isNotEmpty) {
      normalizedNewEmail =
          newEmail.trim().toLowerCase();

      if (!_isValidEmail(
        normalizedNewEmail,
      )) {
        throw Exception(
          'Ingresa un correo electrónico válido.',
        );
      }

      if (normalizedNewEmail !=
              currentEmail &&
          users.any(
            (u) =>
                u.email ==
                normalizedNewEmail,
          )) {
        throw Exception(
          'Ese correo ya está en uso por otra cuenta.',
        );
      }
    }

    if (newPassword != null &&
        newPassword.isNotEmpty &&
        newPassword.length < 8) {
      throw Exception(
        'La contraseña debe tener mínimo 8 caracteres.',
      );
    }

    final updated =
        users[idx].copyWith(
      email: normalizedNewEmail,
      passwordHash:
          newPassword != null &&
                  newPassword.isNotEmpty
              ? _hash(newPassword)
              : null,
    );

    users[idx] = updated;

    await _saveUsers(users);

    if (normalizedNewEmail != null) {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _sessionKey,
        normalizedNewEmail,
      );
    }

    return updated;
  }
}