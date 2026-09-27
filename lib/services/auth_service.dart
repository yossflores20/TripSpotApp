import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Registro/login/edición de perfil SIN servicios externos: los usuarios
/// se guardan localmente en el teléfono (SharedPreferences), como una
/// lista de JSON. La contraseña nunca se guarda en texto plano (se
/// guarda su hash SHA-256).
///
/// El PRIMER usuario que se registra en el dispositivo se vuelve
/// administrador automáticamente (así se puede probar el panel de admin
/// sin necesitar un backend: cuenta 1 = admin, las demás = usuarios
/// normales).
class AuthService {
  static const _usersKey = 'tripspot_users';
  static const _sessionKey = 'tripspot_session_email';

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  Future<List<AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  /// Lista completa de usuarios registrados en este dispositivo (para el
  /// panel de administrador).
  Future<List<AppUser>> getAllUsers() => _loadUsers();

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    if (users.any((u) => u.email == normalizedEmail)) {
      throw Exception('Ya existe una cuenta con ese correo.');
    }
    final newUser = AppUser(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hash(password),
      isAdmin: users.isEmpty, // el primero en registrarse es el admin
    );
    users.add(newUser);
    await _saveUsers(users);
    // A propósito NO iniciamos sesión: el usuario vuelve al login.
    return newUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final users = await _loadUsers();
    final normalizedEmail = email.trim().toLowerCase();
    final hash = _hash(password);
    final match = users.where(
      (u) => u.email == normalizedEmail && u.passwordHash == hash,
    );
    if (match.isEmpty) throw Exception('Correo o contraseña incorrectos.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, normalizedEmail);
    return match.first;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    final users = await _loadUsers();
    final match = users.where((u) => u.email == email);
    return match.isEmpty ? null : match.first;
  }

  Future<AppUser> updateProfile({
    required String currentEmail,
    String? newEmail,
    String? newPassword,
  }) async {
    final users = await _loadUsers();
    final idx = users.indexWhere((u) => u.email == currentEmail);
    if (idx == -1) throw Exception('Usuario no encontrado.');

    final normalizedNewEmail = newEmail?.trim().toLowerCase();
    if (normalizedNewEmail != null &&
        normalizedNewEmail != currentEmail &&
        users.any((u) => u.email == normalizedNewEmail)) {
      throw Exception('Ese correo ya está en uso por otra cuenta.');
    }

    final updated = users[idx].copyWith(
      email: normalizedNewEmail,
      passwordHash: newPassword != null ? _hash(newPassword) : null,
    );
    users[idx] = updated;
    await _saveUsers(users);

    if (normalizedNewEmail != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, normalizedNewEmail);
    }
    return updated;
  }
}
