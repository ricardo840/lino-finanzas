import 'package:flutter/cupertino.dart';

import '../../widgets/fondo_lino.dart';
import '../../widgets/logo_lino.dart';

/// Pantalla breve mientras se lee si ya existe un PIN.
class CargaPantalla extends StatelessWidget {
  const CargaPantalla({super.key});

  @override
  Widget build(BuildContext context) => const FondoLino(
        child: Center(child: LogoLino(tamano: 80)),
      );
}
