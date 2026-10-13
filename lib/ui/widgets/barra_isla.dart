import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'vidrio.dart';

/// Pestaña de la [BarraIsla].
class PestanaIsla {
  const PestanaIsla({required this.etiqueta, required this.icono, IconData? iconoActivo})
      : iconoActivo = iconoActivo ?? icono;

  final String etiqueta;
  final IconData icono;

  /// Icono cuando la pestaña está abierta (por lo general, el relleno).
  final IconData iconoActivo;
}

/// Barra de pestañas flotante: una isla de vidrio redondeada sobre el borde
/// inferior de la pantalla.
class BarraIsla extends StatelessWidget {
  const BarraIsla({
    super.key,
    required this.pestanas,
    required this.indice,
    required this.alTocar,
  });

  final List<PestanaIsla> pestanas;

  /// Pestaña abierta.
  final int indice;
  final ValueChanged<int> alTocar;

  static const double altura = 64;

  /// Separación entre la isla y el borde inferior útil de la pantalla.
  static const double margenInferior = 10;
  static const double margenLateral = 16;

  /// En pantallas anchas la isla no se estira de lado a lado.
  static const double anchoMaximo = 520;

  static const double _relleno = 6;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximo),
          child: PanelIsla(
            radio: altura / 2,
            padding: const EdgeInsets.all(_relleno),
            child: SizedBox(
              height: altura - _relleno * 2,
              child: Row(
                children: [
                  for (var i = 0; i < pestanas.length; i++)
                    Expanded(
                      child: _BotonIsla(
                        pestana: pestanas[i],
                        activa: i == indice,
                        onTap: () {
                          context.vibrarToque();
                          alTocar(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonIsla extends StatelessWidget {
  const _BotonIsla({required this.pestana, required this.activa, required this.onTap});

  final PestanaIsla pestana;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final color = activa ? tema.acento : tema.textoSecundario;
    return Semantics(
      button: true,
      selected: activa,
      child: Presionable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: tema.acento.withValues(alpha: activa ? 0.18 : 0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(activa ? pestana.iconoActivo : pestana.icono, size: 24, color: color),
              const SizedBox(height: 2),
              // Si el teléfono es angosto la etiqueta se encoge en vez de cortarse.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  pestana.etiqueta,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: activa ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
