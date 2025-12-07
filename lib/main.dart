import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- Importante
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import './ProviderState.dart';
import './SelectUniversityPage.dart';
import './SignUpPage.dart';
import './HomePage.dart';
import './LoginPage.dart';
import './ProfilePage.dart';
import './ScheduleTripPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificamos si hay usuario logueado
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final String rutaInicial = currentUser != null ? '/HOME' : '/SELECT_UNI';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProviderState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Carpooling Universitario',
        // Configuración de localización
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés
        ],
        locale: const Locale('es', 'ES'),
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
        initialRoute: rutaInicial, // <--- Usamos la variable calculada
        routes: {
          '/SELECT_UNI': (context) => const SelectUniversityPage(),
          '/SIGNUP': (context) => const SignUpPage(),
          '/HOME': (context) => const HomePage(),
          '/LOGIN': (context) => const LoginPage(),
          '/PROFILE': (context) => const ProfilePage(),
          '/SCHEDULE': (context) => const ScheduleTripPage(),
        },
      ),
    ),
  );
}