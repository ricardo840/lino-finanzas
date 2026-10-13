import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'lino_tema.dart';
import 'temas.dart';

extension TemaEnContexto on BuildContext {
  /// Tema activo de Lino.
  LinoTema get tema => LinoTemaScope.maybeOf(this) ?? temaPorId(temaPorDefectoId);

  /// true si en Ajustes se pidió quitar el desenfoque de los paneles.
  bool get reducirDesenfoque => LinoTemaScope.alcanceDe(this)?.reducirDesenfoque ?? false;

  /// Respuesta háptica breve al tocar, si está encendida en Ajustes.
  void vibrarToque() {
    if (LinoTemaScope.alcanceDe(this)?.vibracion ?? true) HapticFeedback.selectionClick();
  }

  /// Respuesta háptica fuerte para un error, si está encendida en Ajustes.
  void vibrarError() {
    if (LinoTemaScope.alcanceDe(this)?.vibracion ?? true) unawaited(HapticFeedback.heavyImpact());
  }
}
