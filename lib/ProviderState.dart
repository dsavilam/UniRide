import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';

// --- MODELOS ---
class VehicleModel {
  final String id;
  final String placa;
  final String modelo;
  final String color;

  VehicleModel({required this.id, required this.placa, required this.modelo, required this.color});

  factory VehicleModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VehicleModel(
      id: id,
      placa: map['placa'] ?? '',
      modelo: map['modelo'] ?? '',
      color: map['color'] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {'placa': placa, 'modelo': modelo, 'color': color};
}

class TripModel {
  final String id;
  final String driverId;
  final String driverName;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final double price;
  final int availableSeats;
  final int departureTime;
  final String routeDescription;

  TripModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.vehicle,
    required this.origin,
    required this.destination,
    required this.price,
    required this.availableSeats,
    required this.departureTime,
    required this.routeDescription,
  });

  factory TripModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TripModel(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Conductor',
      vehicle: Map<String, dynamic>.from(map['vehicle'] ?? {}),
      origin: Map<String, dynamic>.from(map['origin'] ?? {}),
      destination: Map<String, dynamic>.from(map['destination'] ?? {}),
      price: (map['economics']?['price'] ?? 0).toDouble(),
      availableSeats: map['seats']?['available'] ?? 0,
      departureTime: map['timing']?['departureTime'] ?? 0,
      routeDescription: map['destination']?['routeDescription'] ?? '',
    );
  }
}

