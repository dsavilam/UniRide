import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <--- Importante para leer el estado
import './ProviderState.dart'; // <--- Importante para acceder a VehicleModel y lógica
import './ScheduleTripPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPassenger = true;

  // Estados para la vista del conductor
  String? _selectedVehiclePlaca; // Solo guardamos la placa seleccionada
  bool _showAddVehicleForm = false;

  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos (Perfil y Vehículos) desde Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProviderState>();
      provider.loadUserProfile();
      provider.loadVehicles();
    });
  }

  @override
  void dispose() {
    _placaController.dispose();
    _colorController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  // Método para añadir un vehículo a Firebase
  void _addVehicle() async {
    final placa = _placaController.text.trim().toUpperCase();
    final modelo = _modeloController.text.trim();
    final color = _colorController.text.trim();

    if (placa.isEmpty || modelo.isEmpty || color.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos")),
      );
      return;
    }

    if (placa.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("La placa debe tener exactamente 6 caracteres")),
      );
      return;
    }

    // Llamada a Firebase a través del Provider
    final provider = context.read<ProviderState>();

    // Validamos localmente si ya existe en la lista descargada
    if (provider.vehicles.any((v) => v.placa == placa)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este vehículo ya está registrado")),
      );
      return;
    }

    final success = await provider.addVehicle(placa, modelo, color);

    if (success) {
      setState(() {
        _selectedVehiclePlaca = placa; // Seleccionamos el nuevo automáticamente
        _placaController.clear();
        _colorController.clear();
        _modeloController.clear();
        _showAddVehicleForm = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehículo agregado correctamente")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar en la base de datos")),
        );
      }
    }
  }

  void _selectVehicle(String placa) {
    setState(() {
      _selectedVehiclePlaca = placa;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el provider para actualizar la lista de vehículos
    final provider = context.watch<ProviderState>();
    final myVehicles = provider.vehicles;
    final userName = provider.userProfile?['fullName'] ?? '¡Bienvenid@!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      userName.contains(' ')
                          ? "Hola, ${userName.split(' ')[0]}"
                          : userName,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.account_circle,
                        color: Colors.grey[600], size: 30),
                    onPressed: () {
                      Navigator.pushNamed(context, '/PROFILE');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle Switch (Pasajero / Conductor)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
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
                            child: Text(
                              'Soy pasajero',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isPassenger
                                      ? Colors.black
                                      : Colors.grey[600]),
                            ),
                          ),
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
                            child: Text(
                              'Soy conductor',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !_isPassenger
                                      ? Colors.black
                                      : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _isPassenger
                  ? _buildPassengerView()
                  : _buildDriverView(myVehicles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿A dónde te diriges?',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Buscar destino...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ),
              Icon(CupertinoIcons.mic_fill, color: Colors.grey[600]),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Estos wheels te sirven',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: ListView.separated(
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildWheelCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDriverView(List<VehicleModel> myVehicles) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tus vehículos registrados',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona el vehículo que vas a usar hoy',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Selector de vehículos con animación
        _buildVehicleSelector(myVehicles),

        const SizedBox(height: 40),

        GestureDetector(
          onTap: () {
            setState(() {
              _showAddVehicleForm = !_showAddVehicleForm;
            });
          },
          child: Row(
            children: [
              Icon(
                _showAddVehicleForm
                    ? Icons.remove_circle_outline
                    : Icons.add_circle_outline,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Añade un vehículo',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        if (_showAddVehicleForm) ...[
          const SizedBox(height: 20),
          _buildInlineFormField(
            label: 'Placa:',
            controller: _placaController,
            showClearIcon: true,
            maxLength: 6,
          ),
          _buildInlineFormField(
            label: 'Color del vehículo:',
            controller: _colorController,
          ),
          _buildInlineFormField(
            label: 'Modelo:',
            controller: _modeloController,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _addVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
              // 1. Validar selección
              if (_selectedVehiclePlaca == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Por favor selecciona un vehículo")),
                );
                return;
              }

              // 2. Navegar
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleTripPage(
                    selectedVehicle: _selectedVehiclePlaca,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              'Programar viaje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No tienes vehículos registrados. Añade uno abajo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: vehicles.map((vehicle) {
        final isSelected = _selectedVehiclePlaca == vehicle.placa;

        // --- ANIMACIÓN DE SELECCIÓN ---
        return GestureDetector(
          onTap: () => _selectVehicle(vehicle.placa),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 160, // Ancho fijo para consistencia
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // Si está seleccionado, fondo azul muy claro. Si no, gris claro.
              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              // Borde azul y más grueso si está seleccionado
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                // Animación de escala para el icono
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Image.asset(
                    'assets/car-shape.png',
                    height: 40,
                    width: 80,
                    fit: BoxFit.contain,
                    color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_circle, color: primaryColor, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.placa,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            vehicle.modelo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInlineFormField({
    required String label,
    required TextEditingController controller,
    bool showClearIcon = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              inputFormatters: maxLength != null
                  ? [
                      LengthLimitingTextInputFormatter(maxLength),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ]
                  : null,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                counterText: '',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                suffixIcon: showClearIcon
                    ? IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.grey),
                        onPressed: () => controller.clear(),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Viaje Andes -> Casa',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                'Juan Perez • 4.8★',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          Text(
            '5:30 PM',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
