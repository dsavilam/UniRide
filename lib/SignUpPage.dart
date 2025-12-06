import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    _celularCtrl.dispose();
    super.dispose();
  }

  void _submitRegistration() async {
    // 1. Validar formulario visualmente
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ProviderState>();

    // 2. Intentar registrar (Simulado en el Provider)
    final success = await provider.registerUser(
      nombre: "${_nombreCtrl.text} ${_apellidoCtrl.text}",
      correo: _correoCtrl.text,
      usuario: _usuarioCtrl.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // 3. Navegar al HOME y borrar el historial para que no puedan volver atrás al registro
      Navigator.of(context).pushNamedAndRemoveUntil('/HOME', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar. Intenta nuevamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider para validaciones (sin escuchar cambios, solo lectura)
    final provider = context.read<ProviderState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/UniRideLogoNOBG.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Regístrate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // -- Nombre --
                _buildTextField(
                  label: 'Nombre',
                  controller: _nombreCtrl,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // -- Apellidos --
                _buildTextField(
                  label: 'Apellidos',
                  controller: _apellidoCtrl,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // -- Correo Institucional --
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!provider.validateEmailDomain(value)) {
                      return 'Usa un correo institucional válido (ej: @uniandes.edu.co)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // -- Usuario --
                _buildTextField(
                  label: 'Nombre de usuario',
                  controller: _usuarioCtrl,
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),

                // -- Contraseña --
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // -- Celular --
                TextFormField(
                  controller: _celularCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu celular';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // -- Botón Registrarme --
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Registrarme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // -- Ya tienes cuenta? --
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes una cuenta? '),
                    GestureDetector(
                      onTap: () {
                        // Aquí iría la navegación al Login
                        Navigator.pushNamed(context, '/LOGIN');
                      },
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para crear inputs simples y no repetir código
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      },
    );
  }
}
