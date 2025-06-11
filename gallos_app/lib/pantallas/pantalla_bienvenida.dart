import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_home.dart';

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool isAppEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    listenAppStatus();
  }

  void listenAppStatus() {
    FirebaseFirestore.instance
        .collection('config')
        .doc('appSettings')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isAppEnabled = snapshot['appEnabled'];
        });
      }
    });
  }

  void _irAHome() {
    if (isAppEnabled) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PantallaHome()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La aplicación está en mantenimiento. Disculpe las molestias.'),
          backgroundColor: Colors.amber[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[900]!,
              Colors.blueGrey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Elementos decorativos de fondo
              Positioned(
                top: -size.width * 0.2,
                right: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueGrey[800]!.withOpacity(0.1),
                  ),
                ),
              ),
              
              Positioned(
                bottom: -size.width * 0.3,
                left: -size.width * 0.3,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo[900]!.withOpacity(0.1),
                  ),
                ),
              ),
              
              // Contenido principal
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo premium
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.tealAccent.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 80,
                            color: Colors.tealAccent[400],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Título principal
                        Text(
                          'CAP',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                            fontFamily: 'Roboto',
                            shadows: [
                              Shadow(
                                color: Colors.tealAccent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Subtítulo
                        Text(
                          'CONTROL DE APUESTAS\nPROFESIONAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueGrey[200],
                            letterSpacing: 1.5,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Botón de acción
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                30 * (1 - _controller.value),
                              ),
                              child: child,
                            );
                          },
                          child: ElevatedButton(
                            onPressed: _irAHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent[400],
                              foregroundColor: Colors.grey[900],
                              elevation: 15,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              shadowColor: Colors.tealAccent.withOpacity(0.5),
                            ),
                            child: const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Versión y copyright
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '© 2025 CAP. Todos los derechos reservados.',
                      style: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}