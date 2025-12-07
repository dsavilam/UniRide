import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Definimos el modelo del vehículo aquí para usarlo en toda la app
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

  // Convertir de JSON a Objeto
  factory VehicleModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VehicleModel(
      id: id,
      placa: map['placa'] ?? '',
      modelo: map['modelo'] ?? '',
      color: map['color'] ?? '',
    );
  }
}

class ProviderState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? _selectedUniversity;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  // Lista de vehículos del usuario
  List<VehicleModel> _vehicles = [];

  final List<String> _allowedDomains = [
    'uexternado.edu.co',
    'urosario.edu.co',
    'javeriana.edu.co',
    'uniandes.edu.co',
  ];

  String? get selectedUniversity => _selectedUniversity;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<VehicleModel> get vehicles => _vehicles;

  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    notifyListeners();
  }

  bool validateEmailDomain(String email) {
    final lowerEmail = email.toLowerCase().trim();
    return _allowedDomains.any((domain) => lowerEmail.endsWith(domain));
  }

  // Cargar Perfil
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

  // --- NUEVO: Cargar Vehículos de Firebase ---
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

  // --- NUEVO: Agregar Vehículo a Firebase ---
  Future<bool> addVehicle(String placa, String modelo, String color) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      final newVehicleRef = _db.child('users/$uid/vehicles').push();
      await newVehicleRef.set({
        'placa': placa,
        'modelo': modelo,
        'color': color,
        'capacidad': 4 // Por defecto
      });

      // Recargamos la lista localmente
      await loadVehicles();
      return true;
    } catch (e) {
      debugPrint("Error agregando vehículo: $e");
      return false;
    }
  }

  // ... (El resto de tus funciones de Auth: registerUser, loginUser, logout siguen igual)
  // Solo recuerda llamar a loadVehicles() dentro de loginUser y registerUser si quieres

  Future<bool> registerUser({
    required String nombre,
    required String correo,
    required String usuario,
    required String password,
    required String celular,
  }) async {
    // ... (Tu código existente) ...
    // Al final del try, antes de return true:
    // _userProfile = profileData;
    // notifyListeners();
    return true;
    // (Asegúrate de copiar tu lógica completa aquí, la he omitido para ahorrar espacio
    // pero mantén la que ya tenías)
  }

  // LOGIN REAL
  Future<bool> loginUser({required String usuario, required String password}) async {
    // ... (Tu código de login existente) ...
    // Después del signIn:
    // await loadUserProfile();
    await loadVehicles(); // <--- Agregamos esto para cargar los carros al entrar
    return true;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null;
    _userProfile = null;
    _vehicles = []; // Limpiamos vehículos
    notifyListeners();
  }
}