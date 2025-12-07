import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ScheduleTripPage extends StatefulWidget {
  final String? selectedVehicle;
  
  const ScheduleTripPage({super.key, this.selectedVehicle});

  @override
  State<ScheduleTripPage> createState() => _ScheduleTripPageState();
}

class _ScheduleTripPageState extends State<ScheduleTripPage> {
  // Estados del formulario
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isToHome = true; // true = Hacia mi casa, false = Hacia la universidad
  
  // Controladores de texto
  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();

  @override
  void dispose() {
    _startingPointController.dispose();
    _destinationController.dispose();
    _commentsController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  // Método para seleccionar fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Método para seleccionar hora
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Método para publicar viaje
  void _publishTrip() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor selecciona una fecha de salida")));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor selecciona una hora de salida")));
      return;
    }
    if (_startingPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor ingresa un punto de partida")));
      return;
    }
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor ingresa un punto de llegada")));
      return;
    }
    if (_fareController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor ingresa una tarifa")));
      return;
    }

    // Aquí iría la lógica para publicar el viaje
    debugPrint("Publicando viaje con vehículo: ${widget.selectedVehicle}");
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Viaje publicado correctamente")));
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Espacio para el mapa (en blanco por ahora)
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  'Mapa',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            
            // Formulario de viaje
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Fecha de salida
                    _buildDateField(
                      label: 'Fecha de salida:',
                      value: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : null,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 20),

                    // Campo Hora de salida
                    _buildTimeField(
                      label: 'Hora de salida:',
                      value: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : null,
                      onTap: _selectTime,
                    ),
                    const SizedBox(height: 20),

                    // Campo Tarifa
                    _buildTextFieldWithIcon(
                      label: 'Tarifa:',
                      controller: _fareController,
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Selector de dirección
                    _buildDirectionSelector(),
                    const SizedBox(height: 20),

                    // Campo Punto de partida
                    _buildTextFieldWithIcon(
                      label: 'Punto de partida:',
                      controller: _startingPointController,
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                    ),
                    const SizedBox(height: 20),

                    // Campo Punto de llegada
                    _buildTextFieldWithIcon(
                      label: 'Punto de llegada:',
                      controller: _destinationController,
                      icon: Icons.location_on,
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 20),

                    // Campo Comentarios
                    _buildTextFieldWithIcon(
                      label: 'Comentarios:',
                      controller: _commentsController,
                      icon: Icons.comment_outlined,
                      iconColor: Colors.grey,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),

                    // Botón Publicar viaje
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _publishTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Publicar viaje',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
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

  // Widget para campo de fecha
  Widget _buildDateField({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Selecciona una fecha',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para campo de hora
  Widget _buildTimeField({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Selecciona una hora',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para selector de dirección
  Widget _buildDirectionSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isToHome = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isToHome ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _isToHome
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Hacia mi casa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isToHome ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isToHome = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isToHome ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: !_isToHome
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Hacia la universidad',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: !_isToHome ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para campo de texto con icono
  Widget _buildTextFieldWithIcon({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

