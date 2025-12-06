import 'package:flutter/material.dart';

class ProviderState extends ChangeNotifier {
  // -- Variables de Estado --
  String? _selectedUniversity;

  // -- Dominios permitidos --
  final List<String> _allowedDomains = [
    'uexternado.edu.co',
    'urosario.edu.co',
    'javeriana.edu.co',
    'uniandes.edu.co',
  ];

  // -- Getters --
  String? get selectedUniversity => _selectedUniversity;

  // -- Lógica de Negocio --

  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    notifyListeners();
  }

  // Función para validar si el dominio es correcto
  bool validateEmailDomain(String email) {
    final lowerEmail = email.toLowerCase().trim();
    // Verifica si el correo termina en alguno de los dominios de la lista
    return _allowedDomains.any((domain) => lowerEmail.endsWith(domain));
  }

  // Simulación de registro
  Future<bool> registerUser({
    required String nombre,
    required String correo,
    required String usuario,
  }) async {
    // Aquí iría la lógica de backend (Firebase/API)
    debugPrint("Registrando usuario: $nombre ($usuario) - $correo");

    // Simulamos un pequeño delay de red
    await Future.delayed(const Duration(seconds: 1));

    return true; // Retorna true si el registro fue exitoso
  }

  // Simulación de login
  Future<bool> loginUser({
    required String usuario,
    required String password,
  }) async {
    debugPrint("Iniciando sesión: $usuario");
    await Future.delayed(const Duration(seconds: 1));
    // Aquí iría la validación real
    return true;
  }
}
