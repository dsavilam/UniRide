import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ProviderState>();
    final success = await provider.loginUser(
      usuario: _usuarioCtrl.text,
      password: _passCtrl.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/HOME', (route) => false);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Credenciales inválidas')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            const SizedBox(), // Hide back button if we want to force navigation via "Regístrate" or system back
        actions: [
          // Optional: Close button if it's a modal, but standard nav is fine.
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                    height: 80, // Adjust height as needed
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                // Usuario
                TextFormField(
                  controller: _usuarioCtrl,
                  decoration: InputDecoration(
                    labelText: 'Usuario:',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () => _usuarioCtrl.clear(),
                    ),
                    // Underline border as per image style usually, but standard InputDecoration is fine.
                    // Image shows a line under the input.
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingresa tu usuario';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña:',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ingresa tu contraseña';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Botón Iniciar Sesión
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4A75A2,
                    ), // A muted blue similar to image
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
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // No tienes cuenta? Regístrate
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .start, // Image shows left aligned? No, looks like it might be left or center. Let's stick to left as per standard form flow or center.
                  // Image shows "No tienes una cuenta? Regístrate" aligned left under the button?
                  // Actually, let's center it for better UI balance, or follow image strictly.
                  // Image: Text is below button, left aligned.
                  children: [
                    Text(
                      'No tienes una cuenta? ',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate back to SignUp
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Regístrate',
                        style: TextStyle(
                          color: Colors.blue.shade900,
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
}
