import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaEditarApuestas extends StatefulWidget {
  const PantallaEditarApuestas({super.key});

  @override
  State<PantallaEditarApuestas> createState() => _PantallaEditarApuestasState();
}

class _PantallaEditarApuestasState extends State<PantallaEditarApuestas> {
  final TextEditingController _idController = TextEditingController();
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

  Future<void> eliminarApuesta(int index) async {
    if (usuarioId == null || usuarioData == null) return;

    final apuestas = List<Map<String, dynamic>>.from(usuarioData!['apuestas'] ?? []);
    final apuestaEliminada = apuestas.removeAt(index);

    double saldoActual = (usuarioData!['saldoActual'] ?? 0).toDouble();
    double monto = (apuestaEliminada['monto'] ?? 0).toDouble();
    String resultado = apuestaEliminada['resultado'];

    if (resultado == "Ganó") saldoActual -= monto;
    else if (resultado == "Perdió") saldoActual += monto;

    await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId!).update({
      'apuestas': apuestas,
      'saldoActual': saldoActual,
    });

    setState(() {
      usuarioData!['apuestas'] = apuestas;
      usuarioData!['saldoActual'] = saldoActual;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apuesta eliminada y saldo actualizado.')));
  }

  void editarApuesta(int index) {
    final apuesta = Map<String, dynamic>.from(usuarioData!['apuestas'][index]);
    final montoController = TextEditingController(text: apuesta['monto'].toString());
    final colorController = TextEditingController(text: apuesta['color']);
    String resultadoActual = apuesta['resultado'];
    String? resultadoSeleccionado = resultadoActual;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Apuesta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoController,
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            DropdownButtonFormField<String>(
              value: resultadoSeleccionado,
              items: const [
                DropdownMenuItem(value: 'Ganó', child: Text('Ganó')),
                DropdownMenuItem(value: 'Perdió', child: Text('Perdió')),
                DropdownMenuItem(value: 'Empate', child: Text('Empate')),
              ],
              onChanged: (value) => resultadoSeleccionado = value,
              decoration: const InputDecoration(labelText: 'Resultado'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final nuevoMonto = double.tryParse(montoController.text.trim()) ?? apuesta['monto'];
              final nuevoColor = colorController.text.trim();
              final nuevoResultado = resultadoSeleccionado ?? apuesta['resultado'];

              double saldo = (usuarioData!['saldoActual'] ?? 0).toDouble();
              double montoAnterior = apuesta['monto'];
              String resultadoAnterior = apuesta['resultado'];

              if (resultadoAnterior == 'Ganó') saldo -= montoAnterior;
              else if (resultadoAnterior == 'Perdió') saldo += montoAnterior;

              if (nuevoResultado == 'Ganó') saldo += nuevoMonto;
              else if (nuevoResultado == 'Perdió') saldo -= nuevoMonto;

              apuesta['monto'] = nuevoMonto;
              apuesta['color'] = nuevoColor;
              apuesta['resultado'] = nuevoResultado;

              usuarioData!['apuestas'][index] = apuesta;
              usuarioData!['saldoActual'] = saldo;

              await FirebaseFirestore.instance.collection('usuarios').doc(usuarioId!).update({
                'apuestas': usuarioData!['apuestas'],
                'saldoActual': saldo,
              });

              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apuesta actualizada correctamente.')));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final redAccent = Colors.redAccent.shade700;
    final apuestas = List<Map<String, dynamic>>.from(usuarioData?['apuestas'] ?? []);
    final saldoActual = usuarioData?['saldoActual'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar / Eliminar Apuestas'),
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
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'ID del usuario',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text('Buscar usuario', style: TextStyle(color: Colors.white)),
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
              const SizedBox(height: 16),
              if (usuarioData != null) ...[
                Text('Saldo actual: \$${saldoActual.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Apuestas registradas:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: apuestas.length,
                    itemBuilder: (_, index) {
                      final ap = apuestas[index];
                      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']));
                      final numeroApuesta = ap['numeroApuesta'] ?? index + 1;
                      final resultado = ap['resultado'];

                      final resultadoIcon = resultado == 'Ganó'
                          ? Icons.check_circle
                          : resultado == 'Perdió'
                              ? Icons.cancel
                              : resultado == 'Empate'
                                  ? Icons.horizontal_rule
                                  : Icons.hourglass_empty;

                      final resultadoColor = resultado == 'Ganó'
                          ? Colors.green
                          : resultado == 'Perdió'
                              ? Colors.red
                              : resultado == 'Empate'
                                  ? Colors.orange
                                  : Colors.grey;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.gavel, color: Colors.deepPurple),
                          title: Text('Pelea torneo: ${ap['pelea']} | Apuesta #$numeroApuesta'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  buildColorCircle(ap['color']),
                                  Text('Color elegido: ${ap['color']}'),
                                ],
                              ),
                              Text('Monto: \$${ap['monto']}'),
                              Row(
                                children: [
                                  Icon(resultadoIcon, color: resultadoColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Resultado: ${resultado ?? "Pendiente"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: resultadoColor,
                                    ),
                                  ),
                                ],
                              ),
                              Text('Fecha: $fecha'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editarApuesta(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => eliminarApuesta(index),
                              ),
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
