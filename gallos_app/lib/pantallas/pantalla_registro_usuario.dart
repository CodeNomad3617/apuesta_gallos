import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PantallaRegistroUsuario extends StatefulWidget {
  const PantallaRegistroUsuario({super.key});

  @override
  State<PantallaRegistroUsuario> createState() => _PantallaRegistroUsuarioState();
}

class _PantallaRegistroUsuarioState extends State<PantallaRegistroUsuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _saldoController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  String? enlaceGenerado;
  bool guardando = false;

  void guardarUsuario() async {
    final nombre = _nombreController.text.trim();
    final saldo = double.tryParse(_saldoController.text.trim()) ?? 0;
    final id = _idController.text.trim();

    if (nombre.isEmpty || id.isEmpty || saldo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos correctamente.')),
      );
      return;
    }

    setState(() => guardando = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(id).set({
        'nombre': nombre,
        'saldoInicial': saldo,
        'saldoActual': saldo,
        'apuestas': [],
      });

      setState(() {
        enlaceGenerado = 'https://gallos-app-6ac95.web.app/usuario.html?id=$id';
        guardando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con éxito')),
      );
    } catch (e) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Widget buildInput({required String label, required TextEditingController controller, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.input),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Apostador'),
        centerTitle: true,
        backgroundColor: redAccent,
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
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add_alt_1, size: 30, color: redAccent),
                    const SizedBox(width: 8),
                    const Text('Datos del nuevo apostador',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                buildInput(label: 'Nombre del usuario', controller: _nombreController),
                buildInput(label: 'ID único (ej. peque123)', controller: _idController),
                buildInput(label: 'Saldo inicial', controller: _saldoController, type: TextInputType.number),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardarUsuario,
                    icon: guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      guardando ? 'Guardando...' : 'Guardar y generar QR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (enlaceGenerado != null) ...[
                  const Text('Link generado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(enlaceGenerado!, style: const TextStyle(color: Colors.blue)),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: enlaceGenerado!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
