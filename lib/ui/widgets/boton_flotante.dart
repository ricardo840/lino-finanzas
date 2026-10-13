import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'vidrio.dart';

/// Acción principal de una pestaña: una cápsula con icono y texto que flota
/// arriba de la isla, para que se entienda qué hace sin tocarla.
class BotonFlotante extends StatelessWidget {
  const BotonFlotante({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono = CupertinoIcons.add,
  });

  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  static const double altura = 48;

  /// Separación entre el botón y la isla.
  static const double separacion = 12;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final sombra = tema.esOscuro
        ? tema.fondo.last.withValues(alpha: 0.6)
        : tema.texto.withValues(alpha: 0.22);
    return MediaQuery.withNoTextScaling(
      child: Semantics(
        button: true,
        child: Presionable(
          onTap: onPressed,
          child: Container(
            height: altura,
            padding: const EdgeInsets.only(left: 14, right: 18),
            decoration: BoxDecoration(
              color: tema.acento,
              borderRadius: BorderRadius.circular(altura / 2),
              boxShadow: [
                BoxShadow(color: sombra, blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 20, color: tema.sobreAcento),
                const SizedBox(width: 6),
                Text(
                  texto,
                  style: TextStyle(
                    color: tema.sobreAcento,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
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
