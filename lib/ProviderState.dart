import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProviderState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? _selectedUniversity;
  String? _errorMessage;

  // Nuevo: Variable para guardar los datos del usuario en memoria
  Map<String, dynamic>? _userProfile;

  final List<String> _allowedDomains = [
    'uexternado.edu.co',
    'urosario.edu.co',
    'javeriana.edu.co',
    'uniandes.edu.co',
  ];

  String? get selectedUniversity => _selectedUniversity;
  String? get errorMessage => _errorMessage;
  // Nuevo: Getter del perfil
  Map<String, dynamic>? get userProfile => _userProfile;

  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    notifyListeners();
  }

  bool validateEmailDomain(String email) {
    final lowerEmail = email.toLowerCase().trim();
    return _allowedDomains.any((domain) => lowerEmail.endsWith(domain));
  }

  // --- NUEVA FUNCIÓN: Cargar perfil desde DB ---
  Future<void> loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db.child('users/$uid/profile').get();
      if (snapshot.exists) {
        // Convertimos la data a un Map manejable
        _userProfile = Map<String, dynamic>.from(snapshot.value as Map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    }
  }

  Future<bool> registerUser({
    required String nombre,
    required String correo,
    required String usuario,
    required String password,
    required String celular,
  }) async {
    _errorMessage = null;
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password.trim(),
      );

      final String uid = userCredential.user!.uid;

      // Guardamos en DB
      final profileData = {
        'fullName': nombre,
        'email': correo.trim(),
        'username': usuario.trim(),
        'university': _selectedUniversity ?? 'Desconocida',
        'phone': celular.trim(),
        'rating': 5.0,
        'completedTrips': 0,
      };

      await _db.child('users/$uid/profile').set(profileData);

      // Cargamos los datos en memoria de una vez
      _userProfile = profileData;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _errorMessage = 'La contraseña es muy debil.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'Este correo ya está registrado.';
      } else {
        _errorMessage = 'Error de autenticación: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginUser({
    required String usuario,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      if (!usuario.contains('@')) {
        _errorMessage = "Por favor ingresa tu correo institucional completo.";
        notifyListeners();
        return false;
      }

      await _auth.signInWithEmailAndPassword(
        email: usuario.trim(),
        password: password.trim(),
      );

      // Cargamos el perfil al hacer login exitoso
      await loadUserProfile();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'Usuario no encontrado.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Contraseña incorrecta.';
      } else {
        _errorMessage = 'Error al ingresar.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null;
    _userProfile = null; // Limpiamos datos
    notifyListeners();
  }
}