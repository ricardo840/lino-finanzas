import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'vidrio.dart';

/// Cápsula de vidrio que hace de encabezado: título al centro y una acción a
/// cada lado. Es la pareja, arriba, de la isla de pestañas.
class CapsulaEncabezado extends StatelessWidget {
  const CapsulaEncabezado({super.key, required this.titulo, this.izquierda, this.derecha});

  final String titulo;
  final Widget? izquierda;
  final Widget? derecha;

  static const double altura = 52;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return MediaQuery.withNoTextScaling(
      child: PanelIsla(
        radio: altura / 2,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: altura,
          child: NavigationToolbar(
            leading: izquierda,
            middle: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.subtitulo,
            ),
            trailing: derecha,
            middleSpacing: 8,
          ),
        ),
      ),
    );
  }
}

/// Encabezado flotante de una pantalla: un velo que desvanece el contenido que
/// pasa bajo la barra de estado y, encima, la [CapsulaEncabezado].
///
/// Va dentro de un `Positioned(top: 0, left: 0, right: 0)`; el contenido debe
/// dejar libre arriba la barra de estado más [espacio].
class EncabezadoFlotante extends StatelessWidget {
  const EncabezadoFlotante({super.key, required this.titulo, this.izquierda, this.derecha});

  final String titulo;
  final Widget? izquierda;
  final Widget? derecha;

  static const double _margen = 6;

  /// Alto que ocupa el encabezado debajo de la barra de estado.
  static const double espacio = _margen + CapsulaEncabezado.altura + 14;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final arriba = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: arriba + espacio + 18,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tema.fondo.first.withValues(alpha: 0.92),
                    tema.fondo.first.withValues(alpha: 0),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, arriba + _margen, 16, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: CapsulaEncabezado(titulo: titulo, izquierda: izquierda, derecha: derecha),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acción de texto dentro del encabezado ("Cancelar", "Guardar").
class BotonTextoEncabezado extends StatelessWidget {
  const BotonTextoEncabezado({
    super.key,
    required this.texto,
    required this.onPressed,
    this.fuerte = false,
  });

  final String texto;
  final VoidCallback? onPressed;

  /// En negrita, para la acción principal.
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Presionable(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          texto,
          style: TextStyle(
            color: tema.acento,
            fontSize: 16,
            fontWeight: fuerte ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
