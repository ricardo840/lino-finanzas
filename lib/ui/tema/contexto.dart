import 'package:flutter/widgets.dart';

import 'lino_tema.dart';
import 'temas.dart';

extension TemaEnContexto on BuildContext {
  /// Tema activo de Lino.
  LinoTema get tema => LinoTemaScope.maybeOf(this) ?? temaPorId(temaPorDefectoId);
}
