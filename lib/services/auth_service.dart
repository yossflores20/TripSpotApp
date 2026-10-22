import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitialization;

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    return regex.hasMatch(email.trim());
  }

  AppUser _userFromData(Map<String, dynamic> data) {
    return AppUser(
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      passwordHash: '',
      isAdmin: data['role'] == 'admin',
    );
  }

  Future<void> _initializeGoogle() {
    return _googleInitialization ??=
        _googleSignIn.initialize();
  }

  Future<AppUser> _getExistingProfile(User firebaseUser) async {
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
  }

  // REGISTRAR USUARIO CON CORREO Y CONTRASEÑA
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

    User? createdUser;

    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      await _firestore
          .collection('users')
          .doc(createdUser.uid)
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

      await _auth.signOut();
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    } on FirebaseException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      await _auth.signOut();

      throw Exception(
        e.message ?? 'No se pudieron guardar los datos.',
      );
    }
  }

  // INICIAR SESIÓN CON CORREO Y CONTRASEÑA
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

      try {
        return await _getExistingProfile(firebaseUser);
      } catch (_) {
        await _auth.signOut();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    }
  }

  // INICIAR SESIÓN CON GOOGLE
  Future<AppUser?> signInWithGoogle() async {
    try {
      await _initializeGoogle();

      // Google Sign-In 7.x
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google Sign-In no está disponible '
          'en esta plataforma.',
        );
      }

      GoogleSignInAccount googleAccount;

      try {
        googleAccount = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        rethrow;
      }

      final googleAuthentication =
          googleAccount.authentication;

      final idToken = googleAuthentication.idToken;

      if (idToken == null) {
        throw Exception(
          'Google no proporcionó un token válido.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final result =
          await _auth.signInWithCredential(credential);

      final firebaseUser = result.user;

      if (firebaseUser == null) {
        throw Exception(
          'No se pudo iniciar sesión con Google.',
        );
      }

      final documentReference = _firestore
          .collection('users')
          .doc(firebaseUser.uid);

      // Si ya existe el perfil, respetamos su rol.
      final document = await documentReference.get();

      if (document.exists && document.data() != null) {
        return _userFromData(document.data()!);
      }

      // Solo se crea un perfil si es una cuenta
      // realmente nueva en Firebase Authentication.
      if (result.additionalUserInfo?.isNewUser != true) {
        await logout();
        throw Exception(
          'La cuenta no tiene un perfil de TripSpot. '
          'Contacta al administrador.',
        );
      }

      final name = (firebaseUser.displayName ?? '').trim();
      final email =
          (firebaseUser.email ?? '').trim().toLowerCase();

      if (email.isEmpty) {
        await logout();
        throw Exception(
          'No se pudo obtener el correo de Google.',
        );
      }

      // La transacción evita sobrescribir un perfil
      // creado simultáneamente.
      await _firestore.runTransaction((transaction) async {
        final existing =
            await transaction.get(documentReference);

        if (!existing.exists) {
          transaction.set(documentReference, {
            'name': name.isEmpty ? 'Usuario TripSpot' : name,
            'email': email,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return await _getExistingProfile(firebaseUser);
    } on GoogleSignInException catch (e) {
      throw Exception(
        'No se pudo iniciar sesión con Google: '
        '${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    }
  }

  // RECUPERAR CONTRASEÑA
  Future<void> resetPassword({
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_isValidEmail(normalizedEmail)) {
      throw Exception(
        'Ingresa un correo electrónico válido.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: normalizedEmail,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    }
  }

  // CERRAR SESIÓN
  Future<void> logout() async {
    await _auth.signOut();

    try {
      await _initializeGoogle();
      await _googleSignIn.signOut();
    } catch (_) {
      // La sesión de Firebase ya se cerró.
    }
  }

  // USUARIO ACTUAL
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

  // ACTUALIZAR PERFIL
  Future<AppUser> updateProfile({
    required String currentEmail,
    String? newEmail,
    String? newPassword,
  }) async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No hay una sesión iniciada.');
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

      return await _getExistingProfile(firebaseUser);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Por seguridad, vuelve a iniciar sesión '
          'antes de cambiar tus datos.',
        );
      }

      throw Exception(_authErrorMessage(e));
    }
  }

  // OBTENER TODOS LOS USUARIOS
  Future<List<AppUser>> getAllUsers() async {
    final snapshot =
        await _firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => _userFromData(doc.data()))
        .toList();
  }

  // MENSAJES DE ERROR DE FIREBASE
  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';

      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'weak-password':
        return 'La contraseña es demasiado débil.';

      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';

      case 'network-request-failed':
        return 'No se pudo conectar con Firebase. '
            'Revisa tu conexión a internet.';

      case 'requires-recent-login':
        return 'Vuelve a iniciar sesión por seguridad.';

      case 'account-exists-with-different-credential':
        return 'Este correo ya está asociado a otro '
            'método de inicio de sesión.';

      default:
        return e.message ??
            'Ocurrió un error de autenticación.';
    }
  }
}
