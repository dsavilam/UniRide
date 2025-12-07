import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import './ProviderState.dart';

class TripDetailsPage extends StatefulWidget {
  final TripModel trip;
  final LatLng passengerOrigin;

  const TripDetailsPage({
    super.key,
    required this.trip,
    required this.passengerOrigin
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final MapController _mapController = MapController();

  // Rutas
  List<LatLng> _routeToPickup = []; // Caminata del pasajero (Punteada)
  List<LatLng> _driverRoute = [];   // Ruta del carro (Azul sólida)

  // Estado
  String _currentStatus = "active";
  late DatabaseReference _tripRef;
  StreamSubscription? _tripSubscription;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.trip.id.isEmpty ? "active" : "active"; // Valor inicial

    // 1. Cargar ruta del conductor (La que viene de la BD)
    _loadDriverRoute();

    // 2. Calcular ruta caminando hacia el encuentro
    _getRouteToPickup();

    // 3. Escuchar cambios en tiempo real del estado del viaje
    _tripRef = FirebaseDatabase.instance.ref('trips/${widget.trip.id}');
    _tripSubscription = _tripRef.child('status').onValue.listen((event) {
      if (event.snapshot.exists) {
        final newStatus = event.snapshot.value.toString();
        if (mounted) {
          setState(() => _currentStatus = newStatus);

          // Si el conductor finaliza el viaje globalmente, mostramos dialogo
          if (newStatus == 'finished') {
            _showRateDriverDialog();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  void _loadDriverRoute() {
    // Convertimos la lista dinámica [[lat,lng],...] a List<LatLng>
    // Esta data ya viene en el TripModel desde la pantalla anterior
    try {
      // widget.trip ya debería tener routePolyline poblado desde el Provider
      // Si el TripModel no tiene routePolyline mapeado, asegúrate de que el modelo lo tenga.
      // Asumiendo que TripModel tiene el campo 'routePolyline':
      // Si no lo tiene en tu modelo actual, usa widget.trip.originalMap['routePolyline']

      // NOTA: Como en tu modelo TripModel anterior no vi explícitamente el campo routePolyline
      // en el constructor, asumiré que lo agregaste o lo sacamos del mapa si es necesario.
      // Si usaste el código que te pasé antes, ya debería estar en la BD.

      // Recuperamos directamente de la BD si el modelo no lo trajo completo
      FirebaseDatabase.instance.ref('trips/${widget.trip.id}/routePolyline').get().then((snapshot) {
        if (snapshot.exists) {
          final List<dynamic> points = snapshot.value as List<dynamic>;
          setState(() {
            _driverRoute = points.map((p) => LatLng(p[0], p[1])).toList();
          });
        }
      });

    } catch (e) {
      debugPrint("Error cargando ruta conductor: $e");
    }
  }

  Future<void> _getRouteToPickup() async {
    final start = widget.passengerOrigin;
    final end = LatLng(widget.trip.origin['lat'], widget.trip.origin['lng']);

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/walking/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        final List<dynamic> coordinates = geometry['coordinates'];

        if (mounted) {
          setState(() {
            _routeToPickup = coordinates
                .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error ruta caminata: $e");
    }
  }

  // --- ACCIONES ---

  void _cancelTrip() async {
    final provider = context.read<ProviderState>();
    final success = await provider.cancelTripReservation(widget.trip.id, widget.trip.availableSeats);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reserva cancelada")));
      Navigator.pop(context);
    }
  }

  void _finishMyTrip() {
    // El pasajero decide bajarse
    _showRateDriverDialog();
  }

  void _showRateDriverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateDriverDialog(
        driverId: widget.trip.driverId,
        driverName: widget.trip.driverName,
      ),
    ).then((_) {
      // Al cerrar el diálogo, vamos al home
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickupPoint = LatLng(trip.origin['lat'], trip.origin['lng']);

    // Status Text
    String statusText = "Esperando salida...";
    Color statusColor = Colors.orange;
    if (_currentStatus == 'in_progress') {
      statusText = "Viaje en curso";
      statusColor = Colors.green;
    } else if (_currentStatus == 'finished') {
      statusText = "Finalizado";
      statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tu Viaje", style: TextStyle(fontSize: 18)),
            Text(statusText, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // MAPA
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.passengerOrigin,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

                // 1. Ruta del Conductor (Azul Gruesa)
                PolylineLayer(
                  polylines: [
                    if (_driverRoute.isNotEmpty)
                      Polyline(
                        points: _driverRoute,
                        strokeWidth: 5.0,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                  ],
                ),

                // 2. Ruta Caminando al encuentro (Punteada Violeta)
                PolylineLayer(
                  polylines: [
                    if (_routeToPickup.isNotEmpty)
                      Polyline(
                        points: _routeToPickup,
                        strokeWidth: 4.0,
                        color: Colors.purple,
                        isDotted: true,
                      ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    // Yo
                    Marker(
                      point: widget.passengerOrigin,
                      width: 60, height: 60,
                      child: const Icon(Icons.person_pin_circle, color: Colors.purple, size: 40),
                    ),
                    // Carro (Origen del viaje)
                    Marker(
                      point: pickupPoint,
                      width: 60, height: 60,
                      child: const Icon(Icons.directions_car, color: Colors.blue, size: 40),
                    ),
                    // Destino
                    Marker(
                      point: LatLng(trip.destination['lat'], trip.destination['lng']),
                      width: 60, height: 60,
                      child: const Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PANEL INFERIOR
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Conductor
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${trip.vehicle['placa']} • ${trip.vehicle['modelo']}", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text("\$${trip.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                        const Text("COP", style: TextStyle(fontSize: 10)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // BOTÓN DE ACCIÓN
                if (_currentStatus == 'active')
                  ElevatedButton.icon(
                    onPressed: _cancelTrip,
                    icon: const Icon(Icons.close),
                    label: const Text("Cancelar Solicitud"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  )
                else if (_currentStatus == 'in_progress')
                  ElevatedButton.icon(
                    onPressed: _finishMyTrip,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Ya llegué a mi destino"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  )
                else
                  const Center(child: Text("Viaje finalizado", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DIALOGO PARA CALIFICAR AL CONDUCTOR
class RateDriverDialog extends StatefulWidget {
  final String driverId;
  final String driverName;
  const RateDriverDialog({super.key, required this.driverId, required this.driverName});

  @override
  State<RateDriverDialog> createState() => _RateDriverDialogState();
}

class _RateDriverDialogState extends State<RateDriverDialog> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Calificar Viaje"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("¿Qué tal estuvo el viaje con ${widget.driverName}?"),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1.0),
                icon: Icon(
                  Icons.star,
                  size: 32,
                  color: _rating > index ? Colors.amber : Colors.grey.shade300,
                ),
              );
            }),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_rating > 0) {
              final provider = context.read<ProviderState>();
              await provider.rateUser(widget.driverId, _rating);
            }
            if (mounted) Navigator.pop(context);
          },
          child: const Text("ENVIAR"),
        )
      ],
    );
  }
}