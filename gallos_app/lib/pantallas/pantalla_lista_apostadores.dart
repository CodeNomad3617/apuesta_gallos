import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PantallaListaApostadores extends StatefulWidget {
  const PantallaListaApostadores({super.key});

  @override
  State<PantallaListaApostadores> createState() => _PantallaListaApostadoresState();
}

class _PantallaListaApostadoresState extends State<PantallaListaApostadores> {
  List<QueryDocumentSnapshot> usuarios = [];
  bool cargando = true;

  // Colores para el tema naranja llamativo
  final Color primaryOrange = const Color(0xFFFF6D00);
  final Color darkOrange = const Color(0xFFE65100);
  final Color lightOrange = const Color(0xFFFFE0B2);
  final Color accentOrange = const Color(0xFFFF9800);
  final Color backgroundGradientStart = const Color(0xFFFFF3E0);
  final Color backgroundGradientEnd = const Color(0xFFFFE0B2);

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    setState(() => cargando = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
      setState(() {
        usuarios = snapshot.docs;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  void copiarTexto(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enlace copiado al portapapeles'),
        backgroundColor: primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> eliminarUsuarioYDatos(String userId, String nombre) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas eliminar a "$nombre" y todos sus datos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: primaryOrange),
      ),
    );

    try {
      // Eliminar apuestas relacionadas
      final apuestasSnapshot = await FirebaseFirestore.instance
          .collection('apuestas')
          .where('usuarioId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in apuestasSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Eliminar usuario
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario "$nombre" y sus registros fueron eliminados.'),
          backgroundColor: primaryOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await cargarUsuarios();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkOrange,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 8,
        shadowColor: darkOrange.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        title: const Text('Lista de Apostadores', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5
          )
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundGradientStart, backgroundGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: cargando
            ? Center(
                child: CircularProgressIndicator(color: primaryOrange),
              )
            : usuarios.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: primaryOrange.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay usuarios registrados',
                          style: TextStyle(
                            fontSize: 18,
                            color: darkOrange.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: usuarios.length,
                    itemBuilder: (_, index) {
                      final usuario = usuarios[index];
                      final data = usuario.data() as Map<String, dynamic>;
                      final id = usuario.id;
                      final nombre = data['nombre'] ?? id;
                      final url = 'https://gallos-app-6ac95.web.app/usuario.html?id=$id';

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 16),
                        shadowColor: darkOrange.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: lightOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: primaryOrange, width: 1.5),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: darkOrange,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: darkOrange,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    tooltip: 'Eliminar apostador',
                                    onPressed: () => eliminarUsuarioYDatos(id, nombre),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.fingerprint,
                                    size: 20,
                                    color: primaryOrange.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ID: $id',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 20,
                                    color: primaryOrange.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      url,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: darkOrange,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryOrange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: primaryOrange.withOpacity(0.3)),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        size: 20,
                                        color: darkOrange,
                                      ),
                                    ),
                                    tooltip: 'Copiar enlace',
                                    onPressed: () => copiarTexto(url),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryOrange.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                        offset: const Offset(2, 2),
                                      )
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: url,
                                    size: 140,
                                    backgroundColor: Colors.white,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: darkOrange,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: darkOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}