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

  // Definimos los colores estilo casino
  final Color verdeCasino = Color(0xFF00A65A); // Verde brillante estilo casino
  final Color verdeOscuroCasino = Color(0xFF008040); // Verde más oscuro para contrastes
  final Color doradoCasino = Color(0xFFFFD700); // Dorado para acentos

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
        SnackBar(
          content: Text('Usuario registrado con éxito'),
          backgroundColor: verdeCasino,
        ),
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
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(Icons.input, color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: verdeCasino, width: 2), // Borde verde casino al enfocar
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REGISTRO DE APOSTADOR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            )),
        centerTitle: true,
        backgroundColor: verdeCasino, // Usamos el verde casino
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_add_alt_1,
                                size: 32, color: verdeCasino), // Icono verde casino
                            const SizedBox(width: 12),
                            Text('DATOS DEL APOSTADOR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[800],
                                )),
                          ],
                        ),
                        const SizedBox(height: 24),
                        buildInput(
                            label: 'Nombre completo', controller: _nombreController),
                        buildInput(
                            label: 'ID único (ej. peque123)',
                            controller: _idController),
                        buildInput(
                            label: 'Saldo inicial',
                            controller: _saldoController,
                            type: TextInputType.number),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: guardando ? null : guardarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verdeCasino, // Botón verde casino
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: verdeOscuroCasino.withOpacity(0.4),
                    ),
                    child: guardando
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_alt, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'GUARDAR Y GENERAR QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (enlaceGenerado != null) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text('ENLACE GENERADO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            )),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SelectableText(
                            enlaceGenerado!,
                            style: TextStyle(
                              color: verdeCasino, // Texto verde casino
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: enlaceGenerado!,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: verdeCasino, // Ojos del QR en verde casino
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.grey[800]!,
                            ),
                          ),
                        ),
                      ],
                    ),
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