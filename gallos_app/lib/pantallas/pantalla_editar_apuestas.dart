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

  // Colores para el tema azul profesional premium
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color accentBlue = const Color(0xFF448AFF);
  final Color backgroundGradientStart = const Color(0xFFE3F2FD);
  final Color backgroundGradientEnd = const Color(0xFFBBDEFB);

  void buscarUsuario() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(id).get();
      Navigator.pop(context); // Cerrar indicador de carga

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario "$id" no encontrado.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: primaryBlue,
          )
        );
        return;
      }

      setState(() {
        usuarioId = id;
        usuarioData = doc.data();
      });
    } catch (e) {
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar usuario: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> eliminarApuesta(int index) async {
    if (usuarioId == null || usuarioData == null) return;

    // Mostrar diálogo de confirmación
    bool confirmado = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta apuesta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
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

      Navigator.pop(context); // Cerrar indicador de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apuesta eliminada y saldo actualizado.'),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar apuesta: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  void editarApuesta(int index) {
    final apuesta = Map<String, dynamic>.from(usuarioData!['apuestas'][index]);
    final montoController = TextEditingController(text: apuesta['monto'].toString());
    final colorController = TextEditingController(text: apuesta['color']);
    String resultadoActual = apuesta['resultado'];
    String? resultadoSeleccionado = resultadoActual;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Editar Apuesta', 
              style: TextStyle(
                color: darkBlue,
                fontWeight: FontWeight.bold
              )
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixIcon: Icon(Icons.attach_money, color: primaryBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: darkBlue),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: colorController.text.toLowerCase(),
                    items: ['rojo', 'verde', 'gris'].map((color) {
                      return DropdownMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            buildColorCircle(color),
                            const SizedBox(width: 8),
                            Text(color[0].toUpperCase() + color.substring(1),
                              style: TextStyle(color: darkBlue)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        colorController.text = value;
                        setState(() {});
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: resultadoSeleccionado,
                    items: ['Ganó', 'Perdió', 'Empate'].map((resultado) {
                      IconData icon;
                      Color color;
                      switch (resultado) {
                        case 'Ganó':
                          icon = Icons.check_circle;
                          color = Colors.green;
                          break;
                        case 'Perdió':
                          icon = Icons.cancel;
                          color = Colors.red;
                          break;
                        case 'Empate':
                          icon = Icons.horizontal_rule;
                          color = Colors.orange;
                          break;
                        default:
                          icon = Icons.hourglass_empty;
                          color = Colors.grey;
                      }
                      return DropdownMenuItem(
                        value: resultado,
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 8),
                            Text(resultado, style: TextStyle(color: darkBlue)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => resultadoSeleccionado = value),
                    decoration: InputDecoration(
                      labelText: 'Resultado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                    ),
                    dropdownColor: Colors.white,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final nuevoMonto = double.tryParse(montoController.text.trim()) ?? apuesta['monto'];
                  final nuevoColor = colorController.text.trim();
                  final nuevoResultado = resultadoSeleccionado ?? apuesta['resultado'];

                  if (nuevoMonto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El monto debe ser mayor a cero')),
                    );
                    return;
                  }

                  // Mostrar indicador de carga
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
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

                    Navigator.pop(context); // Cerrar indicador de carga
                    Navigator.pop(context); // Cerrar diálogo de edición
                    
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apuesta actualizada correctamente.'),
                        backgroundColor: Colors.green,
                      )
                    );
                  } catch (e) {
                    Navigator.pop(context); // Cerrar indicador de carga
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      )
                    );
                  }
                },
                child: const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final apuestas = List<Map<String, dynamic>>.from(usuarioData?['apuestas'] ?? []);
    final saldoActual = usuarioData?['saldoActual'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar / Eliminar Apuestas', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: darkBlue,
        elevation: 10,
        shadowColor: darkBlue.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 6,
                shadowColor: primaryBlue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: 'ID del usuario',
                          labelStyle: TextStyle(color: primaryBlue),
                          prefixIcon: Icon(Icons.person, color: primaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryBlue, width: 2),
                          ),
                        ),
                        style: TextStyle(color: darkBlue),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text('Buscar usuario', style: TextStyle(color: Colors.white)),
                          onPressed: buscarUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                            shadowColor: primaryBlue.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (usuarioData != null) ...[
                Card(
                  elevation: 4,
                  shadowColor: primaryBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Saldo actual: \$${saldoActual?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'Apuestas registradas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${apuestas.length}',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shadowColor: primaryBlue.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryBlue.withOpacity(0.3)),
                            ),
                            child: Icon(
                              Icons.sports_mma,
                              color: primaryBlue,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            'Pelea: ${ap['pelea']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Apuesta #$numeroApuesta',
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${ap['monto']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: darkBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  buildColorCircle(ap['color']),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Color: ${ap['color']}',
                                    style: TextStyle(color: darkBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
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
                              const SizedBox(height: 4),
                              Text(
                                fecha,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primaryBlue.withOpacity(0.3)),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () => editarApuesta(index),
                              ),
                              const SizedBox(width: 4),
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
                                onPressed: () => eliminarApuesta(index),
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
                          color: primaryBlue.withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ingresa un ID de usuario para buscar apuestas',
                          style: TextStyle(
                            fontSize: 18,
                            color: primaryBlue.withOpacity(0.7),
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
}