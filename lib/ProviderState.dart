import 'package:flutter/material.dart';

class ProviderState extends ChangeNotifier {

  // -- Variables de Estado --
  String? _selectedUniversity;

  // -- Getters --
  String? get selectedUniversity => _selectedUniversity;

  // -- Lógica de Negocio --

  // Función para guardar la universidad elegida
  void selectUniversity(String universityName) {
    _selectedUniversity = universityName;
    debugPrint("Universidad seleccionada: $_selectedUniversity");

    // Aquí más adelante podríamos cargar temas de color específicos
    // o filtrar viajes solo de esa U.

    notifyListeners();
  }
}