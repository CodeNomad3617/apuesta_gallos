import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pantalla_devolucion_empate.dart';

class PantallaCerrarApuestas extends StatefulWidget {
  const PantallaCerrarApuestas({super.key});

  @override
  State<PantallaCerrarApuestas> createState() => _PantallaCerrarApuestasState();
}

class _PantallaCerrarApuestasState extends State<PantallaCerrarApuestas> {
  Map<int, String?> resultadosSeleccionados = {};
  List<QueryDocumentSnapshot> usuarios = [];
  bool bloqueado = false;

  // Colores para el tema verde esmeralda premium
  final Color primaryEmerald = const Color(0xFF2ECC71);
  final Color darkEmerald = const Color(0xFF27AE60);
  final Color lightEmerald = const Color(0xFFD5F5E3);
  final Color accentEmerald = const Color(0xFF58D68D);
  final Color backgroundGradientStart = const Color(0xFFE8F8F5);
  final Color backgroundGradientEnd = const Color(0xFFD1F2EB);

  Future<void> cargarUsuarios() async {
    setState(() => bloqueado = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
      setState(() {
        usuarios = snapshot.docs;
        bloqueado = false;
      });
    } catch (e) {
      setState(() => bloqueado = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> aplicarResultado(int pelea, String resultadoGlobal) async {
    if (bloqueado) return;
    setState(() => bloqueado = true);

    try {
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
          await FirebaseFirestore.instance.collection('usuarios').doc(doc.id).update({
            'apuestas': apuestas,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resultado "$resultadoGlobal" aplicado a la pelea $pelea'),
          backgroundColor: darkEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (resultadoGlobal == 'Empate' || resultadoGlobal == 'Rojo' || resultadoGlobal == 'Verde') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: PantallaDevolucionEmpate(
                pelea: pelea,
                tipo: resultadoGlobal == 'Empate' ? 'Empate' : 'Ganador',
                colorGanador: resultadoGlobal != 'Empate' ? resultadoGlobal : null,
              ),
            ),
          ),
        );
      }

      await cargarUsuarios();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar resultado: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() => bloqueado = false);
    }
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
            'usuarioId': doc.id,
          });
        }
      }
    }

    final peleasOrdenadas = apuestasPendientes.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkEmerald,
        title: const Text('Cerrar Apuestas', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5
          )
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: darkEmerald.withOpacity(0.6),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
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
        child: peleasOrdenadas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: darkEmerald.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay apuestas pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        color: darkEmerald.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: peleasOrdenadas.length,
                itemBuilder: (_, index) {
                  final pelea = peleasOrdenadas[index];
                  final lista = apuestasPendientes[pelea]!;

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.white,
                    shadowColor: darkEmerald.withOpacity(0.3),
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
                                  color: lightEmerald,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: darkEmerald, width: 1.5),
                                ),
                                child: Icon(
                                  Icons.sports_mma,
                                  color: darkEmerald,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pelea $pelea',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkEmerald,
                                ),
                              ),
                            ],
                          ),
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
                                border: Border.all(
                                  color: colorApuesta.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: lightEmerald,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: darkEmerald.withOpacity(0.3)),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: darkEmerald,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ap['usuario'],
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ID: ${ap['usuarioId']}',
                                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: colorApuesta.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: colorApuesta),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.circle,
                                            size: 12,
                                            color: colorApuesta,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Color: ${ap['color']}',
                                        style: TextStyle(
                                          color: colorApuesta,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        fecha,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'N° Apuesta: ${ap['numeroApuesta'] ?? '-'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: darkEmerald.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Pelea $pelea',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: darkEmerald,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Pierde si pierde',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              Text(
                                                '\$${ap['montoPerdida']}',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Gana si gana',
                                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              Text(
                                                '\$${ap['montoGanancia']}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: resultadosSeleccionados[pelea],
                            decoration: InputDecoration(
                              labelText: 'Seleccionar resultado',
                              labelStyle: TextStyle(color: darkEmerald),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: darkEmerald),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: darkEmerald, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Rojo',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Ganó Rojo'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Verde',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Ganó Verde'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Empate',
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                              onPressed: !bloqueado && resultadosSeleccionados[pelea] != null
                                  ? () => aplicarResultado(pelea, resultadosSeleccionados[pelea]!)
                                  : null,
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: resultadosSeleccionados[pelea] != null ? Colors.white : Colors.grey.shade400,
                              ),
                              label: Text(
                                'Aplicar Resultado',
                                style: TextStyle(
                                  color: resultadosSeleccionados[pelea] != null ? Colors.white : Colors.grey.shade400,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: resultadosSeleccionados[pelea] != null ? darkEmerald : Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: darkEmerald.withOpacity(0.5),
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