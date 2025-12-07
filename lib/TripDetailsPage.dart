import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import './ProviderState.dart'; // Para acceder al modelo TripModel

class TripDetailsPage extends StatefulWidget {
  final TripModel trip;
  final LatLng passengerOrigin; // Dónde está el pasajero

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
  List<LatLng> _routeToPickup = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    // Calcular ruta desde Pasajero hasta Conductor (Punto de encuentro)
    _getRouteToPickup();
  }

  Future<void> _getRouteToPickup() async {
    final start = widget.passengerOrigin;
    final end = LatLng(widget.trip.origin['lat'], widget.trip.origin['lng']);

    // Usamos perfil 'walking' porque el pasajero camina hacia el punto de encuentro
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
            _isLoadingRoute = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error calculando ruta a encuentro: $e");
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // --- LÓGICA DE CANCELACIÓN ---
  void _cancelTrip() async {
    final provider = context.read<ProviderState>();

    // Llamamos a la función del provider que devuelve el cupo a la BD
    final success = await provider.cancelTripReservation(
        widget.trip.id,
        widget.trip.availableSeats
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solicitud cancelada correctamente")),
      );
      // Regresamos al Home
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cancelar la solicitud")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final pickupPoint = LatLng(trip.origin['lat'], trip.origin['lng']);

    // Formatear Hora de Salida
    final dt = DateTime.fromMillisecondsSinceEpoch(trip.departureTime);
    final timeString = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del Viaje"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          // MAPA SUPERIOR
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.passengerOrigin,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.uniride.app',
                ),
                // Ruta punteada para caminar al punto de encuentro
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
                    // Yo (Pasajero)
                    Marker(
                      point: widget.passengerOrigin,
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          Text("Tú", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Punto de Encuentro
                    Marker(
                      point: pickupPoint,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                          Text("Recogida", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TARJETA DE DETALLES INFERIOR
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fila Superior: Hora y Precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hora de Salida", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(timeString,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Tarifa", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text("\$${trip.price.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 15),

                // Info Conductor
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 20,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.driverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("${trip.vehicle['placa']} • ${trip.vehicle['modelo']} • ${trip.vehicle['color']}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 25),

                // Sección de Comentarios (Si existen)
                if (trip.routeDescription.isNotEmpty) ...[
                  const Text("Comentarios del conductor:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    margin: const EdgeInsets.only(top: 5, bottom: 15),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      trip.routeDescription,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],

                // Direcciones
                _infoRow(Icons.place, "Punto de encuentro:", trip.origin['name']),
                const SizedBox(height: 10),
                _infoRow(Icons.flag, "Destino final:", trip.destination['name']),

                const SizedBox(height: 25),

                // Botón Cancelar Solicitud
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _cancelTrip,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: const Text("Cancelar Solicitud", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}