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

  VehicleModel(
      {required this.id,
      required this.placa,
      required this.modelo,
      required this.color});

  factory VehicleModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return VehicleModel(
      id: id,
      placa: map['placa'] ?? '',
      modelo: map['modelo'] ?? '',
      color: map['color'] ?? '',
    );
  }
  Map<String, dynamic> toJson() =>
      {'placa': placa, 'modelo': modelo, 'color': color};
}

class TripModel {
  final String id;
  final String driverId;
  final String driverName;
  final Map<String, dynamic> vehicle;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final Map<String, dynamic>?
      waypoint; // <--- Nuevo: Guardamos el waypoint si existe
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
    this.waypoint,
    required this.price,
    required this.availableSeats,
    required this.departureTime,
    required this.routeDescription,
  });

  factory TripModel.fromMap(String id, Map<dynamic, dynamic> map) {
    // Intentar extraer el waypoint del destino si existe
    Map<String, dynamic>? parsedWaypoint;
    if (map['destination'] != null && map['destination']['waypoint'] != null) {
      parsedWaypoint =
          Map<String, dynamic>.from(map['destination']['waypoint']);
    }

    return TripModel(
      id: id,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? 'Conductor',
      vehicle: Map<String, dynamic>.from(map['vehicle'] ?? {}),
      origin: Map<String, dynamic>.from(map['origin'] ?? {}),
      destination: Map<String, dynamic>.from(map['destination'] ?? {}),
      waypoint: parsedWaypoint, // Asignar el waypoint
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
  List<TripModel> _myDriverTrips = [];
  List<TripModel> _myPassengerTrips = [];

  final List<String> _allowedDomains = [
    'uexternado.edu.co',
    'urosario.edu.co',
    'javeriana.edu.co',
    'uniandes.edu.co'
  ];

  String? get selectedUniversity => _selectedUniversity;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<VehicleModel> get vehicles => _vehicles;
  List<TripModel> get foundTrips => _foundTrips;
  bool get isSearchingTrips => _isSearchingTrips;
  List<TripModel> get myDriverTrips => _myDriverTrips;
  List<TripModel> get myPassengerTrips => _myPassengerTrips;

  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    notifyListeners();
  }

  bool validateEmailDomain(String email) =>
      _allowedDomains.any((d) => email.toLowerCase().trim().endsWith(d));

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
      debugPrint("Error perfil: $e");
    }
  }

  // Subir foto
  Future<String?> uploadProfilePhoto(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try {
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await ref.getDownloadURL();
        await _db.child('users/$uid/profile/photoUrl').set(downloadUrl);
        if (_userProfile != null) {
          _userProfile!['photoUrl'] = downloadUrl;
          notifyListeners();
        }
        return downloadUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Eliminar foto
  Future<bool> deleteProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      await ref.delete();
      await _db.child('users/$uid/profile/photoUrl').remove();
      if (_userProfile != null) {
        _userProfile!.remove('photoUrl');
        notifyListeners();
      }
      return true;
    } catch (e) {
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
    } catch (e) {
      debugPrint("Error vehiculos: $e");
    }
  }

  Future<bool> addVehicle(String p, String m, String c) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db
          .child('users/$uid/vehicles')
          .push()
          .set({'placa': p, 'modelo': m, 'color': c, 'capacidad': 4});
      await loadVehicles();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cambiamos Future<bool> por Future<String?> para retornar el ID del viaje creado
  Future<String?> publishTrip({
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
    if (uid == null) return null; // Retornamos null si falla

    VehicleModel? vehicleObj;
    try {
      vehicleObj = _vehicles.firstWhere((v) => v.placa == vehiclePlaca);
    } catch (e) {
      vehicleObj =
          VehicleModel(id: 'unk', placa: vehiclePlaca, modelo: '', color: '');
    }

    try {
      final DateTime fullDateTime = DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day,
        departureTime.hour,
        departureTime.minute,
      );

      // Creamos la referencia primero para obtener el ID (key)
      final newTripRef = _db.child('trips').push();

      final tripData = {
        "driverId": uid,
        "driverName": _userProfile?['fullName'] ?? 'Conductor',
        "university": _userProfile?['university'] ?? 'Desconocida',
        "vehicle": vehicleObj.toJson(),
        "origin": origin,
        "destination": {...destination, "routeDescription": comments},
        "timing": {
          "departureTime": fullDateTime.millisecondsSinceEpoch,
          "estimatedDurationMin": 0
        },
        "status": "active",
        "economics": {"price": price, "currency": "COP"},
        "seats": {
          "initialCapacity": capacity,
          "available": capacity,
          "passengers": {}
        },
        "routePolyline": routePolyline
      };

      await newTripRef.set(tripData);

      // ¡ÉXITO! Retornamos el ID del nuevo viaje
      return newTripRef.key;
    } catch (e) {
      debugPrint("Error publicando viaje: $e");
      return null;
    }
  }

  // --- LÓGICA DE BÚSQUEDA AVANZADA CON RECTÁNGULO DE WAYPOINT ---
  Future<void> searchTrips(
      {required LatLng passengerOrigin, required LatLng passengerDest}) async {
    _isSearchingTrips = true;
    _foundTrips = [];
    notifyListeners();
    final myUid = _auth.currentUser?.uid;

    try {
      final snapshot = await _db
          .child('trips')
          .orderByChild('status')
          .equalTo('active')
          .get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final trip = TripModel.fromMap(key, value);

          if (trip.driverId == myUid) return;
          if (trip.availableSeats <= 0) return;

          // 1. Verificar coincidencia DIRECTA (Origen con Origen, Destino con Destino)
          // Radio estricto de 2km para puntos principales
          final bool originMatch = _isClose(trip.origin, passengerOrigin, 2.0);
          final bool destMatch = _isClose(trip.destination, passengerDest, 2.0);

          // 2. Verificar WAYPOINT (Si el viaje tiene parada intermedia)
          bool waypointOriginMatch =
              false; // ¿El pasajero se sube en el waypoint?
          bool waypointDestMatch =
              false; // ¿El pasajero se baja en el waypoint?

          if (trip.waypoint != null) {
            // Lógica del Rectángulo: 5km Largo (±2.5km) x 1km Ancho (±0.5km)
            // Como no tenemos vector de dirección, usamos el radio mayor (2.5km) para cubrir el largo.
            waypointOriginMatch =
                _isWithinWaypointRectangle(trip.waypoint!, passengerOrigin);
            waypointDestMatch =
                _isWithinWaypointRectangle(trip.waypoint!, passengerDest);
          }

          // --- EVALUACIÓN FINAL DEL VIAJE ---
          // Caso A: Viaje Completo (Origen Cerca -> Destino Cerca)
          if (originMatch && destMatch) {
            _foundTrips.add(trip);
          }
          // Caso B: Pasajero se sube en Waypoint (Waypoint Cerca -> Destino Cerca)
          else if (waypointOriginMatch && destMatch) {
            _foundTrips.add(trip);
          }
          // Caso C: Pasajero se baja en Waypoint (Origen Cerca -> Waypoint Cerca)
          else if (originMatch && waypointDestMatch) {
            _foundTrips.add(trip);
          }
        });
      }
    } catch (e) {
      debugPrint("Error busqueda: $e");
    } finally {
      _isSearchingTrips = false;
      notifyListeners();
    }
  }

  // --- MIS VIAJES (CONDUCTOR) ---
  Future<void> fetchMyDriverTrips() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final List<TripModel> loaded = [];

      // Helper para procesar snapshot
      void processSnapshot(DataSnapshot snapshot) {
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((k, v) {
            final trip = TripModel.fromMap(k, v);
            // IMPORTANTE: Filtramos aquí para asegurar que solo vemos LOS MÍOS
            if (trip.driverId == uid) {
              // Evitar duplicados
              if (!loaded.any((t) => t.id == trip.id)) {
                loaded.add(trip);
              }
            }
          });
        }
      }

      // 1. Traer activos (Esto suele funcionar mejor sin indices complejos)
      final s1 = await _db
          .child('trips')
          .orderByChild('status')
          .equalTo('active')
          .get();
      processSnapshot(s1);

      // 2. Traer en progreso
      final s2 = await _db
          .child('trips')
          .orderByChild('status')
          .equalTo('in_progress')
          .get();
      processSnapshot(s2);

      // Ordenar por fecha
      loaded.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      _myDriverTrips = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching driver trips: $e");
    }
  }

  // --- ELIMINAR VIAJE (CONDUCTOR) ---
  Future<bool> deleteTrip(String tripId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || tripId.isEmpty) return false;

    try {
      // Doble verificación: Asegurar que el viaje pertenece al usuario antes de borrar
      final snapshot = await _db.child('trips/$tripId').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        if (data['driverId'] == uid) {
          await _db.child('trips/$tripId').remove();
          // Actualizar lista local
          _myDriverTrips.removeWhere((t) => t.id == tripId);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting trip: $e");
      return false;
    }
  }

  // --- MIS VIAJES (PASAJERO) ---
  Future<void> fetchMyPassengerTrips() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final List<TripModel> loaded = [];

      // Helper para procesar snapshot
      void processSnapshot(DataSnapshot snapshot) {
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((k, v) {
            final trip = TripModel.fromMap(k, v);
            final passengers = v['seats']?['passengers'] as Map?;
            if (passengers != null && passengers.containsKey(uid)) {
              // Evitar duplicados si por alguna razón se solapan (raro aquí)
              if (!loaded.any((t) => t.id == trip.id)) {
                loaded.add(trip);
              }
            }
          });
        }
      }

      // 1. Traer activos
      final s1 = await _db
          .child('trips')
          .orderByChild('status')
          .equalTo('active')
          .get();
      processSnapshot(s1);

      // 2. Traer en progreso
      final s2 = await _db
          .child('trips')
          .orderByChild('status')
          .equalTo('in_progress')
          .get();
      processSnapshot(s2);

      // Ordenar por fecha
      loaded.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      _myPassengerTrips = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching passenger trips: $e");
    }
  }

  // Helper para distancia simple (km)
  bool _isClose(
      Map<String, dynamic> pointData, LatLng userPoint, double radiusKm) {
    if (pointData['lat'] == null || pointData['lng'] == null) return false;
    final tripPoint = LatLng(pointData['lat'], pointData['lng']);
    final double dist =
        _distanceCalculator.as(LengthUnit.Kilometer, tripPoint, userPoint);
    return dist <= radiusKm;
  }

  // Helper para la lógica del "Rectángulo" en el Waypoint
  bool _isWithinWaypointRectangle(
      Map<String, dynamic> waypointData, LatLng userPoint) {
    if (waypointData['lat'] == null || waypointData['lng'] == null)
      return false;

    final waypointPoint = LatLng(waypointData['lat'], waypointData['lng']);
    final double dist =
        _distanceCalculator.as(LengthUnit.Kilometer, waypointPoint, userPoint);

    // REGLA: Rectángulo de 5km de largo x 1km de ancho.
    // Interpretación: El largo de 5km implica que el punto más lejano válido está a 2.5km del centro.
    // El ancho de 1km implica 0.5km del centro lateralmente.
    // Sin vector de dirección del coche, la forma más segura de NO descartar un viaje válido
    // es permitir un radio igual al semieje mayor (2.5km).
    // Esto crea un área circular de cobertura que engloba el rectángulo solicitado.

    return dist <= 2.5;
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
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelTripReservation(
      String tripId, int currentAvailable) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      await _db.child('trips/$tripId/seats').update({
        'available': currentAvailable + 1,
        'passengers/$uid': null,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerUser(
      {required String nombre,
      required String correo,
      required String usuario,
      required String password,
      required String celular}) async {
    _errorMessage = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: correo.trim(), password: password.trim());
      final uid = cred.user!.uid;
      final check = await _db
          .child('users')
          .orderByChild('profile/email')
          .equalTo(correo.trim())
          .get();
      if (check.exists) {
        await cred.user!.delete();
        _errorMessage = 'Correo ya registrado en BD.';
        notifyListeners();
        return false;
      }
      if (!cred.user!.emailVerified) await cred.user!.sendEmailVerification();

      final pData = {
        'fullName': nombre,
        'email': correo.trim(),
        'username': usuario.trim(),
        'university': _selectedUniversity ?? 'Desc',
        'phone': celular.trim(),
        'rating': 5.0,
        'completedTrips': 0,
        'ratingCount': 0
      };
      await _db.child('users/$uid/profile').set(pData);
      _userProfile = pData;
      _vehicles = [];
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error registro.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginUser(
      {required String usuario, required String password}) async {
    _errorMessage = null;
    try {
      if (!usuario.contains('@')) {
        _errorMessage = "Usa correo institucional.";
        notifyListeners();
        return false;
      }
      final cred = await _auth.signInWithEmailAndPassword(
          email: usuario.trim(), password: password.trim());
      if (cred.user != null) await cred.user!.reload();
      await loadUserProfile();
      await loadVehicles();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error login.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _selectedUniversity = null;
    _userProfile = null;
    _vehicles = [];
    _foundTrips = [];
    notifyListeners();
  }

  // --- NUEVOS MÉTODOS PARA EL FLUJO DE CONDUCTOR ---

  // 1. Obtener información de un pasajero por su ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId/profile').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint("Error obteniendo usuario: $e");
    }
    return null;
  }

  // 2. Cambiar estado del viaje (active -> in_progress -> finished)
  Future<bool> updateTripStatus(String tripId, String newStatus) async {
    try {
      await _db.child('trips/$tripId').update({'status': newStatus});

      // Si el viaje finalizó, incrementamos el contador del conductor (usuario actual)
      if (newStatus == 'finished') {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _incrementUserTrips(uid);
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error actualizando estado: $e");
      return false;
    }
  }

  Future<void> _incrementUserTrips(String uid) async {
    try {
      final ref = _db.child('users/$uid/profile/completedTrips');
      final snapshot = await ref.get();
      int current = 0;
      if (snapshot.exists) {
        current = (snapshot.value is num)
            ? (snapshot.value as num).toInt()
            : int.tryParse(snapshot.value.toString()) ?? 0;
      }
      await ref.set(current + 1);

      // Si es el usuario actual, actualizamos el estado local
      if (_userProfile != null && _auth.currentUser?.uid == uid) {
        _userProfile!['completedTrips'] = current + 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error incrementing trips: $e");
    }
  }

  // 3. Calificar usuario (Conductor a Pasajero o viceversa)
  Future<bool> rateUser(String userId, double rating,
      {bool incrementCount = true}) async {
    try {
      final userRef = _db.child('users/$userId/profile');
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        double currentRating = (data['rating'] is num)
            ? (data['rating'] as num).toDouble()
            : double.tryParse(data['rating'].toString()) ?? 5.0;

        int trips = (data['completedTrips'] is num)
            ? (data['completedTrips'] as num).toInt()
            : int.tryParse(data['completedTrips'].toString()) ?? 0;

        // NUEVO: Usamos ratingCount para el promedio real
        int ratingCount = (data['ratingCount'] is num)
            ? (data['ratingCount'] as num).toInt()
            : int.tryParse(data['ratingCount'].toString()) ??
                trips; // Fallback a trips si no existe

        // Calculamos nuevo promedio basado en ratingCount
        // Promedio = ( (OldAvg * OldCount) + NewVal ) / (OldCount + 1)
        double newRating =
            ((currentRating * ratingCount) + rating) / (ratingCount + 1);

        int newTripsCount = trips;
        if (incrementCount) {
          newTripsCount = trips + 1;
        }

        await userRef.update({
          'rating': newRating,
          'completedTrips': newTripsCount,
          'ratingCount': ratingCount +
              1 // Siempre incrementamos el conteo de calificaciones
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error calificando: $e");
      return false;
    }
  }
}
