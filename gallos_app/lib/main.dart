import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pantallas/pantalla_home.dart';
import 'pantallas/pantalla_bienvenida.dart'; // 👈 asegúrate de tener este archivo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBnj2i68BldCgnbBHchwWIiAWmGsETuTR4",
      authDomain: "gallos-app-6ac95.firebaseapp.com",
      projectId: "gallos-app-6ac95",
      storageBucket: "gallos-app-6ac95.appspot.com",
      messagingSenderId: "1026205994287",
      appId: "1:1026205994287:web:860938c1c7eeaa8c42a5da",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallos App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF3E0),
      ),
      home: const PantallaBienvenida(), // 👈 Pantalla inicial
    );
  }
}
