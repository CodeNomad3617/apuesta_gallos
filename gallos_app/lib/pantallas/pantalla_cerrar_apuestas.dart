import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaCerrarApuestas extends StatefulWidget {
  const PantallaCerrarApuestas({super.key});

  @override
  State<PantallaCerrarApuestas> createState() => _PantallaCerrarApuestasState();
}

class _PantallaCerrarApuestasState extends State<PantallaCerrarApuestas> {
  Map<int, String?> resultadosSeleccionados = {};
  List<QueryDocumentSnapshot> usuarios = [];

  Future<void> cargarUsuarios() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    setState(() => usuarios = snapshot.docs);
  }

  Future<void> aplicarResultado(int pelea, String resultadoGlobal) async {
    for (var doc in usuarios) {
      final data = doc.data() as Map<String, dynamic>;
      final apuestas = List<Map<String, dynamic>>.from(data['apuestas'] ?? []);
      bool modificado = false;

      for (var ap in apuestas) {
        if (ap['pelea'] == pelea && ap['resultado'] == null) {
          ap['resultado'] = (resultadoGlobal == 'Empate')
              ? 'Empate'
              : (ap['color'] == resultadoGlobal ? 'Ganó' : 'Perdió');
          modificado = true;
        }
      }

      if (modificado) {
        double saldo = (data['saldoInicial'] ?? 0).toDouble();
        for (var ap in apuestas) {
          if (ap['resultado'] == 'Ganó') saldo += (ap['monto'] ?? 0).toDouble();
          if (ap['resultado'] == 'Perdió') saldo -= (ap['monto'] ?? 0).toDouble();
        }

        await FirebaseFirestore.instance.collection('usuarios').doc(doc.id).update({
          'apuestas': apuestas,
          'saldoActual': saldo,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resultado "$resultadoGlobal" aplicado a la pelea $pelea'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    cargarUsuarios();
  }

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, List<Map<String, dynamic>>> apuestasPendientes = {};
    for (var doc in usuarios) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = data['nombre'] ?? doc.id;
      final apuestas = List<Map<String, dynamic>>.from(data['apuestas'] ?? []);
      for (var ap in apuestas) {
        if (ap['resultado'] == null) {
          final pelea = ap['pelea'] ?? 0;
          apuestasPendientes.putIfAbsent(pelea, () => []).add({
            ...ap,
            'usuario': nombre,
          });
        }
      }
    }

    final peleasOrdenadas = apuestasPendientes.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent.shade700,
        title: const Text('Cerrar Apuestas / Resultados', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDEDEC), Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: peleasOrdenadas.isEmpty
            ? const Center(child: Text('No hay apuestas pendientes.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: peleasOrdenadas.length,
                itemBuilder: (_, index) {
                  final pelea = peleasOrdenadas[index];
                  final lista = apuestasPendientes[pelea]!;

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🐓 Pelea $pelea',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...lista.map((ap) {
                            final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ap['fecha']));
                            final colorApuesta = ap['color'] == 'Rojo'
                                ? Colors.redAccent
                                : ap['color'] == 'Verde'
                                    ? Colors.green
                                    : Colors.grey;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: colorApuesta.withOpacity(0.05),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(ap['usuario'],
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ),
                                      const Icon(Icons.attach_money, size: 18, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text('\$${ap['monto']}', style: const TextStyle(color: Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.color_lens, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Color: ${ap['color']}',
                                          style: TextStyle(color: colorApuesta, fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(fecha, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: resultadosSeleccionados[pelea],
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar resultado',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xFFFFF8F4),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Rojo',
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('Ganó Rojo'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Verde',
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('Ganó Verde'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Empate',
                                child: Row(
                                  children: [
                                    const Icon(Icons.remove, color: Colors.grey, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('Empate'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) => setState(() => resultadosSeleccionados[pelea] = val),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: resultadosSeleccionados[pelea] != null
                                  ? () => aplicarResultado(pelea, resultadosSeleccionados[pelea]!)
                                  : null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Aplicar Resultado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: resultadosSeleccionados[pelea] != null
                                    ? Colors.redAccent.shade700
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          )
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
