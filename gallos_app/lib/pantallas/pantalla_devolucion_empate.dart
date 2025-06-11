import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PantallaDevolucionEmpate extends StatefulWidget {
  final int pelea;
  final String tipo; // 'Empate' o 'Ganador'
  final String? colorGanador; // Requerido si tipo == 'Ganador'

  const PantallaDevolucionEmpate({
    Key? key,
    required this.pelea,
    required this.tipo,
    this.colorGanador,
  }) : super(key: key);

  @override
  State<PantallaDevolucionEmpate> createState() => _PantallaDevolucionEmpateState();
}

class _PantallaDevolucionEmpateState extends State<PantallaDevolucionEmpate> {
  final Map<String, TextEditingController> _controladores = {};
  List<Map<String, dynamic>> _usuariosConApuestas = [];

  @override
  void initState() {
    super.initState();
    _cargarApostadores();
  }

  Future<void> _cargarApostadores() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
    List<Map<String, dynamic>> temp = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final apuestas = List<Map<String, dynamic>>.from(data['apuestas'] ?? []);

      for (var ap in apuestas) {
        final peleaMatch = ap['pelea'] == widget.pelea;
        final fecha = ap['fecha'];
        final nombre = data['nombre'] ?? 'Sin nombre';
        final id = doc.id;
        final color = ap['color'] ?? '-';

        if (widget.tipo == 'Empate' &&
            peleaMatch &&
            ap['resultado'] == 'Empate' &&
            (ap['montoDevuelto'] ?? 0) == 0) {
          final monto = ap['montoPerdida'] ?? 0;

          temp.add({
            'id': id,
            'nombre': nombre,
            'monto': monto,
            'color': color,
            'fecha': fecha,
            'apuesta': ap,
          });
          _controladores[id] = TextEditingController(text: monto.toString());
        }

        if (widget.tipo == 'Ganador' &&
            peleaMatch &&
            ap['resultado'] == 'Ganó' &&
            ap['color'] == widget.colorGanador &&
            (ap['montoPagado'] ?? 0) == 0) {
          final monto = ap['montoGanancia'] ?? 0;

          temp.add({
            'id': id,
            'nombre': nombre,
            'monto': monto,
            'color': color,
            'fecha': fecha,
            'apuesta': ap,
          });
          _controladores[id] = TextEditingController(text: monto.toString());
        }
      }
    }

    setState(() => _usuariosConApuestas = temp);
  }

  Future<void> _guardarCambios() async {
    for (var usuario in _usuariosConApuestas) {
      final docId = usuario['id'];
      final nuevaCantidad = double.tryParse(_controladores[docId]?.text ?? '') ?? 0;

      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(docId);
      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (data == null) continue;

      List<Map<String, dynamic>> apuestas = List<Map<String, dynamic>>.from(data['apuestas'] ?? []);
      double saldoActual = (data['saldoActual'] ?? 0).toDouble();

      for (var ap in apuestas) {
        if (ap['pelea'] == widget.pelea) {
          if (widget.tipo == 'Empate' &&
              ap['resultado'] == 'Empate' &&
              (ap['montoDevuelto'] ?? 0) == 0) {
            ap['montoDevuelto'] = nuevaCantidad;
            saldoActual += nuevaCantidad;
          }

          if (widget.tipo == 'Ganador' &&
              ap['resultado'] == 'Ganó' &&
              ap['color'] == widget.colorGanador &&
              (ap['montoPagado'] ?? 0) == 0) {
            ap['montoPagado'] = nuevaCantidad;
            saldoActual += nuevaCantidad;
          }
        }
      }

      await docRef.update({
        'apuestas': apuestas,
        'saldoActual': saldoActual,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.tipo == 'Empate'
            ? '✅ Devoluciones guardadas correctamente'
            : '✅ Pagos guardados correctamente'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final estiloTitulo = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.grey[800],
    );
    final estiloValor = TextStyle(
      fontSize: 16,
      color: Colors.grey[700],
    );

    // Colores premium
    final primaryColor = widget.tipo == 'Empate' 
        ? Color(0xFF6A1B9A) // Púrpura oscuro para empates
        : Color(0xFF0D47A1); // Azul oscuro para ganadores
    final secondaryColor = widget.tipo == 'Empate'
        ? Color(0xFF9C27B0) // Púrpura claro
        : Color(0xFF1976D2); // Azul claro
    final backgroundColor = Color(0xFFFAFAFA);
    final cardColor = Colors.white;
    final textFieldColor = Color(0xFFF5F5F5);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.tipo == 'Empate'
            ? 'Empate - Pelea ${widget.pelea}'
            : 'Pago a Ganadores - Pelea ${widget.pelea} (${widget.colorGanador})'),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        color: backgroundColor,
        child: _usuariosConApuestas.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 50, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No hay devoluciones/pagos pendientes',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _usuariosConApuestas.length,
                itemBuilder: (context, index) {
                  final usuario = _usuariosConApuestas[index];
                  final fechaFormat = usuario['fecha'] != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(usuario['fecha']))
                      : 'Sin fecha';
                  final color = usuario['color'] == 'Rojo'
                      ? Colors.redAccent
                      : usuario['color'] == 'Verde'
                          ? Colors.green
                          : Colors.grey;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.person, color: secondaryColor),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    usuario['nombre'],
                                    style: estiloTitulo.copyWith(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.color_lens, size: 18, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text('Color: ', style: estiloValor),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    usuario['color'],
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text('Fecha: ', style: estiloValor),
                                Text(
                                  fechaFormat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Text(
                                  widget.tipo == 'Empate' ? 'Apostó: ' : 'Ganancia: ',
                                  style: estiloValor,
                                ),
                                Text(
                                  '\$${usuario['monto']}',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _controladores[usuario['id']],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: widget.tipo == 'Empate'
                                    ? 'Monto a devolver'
                                    : 'Monto a pagar',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: secondaryColor, width: 2),
                                ),
                                fillColor: textFieldColor,
                                filled: true,
                                prefixIcon: Icon(Icons.money, color: secondaryColor),
                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardarCambios,
        label: Text(
          widget.tipo == 'Empate' ? 'Devolver' : 'Pagar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: Icon(Icons.save),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}