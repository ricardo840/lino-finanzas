import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tema/contexto.dart';

/// Logotipo: la flor de lino (cinco pétalos y centro dorado) sobre un cuadro
/// de vidrio. Con el tema Medianoche coincide con el ícono de la app.
class LogoLino extends StatelessWidget {
  const LogoLino({super.key, this.tamano = 72});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return SizedBox.square(
      dimension: tamano,
      child: CustomPaint(
        painter: _PintorLogo(
          fondoAlto: Color.alphaBlend(tema.vidrioAlto, tema.fondo[1]),
          fondoBajo: Color.alphaBlend(tema.vidrio, tema.fondo.last),
          punta: tema.texto,
          base: tema.acento,
          centro: tema.advertencia,
          borde: tema.bordeVidrio,
        ),
      ),
    );
  }
}

class _PintorLogo extends CustomPainter {
  _PintorLogo({
    required this.fondoAlto,
    required this.fondoBajo,
    required this.punta,
    required this.base,
    required this.centro,
    required this.borde,
  });

  final Color fondoAlto;
  final Color fondoBajo;

  /// Color de la punta de cada pétalo; se degrada hacia [base].
  final Color punta;
  final Color base;
  final Color centro;
  final Color borde;

  /// El dibujo está trazado sobre una cuadrícula de 512 puntos, la misma del
  /// ícono de la app.
  static const double _cuadricula = 512;
  static const Offset _centroFlor = Offset(256, 256);
  static const Rect _cajaPetalo = Rect.fromLTRB(212, 102, 300, 250);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final area = Offset.zero & size;
    final cuadro = RRect.fromRectAndRadius(area, Radius.circular(w * 0.28));

    canvas.drawRRect(
      cuadro,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [fondoAlto, fondoBajo],
        ).createShader(area),
    );
    canvas.drawRRect(
      cuadro.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borde,
    );

    canvas.save();
    canvas.scale(w / _cuadricula);

    final petalo = Path()
      ..moveTo(256, 250)
      ..cubicTo(212, 204, 212, 142, 256, 102)
      ..cubicTo(300, 142, 300, 204, 256, 250)
      ..close();
    final pinturaPetalo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [punta, base],
      ).createShader(_cajaPetalo);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(_centroFlor.dx, _centroFlor.dy);
      canvas.rotate(i * 2 * math.pi / 5);
      canvas.translate(-_centroFlor.dx, -_centroFlor.dy);
      canvas.drawPath(petalo, pinturaPetalo);
      canvas.restore();
    }
    canvas.drawCircle(_centroFlor, 34, Paint()..color = fondoBajo);
    canvas.drawCircle(_centroFlor, 23, Paint()..color = centro);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorLogo old) =>
      old.fondoAlto != fondoAlto ||
      old.fondoBajo != fondoBajo ||
      old.punta != punta ||
      old.base != base ||
      old.centro != centro ||
      old.borde != borde;
}
