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

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    setState(() {
      usuarios = snapshot.docs;
      cargando = false;
    });
  }

  void copiarTexto(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enlace copiado al portapapeles'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> eliminarUsuarioYDatos(String userId, String nombre) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Deseas eliminar a "$nombre" y todos sus datos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Eliminar apuestas relacionadas
    final apuestasSnapshot = await FirebaseFirestore.instance
        .collection('apuestas')
        .where('usuarioId', isEqualTo: userId)
        .get();

    for (var doc in apuestasSnapshot.docs) {
      await doc.reference.delete();
    }

    // Eliminar usuario
    await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usuario "$nombre" y sus registros fueron eliminados.'),
        backgroundColor: Colors.redAccent.shade700,
      ),
    );

    await cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Lista de Apostadores', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEDEC), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : usuarios.isEmpty
                ? const Center(child: Text('No hay usuarios registrados'))
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
                        elevation: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.black87),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Eliminar apostador',
                                    onPressed: () => eliminarUsuarioYDatos(id, nombre),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.fingerprint, size: 20, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('ID: $id', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.link, size: 20, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      url,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.redAccent.shade700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    color: Colors.redAccent.shade700,
                                    tooltip: 'Copiar enlace',
                                    onPressed: () => copiarTexto(url),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: QrImageView(
                                  data: url,
                                  size: 160,
                                  backgroundColor: Colors.white,
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
