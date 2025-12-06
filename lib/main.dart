import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';
import './SelectUniversityPage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProviderState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Carpooling Universitario',
        theme: ThemeData(
          // Usamos un esquema de color limpio (Blanco/Negro) como base
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        initialRoute: '/SELECT_UNI',
        routes: {
          '/SELECT_UNI': (context) => const SelectUniversityPage(),
          // Aquí iremos agregando las siguientes rutas (Login, Home, etc.)
        },
      ),
    ),
  );
}