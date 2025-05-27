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
        'icono': Icons.person_add_alt_1,
        'pantalla': const PantallaRegistroUsuario(),
      },
      {
        'titulo': 'Registrar Apuesta',
        'icono': Icons.edit_note,
        'pantalla': const PantallaRegistroApuesta(),
      },
      {
        'titulo': 'Ver Historial',
        'icono': Icons.history,
        'pantalla': const PantallaHistorialUsuario(),
      },
      {
        'titulo': 'Editar / Eliminar Apuestas',
        'icono': Icons.settings,
        'pantalla': const PantallaEditarApuestas(),
      },
      {
        'titulo': 'Lista de Apostadores',
        'icono': Icons.qr_code,
        'pantalla': const PantallaListaApostadores(),
      },
      {
        'titulo': 'Cerrar Apuestas',
        'icono': Icons.check_circle,
        'pantalla': const PantallaCerrarApuestas(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🐓', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('Control de Apuestas de Gallos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEDEC), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: opciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final opcion = opciones[index];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(opcion['icono'] as IconData, size: 32, color: Colors.redAccent.shade700),
                  title: Text(
                    opcion['titulo'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => opcion['pantalla'] as Widget),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
