import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import './ProviderState.dart';
import './ScheduleTripPage.dart';
import './TripDetailsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPassenger = true;

  // --- VARIABLES PASAJERO ---
  final TextEditingController _originSearchCtrl = TextEditingController();
  final TextEditingController _destSearchCtrl = TextEditingController();
  LatLng? _passengerOrigin;
  LatLng? _passengerDestination;
  Timer? _debounce;
  bool _isSearchingAddress = false;
  bool _isLoadingLocation = false;

  // --- VARIABLES CONDUCTOR ---
  String? _selectedVehiclePlaca;
  bool _showAddVehicleForm = false;
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProviderState>();
      provider.loadUserProfile(); // Esto cargará la foto si existe
      provider.loadVehicles();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _originSearchCtrl.dispose();
    _destSearchCtrl.dispose();
    _placaController.dispose();
    _colorController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  // --- LÓGICA GPS (GEOLOCATOR) ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _passengerOrigin = LatLng(position.latitude, position.longitude);
          _originSearchCtrl.text = "Mi Ubicación Actual";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo GPS: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // --- LÓGICA DE BÚSQUEDA DE DIRECCIONES (NOMINATIM) ---
  List<dynamic> _addressSuggestions = [];
  bool _isSelectingOrigin = true;

  void _onSearchChanged(String query, bool isOrigin) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => _isSelectingOrigin = isOrigin);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _fetchAddressSuggestions(query);
      } else {
        setState(() => _addressSuggestions = []);
      }
    });
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    setState(() => _isSearchingAddress = true);
    const String viewBox = "-74.30,4.40,-73.90,5.00";

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '10',
      'viewbox': viewBox,
      'bounded': '1',
      'addressdetails': '1'
    });

    try {
      final response =
      await http.get(uri, headers: {'User-Agent': 'com.uniride.app'});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _addressSuggestions = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error geocoding: $e");
    } finally {
      if (mounted) setState(() => _isSearchingAddress = false);
    }
  }

  void _selectSuggestion(dynamic suggestion) {
    final lat = double.parse(suggestion['lat']);
    final lon = double.parse(suggestion['lon']);
    final displayName = suggestion['display_name'].toString().split(',')[0];

    setState(() {
      if (_isSelectingOrigin) {
        _passengerOrigin = LatLng(lat, lon);
        _originSearchCtrl.text = displayName;
      } else {
        _passengerDestination = LatLng(lat, lon);
        _destSearchCtrl.text = displayName;
        _searchMatchingTrips();
      }
      _addressSuggestions = [];
      FocusScope.of(context).unfocus();
    });
  }

  // --- BÚSQUEDA DE VIAJES (PROVIDER) ---
  void _searchMatchingTrips() {
    if (_passengerDestination != null && _passengerOrigin != null) {
      context.read<ProviderState>().searchTrips(
          passengerOrigin: _passengerOrigin!,
          passengerDest: _passengerDestination!);
    } else if (_passengerOrigin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Necesitamos tu origen para buscar viajes cercanos")));
    }
  }

  // --- RESERVA Y NAVEGACIÓN ---
  void _handleTripSelection(TripModel trip) async {
    if (_passengerOrigin == null) {
      _getCurrentLocation();
      return;
    }

    final provider = context.read<ProviderState>();
    final success = await provider.bookTrip(trip.id, trip.availableSeats);

    if (success && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TripDetailsPage(
                  trip: trip, passengerOrigin: _passengerOrigin!)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
          Text("No se pudo reservar el viaje (quizás ya no hay cupo)")));
    }
  }

  // --- MÉTODOS CONDUCTOR ---
  void _addVehicle() async {
    final placa = _placaController.text.trim().toUpperCase();
    final modelo = _modeloController.text.trim();
    final color = _colorController.text.trim();

    if (placa.isEmpty || modelo.isEmpty || color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor completa todos los campos")));
      return;
    }
    if (placa.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("La placa debe tener exactamente 6 caracteres")));
      return;
    }

    final provider = context.read<ProviderState>();
    if (provider.vehicles.any((v) => v.placa == placa)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este vehículo ya está registrado")));
      return;
    }

    final success = await provider.addVehicle(placa, modelo, color);

    if (success) {
      setState(() {
        _selectedVehiclePlaca = placa;
        _placaController.clear();
        _colorController.clear();
        _modeloController.clear();
        _showAddVehicleForm = false;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehículo agregado correctamente")));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error al guardar en la base de datos")));
    }
  }

  void _selectVehicle(String placa) {
    setState(() => _selectedVehiclePlaca = placa);
  }

  // --- UI PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderState>();
    final myVehicles = provider.vehicles;
    final userName = provider.userProfile?['fullName'] ?? '¡Bienvenid@!';
    // Obtenemos la URL de la foto
    final photoUrl = provider.userProfile?['photoUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10), // Ajuste pequeño de margen superior
                // --- HEADER MEJORADO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacio entre texto e imagen
                  crossAxisAlignment: CrossAxisAlignment.center, // Alineación vertical perfecta
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hola,",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            userName.contains(' ')
                                ? userName.split(' ')[0]
                                : userName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.1), // Altura de línea ajustada
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // FOTO DE PERFIL
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/PROFILE'),
                      child: Hero(
                        tag: 'profile-pic', // Animación bonita si en profile usas Hero también
                        child: CircleAvatar(
                          radius: 28, // Tamaño 56px (más grande que antes)
                          backgroundColor: Colors.grey.shade200,
                          // Si hay foto, la muestra. Si no, null.
                          backgroundImage: (photoUrl != null && photoUrl.toString().isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          // Si NO hay foto, muestra el icono
                          child: (photoUrl == null || photoUrl.toString().isEmpty)
                              ? Icon(Icons.person, color: Colors.grey.shade400, size: 32)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                // -----------------------

                const SizedBox(height: 24),

                // Toggle Switch
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPassenger = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPassenger
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: _isPassenger
                                  ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                                  : [],
                            ),
                            child: Center(
                                child: Text('Soy pasajero',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _isPassenger
                                            ? Colors.black
                                            : Colors.grey[600]))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPassenger = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPassenger
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: !_isPassenger
                                  ? [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                                  : [],
                            ),
                            child: Center(
                                child: Text('Soy conductor',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: !_isPassenger
                                            ? Colors.black
                                            : Colors.grey[600]))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Vista Condicional
                _isPassenger
                    ? _buildPassengerView(provider)
                    : _buildDriverView(myVehicles),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- VISTA PASAJERO ---
  Widget _buildPassengerView(ProviderState provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿A dónde te diriges?',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 16),

        // Input Origen (Auto-rellenado por GPS)
        TextField(
          controller: _originSearchCtrl,
          onChanged: (val) => _onSearchChanged(val, true),
          decoration: InputDecoration(
            hintText: 'Tu ubicación actual',
            prefixIcon: _isLoadingLocation
                ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : const Icon(Icons.my_location, color: Colors.blue),
            suffixIcon: IconButton(
              icon: const Icon(Icons.gps_fixed, color: Colors.grey),
              onPressed: _getCurrentLocation,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        // Input Destino (Búsqueda)
        TextField(
          controller: _destSearchCtrl,
          onChanged: (val) => _onSearchChanged(val, false),
          decoration: InputDecoration(
            hintText: 'Buscar destino...',
            prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
            suffixIcon: _isSearchingAddress
                ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // --- LISTA DE SUGERENCIAS ---
        if (_addressSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _addressSuggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Colors.grey),
                  title: Text(
                      suggestion['display_name'].toString().split(',')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(suggestion['display_name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),

        const SizedBox(height: 32),
        const Text('Viajes disponibles para ti',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        const SizedBox(height: 16),

        // Lista de Resultados
        if (provider.isSearchingTrips)
          const Center(child: CircularProgressIndicator())
        else if (provider.foundTrips.isEmpty && _passengerDestination != null)
          const Center(
              child: Text("No se encontraron viajes cercanos a tu ruta.",
                  style: TextStyle(color: Colors.grey)))
        else if (_passengerDestination == null)
            const Center(
                child: Text("Ingresa un destino para buscar.",
                    style: TextStyle(color: Colors.grey)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.foundTrips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = provider.foundTrips[index];
                return _buildTripCard(trip);
              },
            ),
      ],
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final dt = DateTime.fromMillisecondsSinceEpoch(trip.departureTime);
    final timeString =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () => _handleTripSelection(trip),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hacia: ${trip.destination['name']}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Desde: ${trip.origin['name']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                            "${trip.driverName} • ${trip.vehicle['placa']}",
                            style: TextStyle(
                                color: Colors.grey[800], fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeString,
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("\$${trip.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green)),
                Text("${trip.availableSeats} cupos",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- VISTA CONDUCTOR ---
  Widget _buildDriverView(List<VehicleModel> vehicles) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tus vehículos registrados',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Selecciona el vehículo que vas a usar hoy',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        _buildVehicleSelector(vehicles),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () =>
              setState(() => _showAddVehicleForm = !_showAddVehicleForm),
          child: Row(
            children: [
              Icon(
                  _showAddVehicleForm
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  color: Colors.black),
              const SizedBox(width: 8),
              Text('Añade un vehículo',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_showAddVehicleForm) ...[
          const SizedBox(height: 20),
          _buildInlineFormField(
              label: 'Placa:',
              controller: _placaController,
              maxLength: 6,
              showClearIcon: true),
          _buildInlineFormField(label: 'Color:', controller: _colorController),
          _buildInlineFormField(
              label: 'Modelo:', controller: _modeloController),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _addVehicle,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: const Text('Guardar vehículo'),
            ),
          ),
        ],
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedVehiclePlaca == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Selecciona un vehículo")));
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ScheduleTripPage(
                          selectedVehicle: _selectedVehiclePlaca)));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2),
            child: const Text('Programar viaje',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVehicleSelector(List<VehicleModel> vehicles) {
    if (vehicles.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: const Text('No tienes vehículos registrados. Añade uno abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)));
    }
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: vehicles.map((v) {
        final isSelected = _selectedVehiclePlaca == v.placa;
        return GestureDetector(
          onTap: () => _selectVehicle(v.placa),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.0),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]
                  : [],
            ),
            child: Column(children: [
              Image.asset('assets/car-shape.png',
                  height: 40,
                  fit: BoxFit.contain,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700),
              const SizedBox(height: 8),
              Text(v.placa,
                  style: TextStyle(
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                      isSelected ? Colors.blue.shade900 : Colors.black54)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInlineFormField(
      {required String label,
        required TextEditingController controller,
        int? maxLength,
        bool showClearIcon = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: controller,
                  maxLength: maxLength,
                  decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8))))
        ]));
  }
}