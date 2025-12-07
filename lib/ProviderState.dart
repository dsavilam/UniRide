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

  // Convertir de Map (Firebase) a Objeto
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
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // -- Variables de Estado --
  String? _selectedUniversity;
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
    notifyListeners();
  }

  bool validateEmailDomain(String email) {
    final lowerEmail = email.toLowerCase().trim();
    return _allowedDomains.any((domain) => lowerEmail.endsWith(domain));
  }

  // ---------------------------------------------------------------------------
  // LÓGICA DE DATOS (Perfil y Vehículos)
  // ---------------------------------------------------------------------------

  // Cargar Perfil desde Realtime Database
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

  // Cargar Vehículos desde Realtime Database
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

  // Agregar Vehículo a Firebase
  Future<bool> addVehicle(String placa, String modelo, String color) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final newVehicleRef = _db.child('users/$uid/vehicles').push();
      await newVehicleRef.set({
        'placa': placa,
        'modelo': modelo,
        'color': color,
        'capacidad': 4, // Valor por defecto
      });

      // Recargamos la lista localmente para ver el cambio inmediato
      await loadVehicles();
      return true;
    } catch (e) {
      debugPrint("Error agregando vehículo: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // LÓGICA DE AUTENTICACIÓN (Registro y Login)
  // ---------------------------------------------------------------------------

  // Registro de Usuario
  Future<bool> registerUser({
    required String nombre,
    required String correo,
    required String usuario,
    required String password,
    required String celular,
  }) async {
    _errorMessage = null;
    try {
      // 1. Crear usuario en Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: password.trim(),
      );

      final String uid = userCredential.user!.uid;

      // 2. Preparar datos del perfil
      final profileData = {
        'fullName': nombre,
        'email': correo.trim(),
        'username': usuario.trim(),
        'university': _selectedUniversity ?? 'Desconocida',
        'phone': celular.trim(),
        'rating': 5.0,
        'completedTrips': 0,
      };

      // 3. Guardar en Base de Datos
      await _db.child('users/$uid/profile').set(profileData);

      // 4. Actualizar estado local
      _userProfile = profileData;
      _vehicles = []; // Usuario nuevo no tiene vehículos aún
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

  // Inicio de Sesión
  Future<bool> loginUser({
    required String usuario, // Se asume que es el correo
    required String password,
  }) async {
    _errorMessage = null;
    try {
      if (!usuario.contains('@')) {
        _errorMessage = "Por favor ingresa tu correo institucional completo.";
        notifyListeners();
        return false;
      }

      // 1. Autenticar con Firebase
      await _auth.signInWithEmailAndPassword(
        email: usuario.trim(),
        password: password.trim(),
      );

      // 2. Cargar datos del usuario (Perfil y Vehículos)
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

  // Cerrar Sesión
  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null;
    _userProfile = null;
    _vehicles = [];
    notifyListeners();
  }
}