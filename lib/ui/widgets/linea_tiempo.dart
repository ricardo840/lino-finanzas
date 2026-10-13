import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/fechas.dart';
import '../../core/formato.dart';
import '../tema/contexto.dart';

/// Línea de tiempo de una compra a crédito: el día de la compra, el corte y
/// la fecha límite de pago, con los domingos de sueldo que hay en medio.
class LineaTiempoCompra extends StatelessWidget {
  const LineaTiempoCompra({
    super.key,
    required this.compra,
    required this.corte,
    required this.limite,
  });

  final DateTime compra;
  final DateTime corte;
  final DateTime limite;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final total = math.max(diasEntre(compra, limite), 1);
    double fraccion(DateTime dia) => (diasEntre(compra, dia) / total).clamp(0.0, 1.0);

    final domingos = <double>[
      for (var dia = sumarDias(compra, 1); !dia.isAfter(limite); dia = sumarDias(dia, 1))
        if (dia.weekday == DateTime.sunday) fraccion(dia),
    ];
    final enCorte = fraccion(corte);
    final etiqueta = tema.secundario.copyWith(fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La etiqueta del corte va arriba, en su posición sobre la línea.
        Align(
          alignment: Alignment(enCorte * 2 - 1, 0),
          child: Text('Corte ${fechaCorta(corte)}', style: etiqueta.copyWith(color: tema.advertencia)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 18,
          child: CustomPaint(
            painter: _PintorLinea(
              corte: enCorte,
              domingos: domingos,
              linea: tema.bordeVidrio,
              colorCompra: tema.acento,
              colorCorte: tema.advertencia,
              colorLimite: tema.negativo,
              colorSueldo: tema.positivo,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: Text('Compra ${fechaCorta(compra)}', style: etiqueta)),
            Text('Pago ${fechaCorta(limite)}', style: etiqueta.copyWith(color: tema.negativo)),
          ],
        ),
        if (domingos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tema.positivo),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${plural(domingos.length, 'domingo de sueldo', 'domingos de sueldo')} antes del pago',
                  style: etiqueta,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PintorLinea extends CustomPainter {
  _PintorLinea({
    required this.corte,
    required this.domingos,
    required this.linea,
    required this.colorCompra,
    required this.colorCorte,
    required this.colorLimite,
    required this.colorSueldo,
  });

  /// Posición del corte sobre la línea, de 0 a 1.
  final double corte;
  final List<double> domingos;
  final Color linea;
  final Color colorCompra;
  final Color colorCorte;
  final Color colorLimite;
  final Color colorSueldo;

  static const double _radio = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    const inicio = _radio;
    final fin = size.width - _radio;
    double x(double fraccion) => inicio + (fin - inicio) * fraccion;

    canvas.drawLine(
      Offset(inicio, y),
      Offset(fin, y),
      Paint()
        ..color = linea
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Hasta el corte, lo que se compra entra en este periodo.
    canvas.drawLine(
      Offset(inicio, y),
      Offset(x(corte), y),
      Paint()
        ..color = colorCompra
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final domingo in domingos) {
      canvas.drawCircle(Offset(x(domingo), y), 3, Paint()..color = colorSueldo);
    }
    canvas.drawCircle(Offset(x(0), y), _radio, Paint()..color = colorCompra);
    canvas.drawCircle(Offset(x(corte), y), _radio - 1, Paint()..color = colorCorte);
    canvas.drawCircle(Offset(x(1), y), _radio, Paint()..color = colorLimite);
  }

  @override
  bool shouldRepaint(_PintorLinea old) =>
      old.corte != corte ||
      old.domingos.length != domingos.length ||
      old.linea != linea ||
      old.colorCompra != colorCompra ||
      old.colorCorte != colorCorte ||
      old.colorLimite != colorLimite ||
      old.colorSueldo != colorSueldo;
}
