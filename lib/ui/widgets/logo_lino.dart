import 'package:flutter/widgets.dart';

import '../tema/contexto.dart';

/// Logotipo: una "L" geométrica sobre un cuadro de vidrio con el acento del
/// tema.
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
          acento: tema.acento,
          trazo: tema.sobreAcento,
          borde: tema.bordeVidrio,
        ),
      ),
    );
  }
}

class _PintorLogo extends CustomPainter {
  _PintorLogo({required this.acento, required this.trazo, required this.borde});

  final Color acento;
  final Color trazo;
  final Color borde;

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
          colors: [acento, acento.withValues(alpha: 0.62)],
        ).createShader(area),
    );
    canvas.drawRRect(
      cuadro.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = borde,
    );

    final grosor = w * 0.14;
    final radio = Radius.circular(grosor / 2);
    final pintura = Paint()..color = trazo;
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.33, w * 0.22, w * 0.33 + grosor, w * 0.78, radio),
      pintura,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.33, w * 0.78 - grosor, w * 0.70, w * 0.78, radio),
      pintura,
    );
  }

  @override
  bool shouldRepaint(_PintorLogo old) =>
      old.acento != acento || old.trazo != trazo || old.borde != borde;
}
