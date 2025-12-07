import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import './ProviderState.dart';
import './SelectUniversityPage.dart';
import './SignUpPage.dart';
import './home_page.dart';
import './LoginPage.dart';
import './ProfilePage.dart';
import './ScheduleTripPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificamos si hay usuario logueado
  // Verificamos si hay usuario logueado Y verificado
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Si existe pero no está verificado (o el token es inválido por haber sido borrado), lo sacamos
  if (currentUser != null) {
    try {
      // Forzamos la recarga del usuario para verificar si sigue existiendo en el backend
      await currentUser.reload();
      if (!currentUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        currentUser = null;
      }
    } catch (e) {
      // Si reload falla (ej: user-not-found), cerramos sesión
      await FirebaseAuth.instance.signOut();
      currentUser = null;
    }
  }

  final String rutaInicial = currentUser != null ? '/HOME' : '/SELECT_UNI';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProviderState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UniRide',
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
