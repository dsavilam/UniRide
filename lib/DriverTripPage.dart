import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import './ProviderState.dart';

class DriverTripPage extends StatefulWidget {
  final String tripId;
  final TripModel tripData;

  const DriverTripPage({super.key, required this.tripId, required this.tripData});

  @override
  State<DriverTripPage> createState() => _DriverTripPageState();
}

class _DriverTripPageState extends State<DriverTripPage> {
  late DatabaseReference _tripRef;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _passengersList = [];
  String _tripStatus = "active";
  Timer? _timer;
  bool _canStartTrip = false;

  // Lista de LatLng para dibujar la ruta en el mapa
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _tripRef = FirebaseDatabase.instance.ref('trips/${widget.tripId}');

    // 1. Cargar la ruta que guardamos en BD
    _loadRouteFromModel();

    // 2. Escuchar cambios
    _tripRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _updatePassengersList(data['seats']?['passengers']);
        if (mounted) {
          setState(() => _tripStatus = data['status'] ?? "active");
        }
      }
    });

    _getCurrentLocation();
    _checkStartTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _checkStartTime());
  }

  // --- NUEVO: Extraer ruta real del modelo ---
  void _loadRouteFromModel() {
    // Si el tripData (TripModel) no tiene routePolyline mapeado en su clase,
    // tendremos que confiar en que el usuario lo pasa bien o leerlo de BD.
    // Aquí asumimos que lo leemos de la BD para asegurar que es la línea trazada.

    _tripRef.child('routePolyline').get().then((snapshot) {
      if (snapshot.exists) {
        final List<dynamic> points = snapshot.value as List<dynamic>;
        setState(() {
          _routePoints = points.map((p) => LatLng(p[0], p[1])).toList();
        });
      } else {
        // Fallback: Línea recta
        setState(() {
          _routePoints = [
            LatLng(widget.tripData.origin['lat'], widget.tripData.origin['lng']),
            LatLng(widget.tripData.destination['lat'], widget.tripData.destination['lng'])
          ];
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 14);
      });
    }
  }

  void _checkStartTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tripTime = widget.tripData.departureTime;
    final diff = tripTime - now;
    // Rango de 5 minutos (300,000 ms) antes o después
    bool canStart = diff <= 300000;

    if (canStart != _canStartTrip && mounted) {
      setState(() => _canStartTrip = canStart);
    }
  }

  Future<void> _updatePassengersList(Map<dynamic, dynamic>? passengersData) async {
    if (passengersData == null) {
      if (mounted) setState(() => _passengersList = []);
      return;
    }

    final provider = context.read<ProviderState>();
    List<Map<String, dynamic>> tempList = [];

    for (var userId in passengersData.keys) {
      if (passengersData[userId] == true) {
        final profile = await provider.getUserProfile(userId.toString());
        if (profile != null) {
          profile['uid'] = userId;
          tempList.add(profile);
        }
      }
    }

    if (mounted) {
      setState(() => _passengersList = tempList);
    }
  }

  // --- ACCIONES ---

  void _startTrip() async {
    // Validación de seguridad extra
    if (_passengersList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Necesitas al menos un pasajero para iniciar.")));
      return;
    }

    final provider = context.read<ProviderState>();
    await provider.updateTripStatus(widget.tripId, 'in_progress');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Viaje iniciado!")));
  }

  void _finishTrip() async {
    final provider = context.read<ProviderState>();
    await provider.updateTripStatus(widget.tripId, 'finished');

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RatePassengersDialog(passengers: _passengersList),
      ).then((_) {
        Navigator.pop(context); // Volver al home
      });
    }
  }

  void _cancelAndExit() async {
    // Lógica para borrar el viaje si no hay pasajeros y el conductor se arrepiente
    // (O simplemente salir)
    await _tripRef.remove(); // Opcional: Borrar el viaje de BD
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.tripData.departureTime);
    final timeStr = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    final bool hasPassengers = _passengersList.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tripStatus == 'in_progress' ? "En ruta..." : "Esperando salida"),
        backgroundColor: _tripStatus == 'in_progress' ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Si intenta salir y el viaje está activo, preguntar o borrar
            if (_tripStatus == 'active') {
              _cancelAndExit();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.tripData.origin['lat'], widget.tripData.origin['lng']),
                initialZoom: 13,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 5.0),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
                      ),
                    Marker(
                      point: LatLng(widget.tripData.origin['lat'], widget.tripData.origin['lng']),
                      child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                    ),
                    Marker(
                      point: LatLng(widget.tripData.destination['lat'], widget.tripData.destination['lng']),
                      child: const Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hora de salida", style: TextStyle(color: Colors.grey)),
                          Text(timeStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text("${_passengersList.length} Pasajeros",
                            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const Divider(height: 30),

                  const Text("Pasajeros confirmados:", style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: _passengersList.isEmpty
                        ? const Center(child: Text("Esperando pasajeros...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                        : ListView.builder(
                      itemCount: _passengersList.length,
                      itemBuilder: (context, index) {
                        final p = _passengersList[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: p['photoUrl'] != null ? NetworkImage(p['photoUrl']) : null,
                            child: p['photoUrl'] == null ? Text(p['fullName'][0]) : null,
                          ),
                          title: Text(p['fullName']),
                          trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- LÓGICA DE BOTONES ---
                  if (_tripStatus == 'active') ...[
                    if (hasPassengers)
                      ElevatedButton.icon(
                        onPressed: _canStartTrip ? _startTrip : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_canStartTrip ? "COMENZAR VIAJE" : "Espera a la hora"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _cancelAndExit,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Volver (Sin pasajeros)"),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red
                        ),
                      )
                  ]
                  else if (_tripStatus == 'in_progress')
                    ElevatedButton.icon(
                      onPressed: _finishTrip,
                      icon: const Icon(Icons.flag),
                      label: const Text("FINALIZAR VIAJE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  else
                    const Center(child: Text("Viaje finalizado", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DIALOGO CONDUCTOR -> CALIFICAR PASAJEROS
class RatePassengersDialog extends StatefulWidget {
  final List<Map<String, dynamic>> passengers;
  const RatePassengersDialog({super.key, required this.passengers});

  @override
  State<RatePassengersDialog> createState() => _RatePassengersDialogState();
}

class _RatePassengersDialogState extends State<RatePassengersDialog> {
  final Map<String, double> _ratings = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("¡Viaje Finalizado!"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Califica a tus pasajeros:"),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.passengers.length,
                itemBuilder: (context, index) {
                  final p = widget.passengers[index];
                  final uid = p['uid'];
                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(child: Text(p['fullName'][0])),
                        title: Text(p['fullName']),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (starIndex) {
                          return IconButton(
                            icon: Icon(
                              Icons.star,
                              color: (_ratings[uid] ?? 0) > starIndex ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _ratings[uid] = starIndex + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final provider = context.read<ProviderState>();
            for (var entry in _ratings.entries) {
              await provider.rateUser(entry.key, entry.value);
            }
            if (mounted) Navigator.pop(context);
          },
          child: const Text("FINALIZAR"),
        )
      ],
    );
  }
}