import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formato.dart';
import '../../estado/ajustes.dart';
import '../tema/contexto.dart';

/// Muestra un monto respetando el modo privacidad.
class MontoTexto extends ConsumerWidget {
  const MontoTexto(
    this.centavos, {
    super.key,
    this.estilo,
    this.color,
    this.colorear = false,
    this.signo = false,
    this.sinCentavos = false,
    this.alineacion,
  });

  final int centavos;
  final TextStyle? estilo;
  final Color? color;

  /// Verde si es positivo, rojo si es negativo.
  final bool colorear;

  /// Antepone "+" a los positivos.
  final bool signo;
  final bool sinCentavos;
  final TextAlign? alineacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oculto = ref.watch(privacidadProvider);
    final tema = context.tema;
    var colorFinal = color;
    if (colorear) {
      colorFinal = centavos < 0
          ? tema.negativo
          : centavos > 0
              ? tema.positivo
              : null;
    }
    final texto = oculto
        ? '\$ •••••'
        : formatoDinero(centavos, conCentavos: !sinCentavos, signoMas: signo);
    final base = estilo ?? tema.monto;
    return Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alineacion,
      style: base.copyWith(
        color: colorFinal ?? base.color,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
      ),
    );
  }
}
