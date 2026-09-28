import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return regex.hasMatch(email.trim());
  }

  /// Convierte un documento de Firestore en AppUser.
  AppUser _userFromData(Map<String, dynamic> data) {
    return AppUser(
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      passwordHash: '',
      isAdmin: data['role'] == 'admin',
    );
  }

  /// Registra un usuario normal.
  ///
  /// Todos los usuarios creados desde la pantalla de registro
  /// tendrán el rol "user".
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.length < 3) {
      throw Exception('Ingresa un nombre válido.');
    }

    if (!_isValidEmail(normalizedEmail)) {
      throw Exception('Ingresa un correo electrónico válido.');
    }

    if (password.length < 8) {
      throw Exception(
        'La contraseña debe tener mínimo 8 caracteres.',
      );
    }

    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      // Guardamos únicamente información del perfil.
      // La contraseña NO se guarda en Firestore.
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'name': normalizedName,
        'email': normalizedEmail,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newUser = AppUser(
        name: normalizedName,
        email: normalizedEmail,
        passwordHash: '',
        isAdmin: false,
      );

      // Firebase inicia sesión automáticamente después
      // del registro. La cerramos porque queremos que
      // TripSpot regrese al Login.
      await _auth.signOut();

      return newUser;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'Ya existe una cuenta con ese correo.',
          );

        case 'invalid-email':
          throw Exception(
            'El correo electrónico no es válido.',
          );

        case 'weak-password':
          throw Exception(
            'La contraseña es demasiado débil.',
          );

        case 'network-request-failed':
          throw Exception(
            'No se pudo conectar con Firebase. Revisa tu conexión a internet.',
          );

        default:
          throw Exception(
            e.message ?? 'No se pudo crear la cuenta.',
          );
      }
    } on FirebaseException catch (e) {
      // Si Authentication creó la cuenta pero Firestore falló,
      // intentamos eliminar esa cuenta para evitar un registro
      // incompleto.
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }

      await _auth.signOut();

      throw Exception(
        e.message ?? 'No se pudieron guardar los datos del usuario.',
      );
    }
  }

  /// Inicia sesión con Firebase Authentication.
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_isValidEmail(normalizedEmail)) {
      throw Exception('Correo electrónico inválido.');
    }

    if (password.length < 8) {
      throw Exception(
        'La contraseña debe tener mínimo 8 caracteres.',
      );
    }

    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      final document = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!document.exists || document.data() == null) {
        await _auth.signOut();

        throw Exception(
          'No se encontró el perfil del usuario.',
        );
      }

      return _userFromData(document.data()!);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          throw Exception(
            'Correo o contraseña incorrectos.',
          );

        case 'invalid-email':
          throw Exception(
            'Correo electrónico inválido.',
          );

        case 'user-disabled':
          throw Exception(
            'Esta cuenta ha sido deshabilitada.',
          );

        case 'network-request-failed':
          throw Exception(
            'No se pudo conectar con Firebase. Revisa tu conexión a internet.',
          );

        default:
          throw Exception(
            e.message ?? 'No se pudo iniciar sesión.',
          );
      }
    }
  }

  /// Cierra la sesión actual.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Obtiene el usuario autenticado actualmente.
  Future<AppUser?> currentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final document = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return _userFromData(document.data()!);
  }

  /// Actualiza el correo y/o contraseña del usuario.
  Future<AppUser> updateProfile({
    required String currentEmail,
    String? newEmail,
    String? newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      throw Exception(
        'No hay una sesión iniciada.',
      );
    }

    String? normalizedNewEmail;

    if (newEmail != null && newEmail.trim().isNotEmpty) {
      normalizedNewEmail =
          newEmail.trim().toLowerCase();

      if (!_isValidEmail(normalizedNewEmail)) {
        throw Exception(
          'Ingresa un correo electrónico válido.',
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

    try {
      // Firebase puede requerir una verificación antes
      // de aplicar un cambio de correo.
      if (normalizedNewEmail != null &&
          normalizedNewEmail != firebaseUser.email) {
        await firebaseUser.verifyBeforeUpdateEmail(
          normalizedNewEmail,
        );
      }

      if (newPassword != null &&
          newPassword.isNotEmpty) {
        await firebaseUser.updatePassword(newPassword);
      }

      final document = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!document.exists || document.data() == null) {
        throw Exception(
          'No se encontró el perfil del usuario.',
        );
      }

      return _userFromData(document.data()!);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Por seguridad, vuelve a iniciar sesión antes de cambiar tus datos.',
        );
      }

      if (e.code == 'email-already-in-use') {
        throw Exception(
          'Ese correo ya está en uso por otra cuenta.',
        );
      }

      throw Exception(
        e.message ?? 'No se pudo actualizar el perfil.',
      );
    }
  }

  /// Devuelve los usuarios registrados.
  ///
  /// Esta función será utilizada por el administrador.
  Future<List<AppUser>> getAllUsers() async {
    final snapshot =
        await _firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => _userFromData(doc.data()))
        .toList();
  }
}