// --- PROVIDER ---
class ProviderState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  // Inicializar Storage con el bucket específico
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'uni-ride-214d1.firebasestorage.app',
  );
  final Distance _distanceCalculator = const Distance();

  String? _selectedUniversity;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  List<VehicleModel> _vehicles = [];
  List<TripModel> _foundTrips = [];
  bool _isSearchingTrips = false;

  final List<String> _allowedDomains = ['uexternado.edu.co', 'urosario.edu.co', 'javeriana.edu.co', 'uniandes.edu.co'];

  String? get selectedUniversity => _selectedUniversity;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<VehicleModel> get vehicles => _vehicles;
  List<TripModel> get foundTrips => _foundTrips;
  bool get isSearchingTrips => _isSearchingTrips;

  void selectUniversity(String universityName) { _selectedUniversity = universityName; notifyListeners(); }
  bool validateEmailDomain(String email) => _allowedDomains.any((d) => email.toLowerCase().trim().endsWith(d));

  Future<void> loadUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await _db.child('users/$uid/profile').get();
      if (snapshot.exists) {
        _userProfile = Map<String, dynamic>.from(snapshot.value as Map);
        notifyListeners();
      }
    } catch (e) { debugPrint("Error perfil: $e"); }
  }

  // Método para subir foto de perfil a Firebase Storage y guardar URL
  Future<String?> uploadProfilePhoto(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint("Error: Usuario no autenticado");
      return null;
    }

    try {
      // Crear referencia en Storage: profile_photos/{userId}.jpg
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      
      // Metadata para especificar el tipo de contenido
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
      );
      
      // Subir el archivo con metadata
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      
      // Verificar que la subida fue exitosa
      if (snapshot.state == TaskState.success) {
        // Obtener la URL de descarga
        final String downloadUrl = await ref.getDownloadURL();
        
        // Guardar la URL en la base de datos
        await _db.child('users/$uid/profile/photoUrl').set(downloadUrl);
        
        // Actualizar el perfil local
        if (_userProfile != null) {
          _userProfile!['photoUrl'] = downloadUrl;
          notifyListeners();
        }
        
        debugPrint("Foto subida exitosamente: $downloadUrl");
        return downloadUrl;
      } else {
        debugPrint("Error: Estado de subida: ${snapshot.state}");
        return null;
      }
    } on FirebaseException catch (e) {
      debugPrint("Error Firebase subiendo foto: ${e.code} - ${e.message}");
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        debugPrint("Error: Usuario no autorizado. Las reglas de Storage están bloqueando el acceso.");
        debugPrint("Por favor configura las reglas en Firebase Console -> Storage -> Rules:");
        debugPrint("rules_version = '2';");
        debugPrint("service firebase.storage {");
        debugPrint("  match /b/{bucket}/o {");
        debugPrint("    match /profile_photos/{userId}.jpg {");
        debugPrint("      allow read: if request.auth != null;");
        debugPrint("      allow write: if request.auth != null && request.auth.uid == userId;");
        debugPrint("    }");
        debugPrint("  }");
        debugPrint("}");
      } else if (e.code == 'object-not-found' || e.code == 'not-found') {
        debugPrint("Error: Firebase Storage no está configurado o las reglas bloquean el acceso");
        debugPrint("Por favor verifica en Firebase Console:");
        debugPrint("1. Que Storage esté habilitado");
        debugPrint("2. Que las reglas permitan escritura para usuarios autenticados");
      }
      return null;
    } catch (e) {
      debugPrint("Error general subiendo foto: $e");
      return null;
    }
  }

  // Método para eliminar foto de perfil
  Future<bool> deleteProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    try {
      // Eliminar de Storage
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      await ref.delete();
      
      // Eliminar URL de la base de datos
      await _db.child('users/$uid/profile/photoUrl').remove();
      
      // Actualizar el perfil local
      if (_userProfile != null) {
        _userProfile!.remove('photoUrl');
        notifyListeners();
      }
      
      return true;
    } on FirebaseException catch (e) {
      debugPrint("Error Firebase eliminando foto: ${e.code} - ${e.message}");
      // Si el archivo no existe, igualmente eliminamos la URL de la BD
      try {
        await _db.child('users/$uid/profile/photoUrl').remove();
        if (_userProfile != null) {
          _userProfile!.remove('photoUrl');
          notifyListeners();
        }
        return true;
      } catch (dbError) {
        debugPrint("Error eliminando URL de BD: $dbError");
        return false;
      }
    } catch (e) {
      debugPrint("Error general eliminando foto: $e");
      return false;
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
        data.forEach((k, v) => loadedList.add(VehicleModel.fromMap(k, v)));
      }
      _vehicles = loadedList;
      notifyListeners();
    } catch (e) { debugPrint("Error vehiculos: $e"); }
  }

  Future<bool> addVehicle(String p, String m, String c) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db.child('users/$uid/vehicles').push().set({'placa': p, 'modelo': m, 'color': c, 'capacidad': 4});
      await loadVehicles();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> publishTrip({
    required String vehiclePlaca,
    required DateTime departureDate,
    required TimeOfDay departureTime,
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    required double price,
    required int capacity,
    required String comments,
    required List<dynamic> routePolyline,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    VehicleModel? vehicleObj;
    try { vehicleObj = _vehicles.firstWhere((v) => v.placa == vehiclePlaca); }
    catch (e) { vehicleObj = VehicleModel(id: 'unk', placa: vehiclePlaca, modelo: '', color: ''); }

    try {
      final DateTime fullDateTime = DateTime(departureDate.year, departureDate.month, departureDate.day, departureTime.hour, departureTime.minute);
      final newTripRef = _db.child('trips').push();
      final tripData = {
        "driverId": uid,
        "driverName": _userProfile?['fullName'] ?? 'Conductor',
        "university": _userProfile?['university'] ?? 'Desconocida',
        "vehicle": vehicleObj.toJson(),
        "origin": origin,
        "destination": { ...destination, "routeDescription": comments },
        "timing": { "departureTime": fullDateTime.millisecondsSinceEpoch, "estimatedDurationMin": 0 },
        "status": "active",
        "economics": { "price": price, "currency": "COP" },
        "seats": { "initialCapacity": capacity, "available": capacity, "passengers": {} },
        "routePolyline": routePolyline
      };
      await newTripRef.set(tripData);
      return true;
    } catch (e) { return false; }
  }

  Future<void> searchTrips({required LatLng passengerOrigin, required LatLng passengerDest}) async {
    _isSearchingTrips = true;
    _foundTrips = [];
    notifyListeners();
    final myUid = _auth.currentUser?.uid;

    try {
      final snapshot = await _db.child('trips').orderByChild('status').equalTo('active').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final trip = TripModel.fromMap(key, value);
          if (trip.driverId == myUid) return;
          if (trip.availableSeats <= 0) return;

          final double distOriginKm = _distanceCalculator.as(LengthUnit.Kilometer, LatLng(trip.origin['lat'], trip.origin['lng']), passengerOrigin);
          final double distDestKm = _distanceCalculator.as(LengthUnit.Kilometer, LatLng(trip.destination['lat'], trip.destination['lng']), passengerDest);

          if (distOriginKm <= 2.0 && distDestKm <= 2.0) {
            _foundTrips.add(trip);
          }
        });
      }
    } catch (e) { debugPrint("Error busqueda: $e"); }
    finally { _isSearchingTrips = false; notifyListeners(); }
  }

  Future<bool> bookTrip(String tripId, int currentAvailable) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db.child('trips/$tripId/seats').update({
        'available': currentAvailable - 1,
        'passengers/$uid': true,
      });
      return true;
    } catch (e) { return false; }
  }

  Future<bool> cancelTripReservation(String tripId, int currentAvailable) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db.child('trips/$tripId/seats').update({
        'available': currentAvailable + 1,
        'passengers/$uid': null,
      });
      return true;
    } catch (e) { return false; }
  }

  Future<bool> registerUser({required String nombre, required String correo, required String usuario, required String password, required String celular}) async {
    _errorMessage = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: correo.trim(), password: password.trim());
      final uid = cred.user!.uid;
      final check = await _db.child('users').orderByChild('profile/email').equalTo(correo.trim()).get();
      if (check.exists) { await cred.user!.delete(); _errorMessage = 'Correo ya registrado en BD.'; notifyListeners(); return false; }
      if (!cred.user!.emailVerified) await cred.user!.sendEmailVerification();

      final pData = {'fullName': nombre, 'email': correo.trim(), 'username': usuario.trim(), 'university': _selectedUniversity ?? 'Desc', 'phone': celular.trim(), 'rating': 5.0, 'completedTrips': 0};
      await _db.child('users/$uid/profile').set(pData);
      _userProfile = pData; _vehicles = []; notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) { _errorMessage = e.message; notifyListeners(); return false; }
    catch (e) { _errorMessage = 'Error registro.'; notifyListeners(); return false; }
  }

  Future<bool> loginUser({required String usuario, required String password}) async {
    _errorMessage = null;
    try {
      if (!usuario.contains('@')) { _errorMessage = "Usa correo institucional."; notifyListeners(); return false; }
      final cred = await _auth.signInWithEmailAndPassword(email: usuario.trim(), password: password.trim());
      if (cred.user != null) await cred.user!.reload();
      await loadUserProfile(); await loadVehicles();
      return true;
    } on FirebaseAuthException catch (e) { _errorMessage = e.message; notifyListeners(); return false; }
    catch (e) { _errorMessage = 'Error login.'; notifyListeners(); return false; }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null; _userProfile = null; _vehicles = []; _foundTrips = [];
    notifyListeners();
  }
}