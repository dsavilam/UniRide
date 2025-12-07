import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class Vehicle {
  final String placa;
  final String modelo;
  final String color;

  Vehicle({required this.placa, required this.modelo, required this.color});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPassenger = true; // Default to passenger

  // Estados para la vista del conductor
  String? _selectedVehiclePlaca = 'ABC123';
  List<Vehicle> _myVehicles = [
    Vehicle(placa: 'ABC123', modelo: 'Chevrolet Spark', color: 'Rojo'),
  ];
  bool _showAddVehicleForm = false; // Controla si se muestra el formulario

  // Controladores para los campos de texto del formulario
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();

  @override
  void dispose() {
    _placaController.dispose();
    _colorController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  // Método para añadir un vehículo
  void _addVehicle() {
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
          content: Text("La placa debe tener exactamente 6 caracteres"),
        ),
      );
      return;
    }

    if (_myVehicles.any((v) => v.placa == placa)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este vehículo ya está registrado")),
      );
      return;
    }

    setState(() {
      _myVehicles.add(Vehicle(placa: placa, modelo: modelo, color: color));
      _selectedVehiclePlaca = placa;
      _placaController.clear();
      _colorController.clear();
      _modeloController.clear();
      _showAddVehicleForm = false; // Ocultar el formulario después de agregar
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vehículo agregado correctamente")),
    );
  }

  // Método para seleccionar un vehículo
  void _selectVehicle(String placa) {
    setState(() {
      _selectedVehiclePlaca = placa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Welcome Header con icono de menú
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '¡Bienvenid@!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onPressed: () {
                      // Acción del menú
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Toggle Switch
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
                                      offset: const Offset(0, 2),
                                    ),
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
                                    : Colors.grey[600],
                              ),
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
                                      offset: const Offset(0, 2),
                                    ),
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
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Contenido condicional según el rol
              _isPassenger ? _buildPassengerView() : _buildDriverView(),
            ],
          ),
        ),
      ),
    );
  }

  // Vista del pasajero
  Widget _buildPassengerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destination Question
        const Text(
          '¿A dónde te diriges?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar
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
                child: Text(
                  'Search',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              Icon(CupertinoIcons.mic_fill, color: Colors.grey[600]),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // "Wheels" Section
        const Text(
          'Estos wheels te sirven',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),

        // List of Wheels
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

  // Vista del conductor
  Widget _buildDriverView() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sección de Vehículos Registrados
        Text(
          'Tus vehículos registrados',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona el vehículo que vas a usar hoy',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Selector de vehículos
        _buildVehicleSelector(),

        const SizedBox(height: 40),

        // Sección "Añade un vehículo" - clickeable
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Mostrar formulario solo si está expandido
        if (_showAddVehicleForm) ...[
          const SizedBox(height: 20),

          // Campos de formulario
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

          // Botón "Agregar vehículo"
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _addVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Agregar vehículo'),
            ),
          ),
        ],

        const SizedBox(height: 40),

        // Botón Principal "Programar viaje"
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedVehiclePlaca == null || _myVehicles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Por favor selecciona un vehículo"),
                  ),
                );
                return;
              }
              debugPrint(
                "Programar viaje presionado con vehículo: $_selectedVehiclePlaca",
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Programando viaje con vehículo: $_selectedVehiclePlaca",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  // Widget que muestra todos los vehículos y permite seleccionar uno
  Widget _buildVehicleSelector() {
    if (_myVehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No tienes vehículos registrados',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _myVehicles.map((vehicle) {
        final isSelected = _selectedVehiclePlaca == vehicle.placa;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _selectVehicle(vehicle.placa);
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey[200] : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? Border.all(color: primaryColor.withOpacity(0.5), width: 2)
                    : Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // Imagen del carro
                  Image.asset(
                    'assets/car-shape.png',
                    height: 40,
                    width: 80,
                    fit: BoxFit.contain,
                    color: Colors
                        .black87, // Optional: tint it if it's an icon/shape
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey[600]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                                  ? Colors.black87
                                  : Colors.black54,
                            ),
                          ),
                          Text(
                            vehicle.modelo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget para los campos de texto con la etiqueta al lado (inline)
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
                counterText: '', // Ocultar el contador de caracteres
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
                'Title',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Description',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          Text(
            '9:41 AM',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
