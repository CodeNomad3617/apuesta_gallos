import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class PantallaHistorialUsuario extends StatefulWidget {
  const PantallaHistorialUsuario({super.key});

  @override
  State<PantallaHistorialUsuario> createState() => _PantallaHistorialUsuarioState();
}

class _PantallaHistorialUsuarioState extends State<PantallaHistorialUsuario> {
  final _idController = TextEditingController();
  Map<String, dynamic>? usuarioData;
  String? usuarioId;

  void buscarUsuario() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuario "$id" no encontrado.')));
      return;
    }

    setState(() {
      usuarioId = id;
      usuarioData = doc.data();
    });
  }

  Future<void> generarPDF() async {
    if (usuarioData == null || usuarioId == null) return;

    final pdf = pw.Document();
    final apuestas = List<Map<String, dynamic>>.from(usuarioData!['apuestas'] ?? []);

    // Contar las apuestas ganadas, perdidas y empatadas
    int totalApuestas = apuestas.length;
    int ganadas = apuestas.where((ap) => ap['resultado'] == 'Ganó').length;
    int perdidas = apuestas.where((ap) => ap['resultado'] == 'Perdió').length;
    int empatadas = apuestas.where((ap) => ap['resultado'] == 'Empate').length;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen de apuestas - ${usuarioData!['nombre']}', style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 10),
              pw.Text('ID: $usuarioId'),
              pw.Text('Saldo inicial: \$${usuarioData!['saldoInicial']}'),
              pw.Text('Saldo actual: \$${usuarioData!['saldoActual']}'),
              pw.SizedBox(height: 20),
              pw.Text('Estadísticas de apuestas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total de Apuestas: $totalApuestas'),
              pw.Text('Apuestas Ganadas: $ganadas'),
              pw.Text('Apuestas Perdidas: $perdidas'),
              pw.Text('Apuestas Empatadas: $empatadas'),
              pw.SizedBox(height: 20),
              pw.Text('Apuestas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...apuestas.map((ap) {
                return pw.Text(
                  'Torneo: ${ap['pelea']} | #${ap['numeroApuesta']} | \$${ap['monto']} | Color: ${ap['color']} | Resultado: ${ap['resultado']} | Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']))}',
                  style: pw.TextStyle(fontSize: 10),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/historial_${usuarioId!}.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF guardado en: ${file.path}')));
    OpenFile.open(file.path);
  }

  Widget buildColorCircle(String color) {
    final colorCode = color.toLowerCase() == 'rojo'
        ? Colors.red
        : color.toLowerCase() == 'verde'
            ? Colors.green
            : Colors.grey;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: colorCode, shape: BoxShape.circle),
      margin: const EdgeInsets.only(right: 6),
    );
  }

  Widget buildResultadoBadge(String? resultado) {
    Color badgeColor;
    Icon icon;

    switch (resultado) {
      case 'Ganó':
        badgeColor = Colors.green.shade100;
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 16);
        break;
      case 'Perdió':
        badgeColor = Colors.red.shade100;
        icon = const Icon(Icons.cancel, color: Colors.red, size: 16);
        break;
      case 'Empate':
        badgeColor = Colors.orange.shade100;
        icon = const Icon(Icons.remove_circle, color: Colors.orange, size: 16);
        break;
      default:
        badgeColor = Colors.grey.shade200;
        icon = const Icon(Icons.help_outline, size: 16);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(resultado ?? 'Pendiente', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent.shade700;
    final apuestas = (usuarioData?['apuestas'] ?? []) as List<dynamic>;
    final saldoActual = usuarioData?['saldoActual'];

    // Contar las apuestas ganadas, perdidas y empatadas
    int totalApuestas = apuestas.length;
    int ganadas = apuestas.where((ap) => ap['resultado'] == 'Ganó').length;
    int perdidas = apuestas.where((ap) => ap['resultado'] == 'Perdió').length;
    int empatadas = apuestas.where((ap) => ap['resultado'] == 'Empate').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Apuestas'),
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
          child: Column(
            children: [
              // Datos del Usuario y opciones
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'ID del usuario',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text('Consultar',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          onPressed: buscarUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Estadísticas de peleas: Total, ganadas, perdidas y empatadas
              if (usuarioData != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Total de Peleas: $totalApuestas', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Ganadas: $ganadas', style: const TextStyle(color: Colors.green)),
                        Text('Perdidas: $perdidas', style: const TextStyle(color: Colors.red)),
                        Text('Empatadas: $empatadas', style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Datos del usuario y acción de exportar PDF
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      'Usuario: ${usuarioData!['nombre']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Saldo actual: \$${saldoActual.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.black87),
                      tooltip: 'Exportar a PDF',
                      onPressed: generarPDF,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Lista de apuestas registradas
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Apuestas registradas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 10),

                // Mostrar la lista de apuestas
                Expanded(
                  child: ListView.builder(
                    itemCount: apuestas.length,
                    itemBuilder: (_, index) {
                      final ap = apuestas[index];
                      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.stacked_bar_chart, color: Colors.deepPurple),
                          title: Text('Pelea torneo: ${ap['pelea']} | Número de apuesta del usuario: ${ap['numeroApuesta']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  buildColorCircle(ap['color']),
                                  Text('Color elegido: ${ap['color']}'),
                                ],
                              ),
                              Text('Monto apostado: \$${ap['monto']}'),
                              buildResultadoBadge(ap['resultado']),
                              Text('Fecha: $fecha'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
