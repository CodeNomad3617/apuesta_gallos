import 'package:flutter/material.dart';
import 'pantalla_registro_usuario.dart';
import 'pantalla_registro_apuesta.dart';
import 'pantalla_historial_usuario.dart';
import 'pantalla_editar_apuestas.dart';
import 'pantalla_lista_apostadores.dart';
import 'pantalla_cerrar_apuestas.dart';

class PantallaHome extends StatelessWidget {
  const PantallaHome({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {
        'titulo': 'Registrar Apostador',
        'icono': Icons.person_add_alt_rounded,
        'color': Color(0xFF2E7D32), // Verde casino
        'pantalla': const PantallaRegistroUsuario(),
      },
      {
        'titulo': 'Registrar Apuesta',
        'icono': Icons.attach_money_rounded,
        'color': Color(0xFFC2185B), // Rojo apuesta
        'pantalla': const PantallaRegistroApuesta(),
      },
      {
        'titulo': 'Historial',
        'icono': Icons.history_rounded,
        'color': Color(0xFF512DA8), // Púrpura premium
        'pantalla': const PantallaHistorialUsuario(),
      },
      {
        'titulo': 'Editar Apuestas',
        'icono': Icons.edit_rounded,
        'color': Color(0xFF0288D1), // Azul profesional
        'pantalla': const PantallaEditarApuestas(),
      },
      {
        'titulo': 'Lista Apostadores',
        'icono': Icons.people_alt_rounded,
        'color': Color(0xFFF57C00), // Naranja llamativo
        'pantalla': const PantallaListaApostadores(),
      },
      {
        'titulo': 'Cerrar Apuestas',
        'icono': Icons.lock_clock_rounded,
        'color': Color(0xFF00796B), // Verde esmeralda
        'pantalla': const PantallaCerrarApuestas(),
      },
    ];

    return Scaffold(
      backgroundColor: Color(0xFF121212), // Fondo oscuro premium
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino_rounded, color: Colors.amber[600]),
            SizedBox(width: 12),
            Text(
              'CAP PRO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              'Panel de Control Principal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.amber[200],
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.1,
                children: opciones.map((opcion) {
                  return _buildCasinoCard(
                    context: context,
                    title: opcion['titulo'] as String,
                    icon: opcion['icono'] as IconData,
                    color: opcion['color'] as Color,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => opcion['pantalla'] as Widget,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCasinoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.25),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}