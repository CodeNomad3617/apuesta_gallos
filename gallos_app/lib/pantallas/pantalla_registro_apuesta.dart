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

  // Colores premium
  final Color rojoPremium = Color(0xFFC62828); // Rojo oscuro premium
  final Color rojoClaro = Color(0xFFEF9A9A); // Rojo claro para fondos
  final Color doradoPremium = Color(0xFFFFD700); // Dorado para acentos
  final Color grisOscuro = Color(0xFF424242); // Gris oscuro para texto

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
        SnackBar(
          content: Text('Llena todos los campos correctamente.'),
          backgroundColor: rojoPremium,
        ),
      );
      return;
    }

    setState(() => guardando = true);

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(id);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El usuario con ID "$id" no existe.'),
          backgroundColor: rojoPremium,
        ),
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
        SnackBar(
          content: Text('El monto excede el saldo actual de \$${saldoActual.toStringAsFixed(2)}'),
          backgroundColor: rojoPremium,
        ),
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
      'monto': montoPerdida,
      'resultado': null,
      'montoDevuelto': 0,
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
      SnackBar(
        content: Text('¡Apuesta registrada con éxito!'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void recargarSaldo() async {
    if (_usuarioSeleccionadoId == null) return;

    double? cantidad = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        double? monto;
        return AlertDialog(
          title: Text('Recargar saldo', style: TextStyle(color: rojoPremium)),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto a recargar',
              labelStyle: TextStyle(color: grisOscuro),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: rojoPremium),
              ),
            ),
            onChanged: (value) {
              monto = double.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancelar', style: TextStyle(color: rojoPremium)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(monto);
              },
              child: Text('Recargar', style: TextStyle(color: rojoPremium)),
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
      SnackBar(
        content: Text('Saldo recargado con éxito. Nuevo saldo: \$${nuevoSaldo.toStringAsFixed(2)}'),
        backgroundColor: Colors.green.shade700,
      ),
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
          labelStyle: TextStyle(color: grisOscuro),
          prefixIcon: Icon(Icons.input, color: rojoPremium),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: rojoPremium, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('REGISTRO DE APUESTAS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            )),
        centerTitle: true,
        backgroundColor: rojoPremium,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
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
              Colors.grey[50]!,
              rojoClaro.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
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
                            Icon(Icons.casino, size: 32, color: rojoPremium),
                            SizedBox(width: 12),
                            Text('DATOS DE LA APUESTA',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: grisOscuro,
                                )),
                          ],
                        ),
                        SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _usuarioSeleccionadoId,
                          decoration: InputDecoration(
                            labelText: 'Selecciona un apostador',
                            labelStyle: TextStyle(color: grisOscuro),
                            prefixIcon: Icon(Icons.person, color: rojoPremium),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: rojoPremium, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
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
                              final doc = await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(val)
                                  .get();
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
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saldo actual: \$${saldoActualVisible!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: saldoActualVisible == 0 ? recargarSaldo : null, // Deshabilitado si saldo > 0
                                  icon: Icon(
                                    Icons.add_circle, 
                                    color: saldoActualVisible == 0 ? rojoPremium : Colors.grey, // Gris cuando está deshabilitado
                                  ),
                                  label: Text(
                                    'Recargar',
                                    style: TextStyle(
                                      color: saldoActualVisible == 0 ? rojoPremium : Colors.grey, // Gris cuando está deshabilitado
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        buildInput(
                            label: 'Número de pelea (torneo)',
                            controller: _peleaController,
                            type: TextInputType.number),
                        DropdownButtonFormField<String>(
                          value: _colorSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Color elegido',
                            labelStyle: TextStyle(color: grisOscuro),
                            prefixIcon: Icon(Icons.color_lens, color: rojoPremium),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: rojoPremium, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Rojo',
                              child: Row(children: [
                                Icon(Icons.circle, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Rojo')
                              ])),
                            DropdownMenuItem(
                                value: 'Verde',
                                child: Row(children: [
                                  Icon(Icons.circle, color: Colors.green, size: 16),
                                  SizedBox(width: 8),
                                  Text('Verde')
                                ])),
                          ],
                          onChanged: (val) => setState(() => _colorSeleccionado = val),
                        ),
                        SizedBox(height: 16),
                        buildInput(
                            label: 'PIERDE:',
                            controller: _montoPerdidaController,
                            type: TextInputType.number),
                        buildInput(
                            label: 'GANA:',
                            controller: _montoGananciaController,
                            type: TextInputType.number),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: guardando || saldoActualVisible == 0
                        ? null
                        : registrarApuesta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rojoPremium,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: rojoPremium.withOpacity(0.4),
                    ),
                    child: guardando
                        ? SizedBox(
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
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'REGISTRAR APUESTA',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}