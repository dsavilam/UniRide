import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';
import './SelectUniversityPage.dart';
import './SignUpPage.dart'; // <--- Importante
import './HomePage.dart';   // <--- Importante

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProviderState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Carpooling Universitario',
        theme: ThemeData(
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
          '/SIGNUP': (context) => const SignUpPage(), // <--- Nueva ruta
          '/HOME': (context) => const HomePage(),     // <--- Nueva ruta
        },
      ),
    ),
  );
}