import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// --- MODELO DE VEHÍCULO ---
class VehicleModel {
  final String id;
  final String placa;
  final String modelo;
  final String color;

  VehicleModel({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.color,
  });

  factory VehicleModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VehicleModel(
      id: id,
      placa: map['placa'] ?? '',
      modelo: map['modelo'] ?? '',
      color: map['color'] ?? '',
    );
  }
}

// --- PROVIDER STATE ---
class ProviderState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // -- Variables de Estado --
  String? _selectedUniversity; // Aquí se guardará lo que venga de SelectUniversityPage
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  List<VehicleModel> _vehicles = [];

  // -- Dominios permitidos --
  final List<String> _allowedDomains = [
    'uexternado.edu.co',
    'urosario.edu.co',
    'javeriana.edu.co',
    'uniandes.edu.co',
  ];

  // -- Getters --
  String? get selectedUniversity => _selectedUniversity;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<VehicleModel> get vehicles => _vehicles;

  // -- Helpers --
  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    // Esto imprime en consola para que verifiques que está llegando el dato correcto
    debugPrint("Universidad seleccionada: $_selectedUniversity");
    notifyListeners();
  }

  bool validateEmailDomain(String email) {
    final lowerEmail = email.toLowerCase().trim();
    return _allowedDomains.any((domain) => lowerEmail.endsWith(domain));
  }

  // --- LÓGICA DE DATOS ---

  Future<void> loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db.child('users/$uid/profile').get();
      if (snapshot.exists) {
        _userProfile = Map<String, dynamic>.from(snapshot.value as Map);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
    }
  }

  Future<void> loadVehicles() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db.child('users/$uid/vehicles').get();
      final List<VehicleModel> loadedList = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          loadedList.add(VehicleModel.fromMap(key, value));
        });
      }
      _vehicles = loadedList;
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando vehículos: $e");
    }
  }

  Future<bool> addVehicle(String placa, String modelo, String color) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final newVehicleRef = _db.child('users/$uid/vehicles').push();
      await newVehicleRef.set({
        'placa': placa,
        'modelo': modelo,
        'color': color,
        'capacidad': 4,
      });

      await loadVehicles();
      return true;
    } catch (e) {
      debugPrint("Error agregando vehículo: $e");
      return false;
    }
  }

  // --- LÓGICA DE AUTH ---

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

      // Aquí usamos la variable _selectedUniversity que seteamos en la pantalla anterior
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

      _userProfile = profileData;
      _vehicles = [];
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
      _errorMessage = 'Ocurrió un error inesperado al registrar.';
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

      await loadUserProfile();
      await loadVehicles();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'Usuario no encontrado.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-credential') {
        _errorMessage = 'Credenciales inválidas.';
      } else {
        _errorMessage = 'Error al ingresar: ${e.code}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión o inesperado.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null;
    _userProfile = null;
    _vehicles = [];
    notifyListeners();
  }
}