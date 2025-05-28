import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistroApuesta extends StatefulWidget {
  const PantallaRegistroApuesta({super.key});

  @override
  State<PantallaRegistroApuesta> createState() => _PantallaRegistroApuestaState();
}

class _PantallaRegistroApuestaState extends State<PantallaRegistroApuesta> {
  final _peleaController = TextEditingController();
  final _montoPerdidaController = TextEditingController();
  final _montoGananciaController = TextEditingController();

  String? _usuarioSeleccionadoId;
  String? _colorSeleccionado;
  bool guardando = false;

  double? saldoActualVisible;
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

  void registrarApuesta() async {
    final id = _usuarioSeleccionadoId;
    final pelea = int.tryParse(_peleaController.text.trim());
    final color = _colorSeleccionado;

    final montoPerdida = double.tryParse(_montoPerdidaController.text.trim());
    final montoGanancia = double.tryParse(_montoGananciaController.text.trim());

    if (id == null || pelea == null || color == null || montoPerdida == null || montoGanancia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Llena todos los campos correctamente.')),
      );
      return;
    }

    setState(() => guardando = true);

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(id);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El usuario con ID "$id" no existe.')),
      );
      return;
    }

    final data = docSnap.data()!;
    final apuestas = List<Map<String, dynamic>>.from(data['apuestas'] ?? []);
    final numeroApuesta = apuestas.length + 1;
    final saldoActual = (data['saldoActual'] ?? 0).toDouble();

    if (montoPerdida > saldoActual) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El monto excede el saldo actual de \$${saldoActual.toStringAsFixed(2)}')),
      );
      return;
    }

    final nuevoSaldo = saldoActual - montoPerdida;

    final nuevaApuesta = {
      'pelea': pelea,
      'numeroApuesta': numeroApuesta,
      'color': color,
      'montoPerdida': montoPerdida,
      'montoGanancia': montoGanancia,
      'resultado': null,
      'fecha': DateTime.now().toIso8601String(),
    };

    await docRef.update({
      'apuestas': FieldValue.arrayUnion([nuevaApuesta]),
      'saldoActual': nuevoSaldo,
    });

    setState(() {
      guardando = false;
      _peleaController.clear();
      _montoPerdidaController.clear();
      _montoGananciaController.clear();
      _colorSeleccionado = null;
      _usuarioSeleccionadoId = null;
      saldoActualVisible = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Apuesta registrada con éxito!')),
    );
  }

  void recargarSaldo() async {
    if (_usuarioSeleccionadoId == null) return;

    double? cantidad = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        double? monto;
        return AlertDialog(
          title: const Text('Recargar saldo'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto a recargar'),
            onChanged: (value) {
              monto = double.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(monto);
              },
              child: const Text('Recargar'),
            ),
          ],
        );
      },
    );

    if (cantidad == null || cantidad <= 0) return;

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(_usuarioSeleccionadoId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) return;

    final data = docSnap.data()!;
    final saldoActual = (data['saldoActual'] ?? 0).toDouble();

    final nuevoSaldo = saldoActual + cantidad;

    await docRef.update({
      'saldoActual': nuevoSaldo,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saldo recargado con éxito. Nuevo saldo: \$${nuevoSaldo.toStringAsFixed(2)}')),
    );

    setState(() {
      saldoActualVisible = nuevoSaldo;
    });
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
        title: const Text('Registrar Apuesta'),
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
                    Icon(Icons.edit_note, size: 30, color: redAccent),
                    const SizedBox(width: 8),
                    const Text('Datos de la Apuesta',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _usuarioSeleccionadoId,
                  decoration: InputDecoration(
                    labelText: 'Selecciona un apostador',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: usuarios
                      .map((usuario) => DropdownMenuItem<String>(
                            value: usuario['id'],
                            child: Text(usuario['nombre']),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    setState(() => _usuarioSeleccionadoId = val);
                    if (val != null) {
                      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(val).get();
                      if (doc.exists) {
                        final data = doc.data();
                        setState(() {
                          saldoActualVisible = (data?['saldoActual'] ?? 0).toDouble();
                        });
                      }
                    }
                  },
                ),
                if (saldoActualVisible != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      'Saldo actual: \$${saldoActualVisible!.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                buildInput(label: 'Número de pelea (torneo)', controller: _peleaController, type: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _colorSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Color elegido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Rojo',
                      child: Row(children: [Icon(Icons.circle, color: Colors.red, size: 16), SizedBox(width: 8), Text('Rojo')]),
                    ),
                    DropdownMenuItem(
                      value: 'Verde',
                      child: Row(children: [Icon(Icons.circle, color: Colors.green, size: 16), SizedBox(width: 8), Text('Verde')]),
                    ),
                  ],
                  onChanged: (val) => setState(() => _colorSeleccionado = val),
                ),
                const SizedBox(height: 16),
                buildInput(label: 'PIERDE:', controller: _montoPerdidaController, type: TextInputType.number),
                buildInput(label: 'GANA:', controller: _montoGananciaController, type: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: guardando || saldoActualVisible == 0
                        ? null // Deshabilitar el botón si el saldo es 0
                        : registrarApuesta,
                    icon: guardando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      guardando ? 'Guardando...' : 'Registrar Apuesta',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
