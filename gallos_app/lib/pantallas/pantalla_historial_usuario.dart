import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class PantallaHistorialUsuario extends StatefulWidget {
  const PantallaHistorialUsuario({super.key});

  @override
  State<PantallaHistorialUsuario> createState() => _PantallaHistorialUsuarioState();
}

class _PantallaHistorialUsuarioState extends State<PantallaHistorialUsuario> {
  Map<String, dynamic>? usuarioData;
  String? usuarioId;
  List<Map<String, dynamic>> usuarios = [];

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    setState(() {
      usuarios = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nombre': data['nombre']?.toString() ?? doc.id,
        };
      }).toList();
    });
  }

  void buscarUsuarioDesdeDropdown(String id) async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario "$id" no encontrado.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.deepPurple,
        )
      );
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

    int totalApuestas = apuestas.length;
    int ganadas = apuestas.where((ap) => ap['resultado'] == 'Ganó').length;
    int perdidas = apuestas.where((ap) => ap['resultado'] == 'Perdió').length;
    int empatadas = apuestas.where((ap) => ap['resultado'] == 'Empate').length;

    // Cargar fuentes de Google Fonts
    final robotoRegular = await GoogleFonts.getFont('Roboto');
    final robotoBold = await GoogleFonts.getFont('Roboto', fontWeight: FontWeight.bold);

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: pw.Font.ttf(robotoRegular as ByteData),
          bold: pw.Font.ttf(robotoBold as ByteData),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'Resumen de apuestas - ${usuarioData!['nombre']}', 
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('ID: $usuarioId', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Saldo inicial: \$${usuarioData!['saldoInicial']}'),
              pw.Text('Saldo actual: \$${usuarioData!['saldoActual']}'),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.purple300),
              pw.Text('Estadísticas de apuestas:', 
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.purple800,
                  fontWeight: pw.FontWeight.bold
                )
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total de Apuestas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('$totalApuestas', style: pw.TextStyle(fontSize: 18)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ganadas:', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                      pw.Text('$ganadas', style: pw.TextStyle(color: PdfColors.green, fontSize: 18)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Perdidas:', style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                      pw.Text('$perdidas', style: pw.TextStyle(color: PdfColors.red, fontSize: 18)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Empatadas:', style: pw.TextStyle(color: PdfColors.orange, fontWeight: pw.FontWeight.bold)),
                      pw.Text('$empatadas', style: pw.TextStyle(color: PdfColors.orange, fontSize: 18)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.purple300),
              pw.Text('Detalle de apuestas:', 
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.purple800,
                  fontWeight: pw.FontWeight.bold
                )
              ),
              pw.SizedBox(height: 10),
              ...apuestas.map((ap) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Torneo: ${ap['pelea']} | #${ap['numeroApuesta']}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Monto: \$${ap['montoPerdida'] ?? ap['monto'] ?? '?'}'),
                      pw.SizedBox(height: 4),
                      pw.Text('Color: ${ap['color']}'),
                      pw.SizedBox(height: 4),
                      pw.Text('Resultado: ${ap['resultado']}', 
                        style: pw.TextStyle(
                          color: ap['resultado'] == 'Ganó' ? PdfColors.green : 
                                ap['resultado'] == 'Perdió' ? PdfColors.red : 
                                PdfColors.orange,
                          fontWeight: pw.FontWeight.bold
                        )
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']))}'),
                    ],
                  ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF generado exitosamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.deepPurple,
        action: SnackBarAction(
          label: 'Abrir',
          textColor: Colors.white,
          onPressed: () => OpenFile.open(file.path),
        ),
      )
    );
  }

  Widget buildColorCircle(String color) {
    final colorCode = color.toLowerCase() == 'rojo'
        ? Colors.redAccent
        : color.toLowerCase() == 'verde'
            ? Colors.greenAccent
            : Colors.grey;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: colorCode,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: Offset(1, 1),
          )
        ]
      ),
      margin: const EdgeInsets.only(right: 8),
    );
  }

  Widget buildResultadoBadge(String? resultado) {
    Color badgeColor;
    Color textColor;
    IconData icon;

    switch (resultado) {
      case 'Ganó':
        badgeColor = Colors.greenAccent.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        break;
      case 'Perdió':
        badgeColor = Colors.redAccent.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
        break;
      case 'Empate':
        badgeColor = Colors.orangeAccent.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.remove_circle;
        break;
      default:
        badgeColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(1, 1),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 6),
          Text(resultado ?? 'Pendiente', 
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor
            )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purpleTheme = Colors.deepPurple;
    final apuestas = (usuarioData?['apuestas'] ?? []) as List<dynamic>;
    final saldoActual = usuarioData?['saldoActual'];
    final saldoInicial = usuarioData?['saldoInicial'];

    int totalApuestas = apuestas.length;
    int ganadas = apuestas.where((ap) => ap['resultado'] == 'Ganó').length;
    int perdidas = apuestas.where((ap) => ap['resultado'] == 'Perdió').length;
    int empatadas = apuestas.where((ap) => ap['resultado'] == 'Empate').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Apuestas', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: purpleTheme,
        elevation: 10,
        shadowColor: purpleTheme.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        actions: [
          if (usuarioData != null)
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: generarPDF,
              tooltip: 'Generar PDF',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade50,
              Colors.deepPurple.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shadowColor: purpleTheme.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: usuarioId,
                    decoration: InputDecoration(
                      labelText: 'Selecciona un apostador',
                      labelStyle: TextStyle(color: purpleTheme),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_search, color: purpleTheme),
                    ),
                    dropdownColor: Colors.white,
                    style: TextStyle(color: Colors.deepPurple.shade900, fontWeight: FontWeight.w500),
                    items: usuarios
                        .map((usuario) => DropdownMenuItem<String>(
                              value: usuario['id'],
                              child: Text(
                                usuario['nombre'],
                                style: TextStyle(color: Colors.deepPurple.shade800),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        buscarUsuarioDesdeDropdown(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (usuarioData != null) ...[
                Card(
                  elevation: 6,
                  shadowColor: purpleTheme.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Resumen Estadístico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: purpleTheme,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'Total',
                              '$totalApuestas',
                              Colors.deepPurple.shade200,
                              Icons.format_list_numbered,
                            ),
                            _buildStatCard(
                              'Ganadas',
                              '$ganadas',
                              Colors.greenAccent.shade200,
                              Icons.trending_up,
                            ),
                            _buildStatCard(
                              'Perdidas',
                              '$perdidas',
                              Colors.redAccent.shade200,
                              Icons.trending_down,
                            ),
                            _buildStatCard(
                              'Empatadas',
                              '$empatadas',
                              Colors.orangeAccent.shade200,
                              Icons.trending_flat,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 6,
                  shadowColor: purpleTheme.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: purpleTheme.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: purpleTheme, width: 2),
                      ),
                      child: Icon(Icons.person, color: purpleTheme, size: 30),
                    ),
                    title: Text(
                      usuarioData!['nombre'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Saldo inicial: \$${saldoInicial?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(color: Colors.deepPurple.shade700),
                        ),
                        Text(
                          'Saldo actual: \$${saldoActual?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: (saldoActual ?? 0) >= (saldoInicial ?? 0) 
                                ? Colors.green.shade800 
                                : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: purpleTheme,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: purpleTheme.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(2, 2),
                            )
                          ]
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      ),
                      onPressed: generarPDF,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Historial de Apuestas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: purpleTheme,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: $totalApuestas',
                        style: TextStyle(
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: apuestas.length,
                    itemBuilder: (_, index) {
                      final ap = apuestas[index];
                      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shadowColor: purpleTheme.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: purpleTheme.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: purpleTheme.withOpacity(0.3)),
                            ),
                            child: Icon(
                              Icons.attach_money,
                              color: purpleTheme,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            'Pelea: ${ap['pelea']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade900,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  buildColorCircle(ap['color']),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Color: ${ap['color']}',
                                    style: TextStyle(color: Colors.deepPurple.shade700),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${ap['montoPerdida'] ?? ap['monto'] ?? '?'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '#${ap['numeroApuesta']}',
                                    style: TextStyle(
                                      color: Colors.deepPurple.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  buildResultadoBadge(ap['resultado']),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fecha,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 60,
                          color: purpleTheme.withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Selecciona un usuario para ver su historial',
                          style: TextStyle(
                            fontSize: 18,
                            color: purpleTheme.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple.shade700),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade900,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }
}