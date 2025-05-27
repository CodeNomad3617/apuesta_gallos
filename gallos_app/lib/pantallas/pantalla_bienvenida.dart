import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_home.dart';

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideButton;
  bool isAppEnabled = true; // Variable para controlar si la app está habilitada

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideButton = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    listenAppStatus();  // Escuchar los cambios en Firestore
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Escuchar el estado de la app en Firestore (tiempo real)
  void listenAppStatus() {
    FirebaseFirestore.instance
        .collection('config')
        .doc('appSettings')  // El documento que contiene el estado de la app
        .snapshots() // Usamos snapshots para escuchar en tiempo real
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isAppEnabled = snapshot['appEnabled']; // Actualizamos el estado de la app
        });
      }
    });
  }

  void _irAHome() {
    if (isAppEnabled) {
      // Si la app está habilitada, navega a la pantalla principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PantallaHome()),
      );
    } else {
      // Si la app está deshabilitada, muestra un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La aplicación está deshabilitada temporalmente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFAFA), Color(0xFFFFEBEE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const Spacer(),
                // Logo gallo o emoji
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.shade100,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    '🐓',
                    style: TextStyle(fontSize: 100),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'ApuestArte',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(blurRadius: 4, offset: Offset(2, 2), color: Colors.black26),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Control de apuestas profesional\ny fácil de usar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                SlideTransition(
                  position: _slideButton,
                  child: ElevatedButton(
                    onPressed: _irAHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      shadowColor: Colors.redAccent,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Entrar a la app',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
