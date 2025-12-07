import 'dart:convert';
import 'dart:async'; // Necesario para el Debouncer (Timer)
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // <--- Importante para ubicación inicial
import './ProviderState.dart';

class ScheduleTripPage extends StatefulWidget {
  final String? selectedVehicle;

  const ScheduleTripPage({super.key, this.selectedVehicle});

  @override
  State<ScheduleTripPage> createState() => _ScheduleTripPageState();
}

class _ScheduleTripPageState extends State<ScheduleTripPage> {
  // --- VARIABLES DEL MAPA ---
  final MapController _mapController = MapController();
  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _isSelectingOrigin = true;

  Timer? _debounce;

  // --- ESTADOS DEL FORMULARIO ---
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Controladores
  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  bool _isPublishing = false;
  bool _isLoadingRoute = false; // Para mostrar carga al buscar dirección

  @override
  void initState() {
    super.initState();
    // Intentar obtener la ubicación actual del conductor al abrir
    _getCurrentLocation();
  }

  // --- OBTENER UBICACIÓN ACTUAL (GPS) ---
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() {
          _origin = LatLng(position.latitude, position.longitude);
          _startingPointController.text = "Mi Ubicación Actual"; // Feedback visual inicial
          _mapController.move(_origin!, 15.0); // Mover cámara
        });

        // Opcional: Obtener dirección real de la ubicación actual
        _getAddressFromLatLng(_origin!).then((address) {
          if(mounted) setState(() => _startingPointController.text = address);
        });
      }
    } catch (e) {
      debugPrint("Error GPS: $e");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _startingPointController.dispose();
    _destinationController.dispose();
    _commentsController.dispose();
    _fareController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // --- GEOCODING INVERSO (COORDENADAS -> TEXTO) ---
  Future<String> _getAddressFromLatLng(LatLng point) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');

      final response = await http.get(url, headers: {'User-Agent': 'com.uniride.app'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Intentamos construir una dirección legible
        String fullAddress = data['display_name'] ?? "Ubicación desconocida";
        List<String> parts = fullAddress.split(',');
        if (parts.length > 3) {
          // Retornamos las primeras 3 partes (ej: Calle, Barrio, Ciudad)
          return "${parts[0]}, ${parts[1]}, ${parts[2]}";
        }
        return fullAddress;
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
  }

  // --- LÓGICA DEL MAPA (TAP) ---
  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    // 1. Actualizamos marcador visualmente
    setState(() {
      if (_isSelectingOrigin) {
        _origin = point;
        _startingPointController.text = "Buscando dirección...";
      } else {
        _destination = point;
        _destinationController.text = "Buscando dirección...";
      }
    });

    // 2. Buscamos la dirección (Async)
    final String address = await _getAddressFromLatLng(point);

    // 3. Actualizamos el texto final
    if (mounted) {
      setState(() {
        if (_isSelectingOrigin) {
          _startingPointController.text = address;
        } else {
          _destinationController.text = address;
        }
      });

      // 4. Si tenemos ambos, trazamos ruta
      if (_origin != null && _destination != null) {
        _getRoute();
      }
    }
  }

  // --- LÓGICA DE BÚSQUEDA (TEXTO -> COORDENADAS) ---
  void _onSearchChanged(String query, bool isOrigin) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Esperamos 1.5s para no saturar la API
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (query.isNotEmpty && query != "Buscando dirección..." && query != "Mi Ubicación Actual") {
        _searchPlace(query, isOrigin);
      }
    });
  }

  Future<void> _searchPlace(String query, bool isOrigin) async {
    setState(() => _isLoadingRoute = true);

    // Bounding Box Bogotá
    const String viewBox = "-74.26,4.46,-73.96,4.84";

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&viewbox=$viewBox&bounded=1'
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'com.uniride.app'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final point = LatLng(lat, lon);

          setState(() {
            if (isOrigin) {
              _origin = point;
            } else {
              _destination = point;
            }
          });

          // Movemos mapa
          _mapController.move(point, 15.0);

          if (_origin != null && _destination != null) {
            _getRoute();
          }
        }
      }
    } catch (e) {
      debugPrint("Error buscando dirección: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // --- OSRM ROUTING ---
  Future<void> _getRoute() async {
    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${_origin!.longitude},${_origin!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry'];
        final List<dynamic> coordinates = geometry['coordinates'];

        setState(() {
          _routePoints = coordinates
              .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo ruta: $e");
    }
  }

  // --- FORMULARIO ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _publishTrip() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Define fecha y hora")));
      return;
    }
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona origen y destino en el mapa")));
      return;
    }
    if (_startingPointController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escribe nombres para los puntos")));
      return;
    }
    if (_fareController.text.isEmpty || _capacityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta tarifa o capacidad")));
      return;
    }

    setState(() => _isPublishing = true);

    final provider = context.read<ProviderState>();

    final bool success = await provider.publishTrip(
      vehiclePlaca: widget.selectedVehicle ?? 'Unknown',
      departureDate: _selectedDate!,
      departureTime: _selectedTime!,
      origin: {
        "lat": _origin!.latitude,
        "lng": _origin!.longitude,
        "name": _startingPointController.text
      },
      destination: {
        "lat": _destination!.latitude,
        "lng": _destination!.longitude,
        "name": _destinationController.text
      },
      price: double.tryParse(_fareController.text) ?? 0,
      capacity: int.tryParse(_capacityController.text) ?? 4,
      comments: _commentsController.text,
      routePolyline: _routePoints.map((p) => [p.latitude, p.longitude]).toList(),
    );

    setState(() => _isPublishing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Viaje publicado!")));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al publicar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Programar viaje'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isLoadingRoute)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- MAPA ---
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Centro inicial Bogotá
                      initialCenter: const LatLng(4.6097, -74.0817),
                      initialZoom: 13.0,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.uniride.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          if (_routePoints.isNotEmpty)
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (_origin != null)
                            Marker(
                              point: _origin!,
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          if (_destination != null)
                            Marker(
                              point: _destination!,
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.flag, color: Colors.blue, size: 40),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Botones flotantes
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "btnOrigin",
                          backgroundColor: _isSelectingOrigin ? Colors.red : Colors.white,
                          child: Icon(Icons.location_on, color: _isSelectingOrigin ? Colors.white : Colors.red),
                          onPressed: () {
                            setState(() => _isSelectingOrigin = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Toca en el mapa para fijar PARTIDA"), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "btnDest",
                          backgroundColor: !_isSelectingOrigin ? Colors.blue : Colors.white,
                          child: Icon(Icons.flag, color: !_isSelectingOrigin ? Colors.white : Colors.blue),
                          onPressed: () {
                            setState(() => _isSelectingOrigin = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Toca en el mapa para fijar DESTINO"), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- FORMULARIO ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Inputs de dirección con búsqueda
                    _buildTextFieldWithIcon(
                      label: 'Punto de Partida:',
                      controller: _startingPointController,
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      hint: "Ej: Universidad de los Andes",
                      onChanged: (val) => _onSearchChanged(val, true),
                    ),
                    const SizedBox(height: 20),

                    _buildTextFieldWithIcon(
                      label: 'Punto de Llegada:',
                      controller: _destinationController,
                      icon: Icons.flag,
                      iconColor: Colors.blue,
                      hint: "Ej: Bulevar Niza",
                      onChanged: (val) => _onSearchChanged(val, false),
                    ),
                    const SizedBox(height: 20),

                    // Fecha y Hora
                    _buildDateField(
                      label: 'Fecha de salida:',
                      value: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : null,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 20),

                    _buildTimeField(
                      label: 'Hora de salida:',
                      value: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : null,
                      onTap: _selectTime,
                    ),
                    const SizedBox(height: 20),

                    // Tarifa y Cupos
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFieldWithIcon(
                            label: 'Tarifa (COP):',
                            controller: _fareController,
                            icon: Icons.attach_money,
                            iconColor: Colors.green,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextFieldWithIcon(
                            label: 'Cupos:',
                            controller: _capacityController,
                            icon: Icons.people,
                            iconColor: Colors.blue,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Comentarios
                    _buildTextFieldWithIcon(
                      label: 'Comentarios / Ruta:',
                      controller: _commentsController,
                      icon: Icons.comment_outlined,
                      iconColor: Colors.grey,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    // Botón
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _publishTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isPublishing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Publicar viaje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildDateField({required String label, String? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(value ?? 'Selecciona una fecha', style: TextStyle(fontSize: 16, color: value != null ? Colors.black87 : Colors.grey[600]))),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({required String label, String? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(value ?? 'Selecciona una hora', style: TextStyle(fontSize: 16, color: value != null ? Colors.black87 : Colors.grey[600]))),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}