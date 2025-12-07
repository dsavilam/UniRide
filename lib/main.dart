import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import './ProviderState.dart';
import './SelectUniversityPage.dart';
import './SignUpPage.dart';
import './HomePage.dart';
import './LoginPage.dart';
import './ProfilePage.dart';
import './ScheduleTripPage.dart'; // <--- 1. Importamos la nueva pantalla

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
          '/SIGNUP': (context) => const SignUpPage(),
          '/HOME': (context) => const HomePage(),
          '/LOGIN': (context) => const LoginPage(),
          '/PROFILE': (context) => const ProfilePage(),
          '/SCHEDULE': (context) => const ScheduleTripPage(), // <--- 2. Agregamos la ruta
        },
      ),
    ),
  );
}