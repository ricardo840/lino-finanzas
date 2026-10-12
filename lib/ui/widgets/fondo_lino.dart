import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../tema/contexto.dart';

/// Fondo de todas las pantallas: degradado con manchas de color difuminadas
/// sobre las que se ven los paneles de vidrio.
class FondoLino extends StatelessWidget {
  const FondoLino({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final opacidad = tema.esOscuro ? 0.55 : 0.70;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tema.fondo,
            ),
          ),
        ),
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70, tileMode: ui.TileMode.decal),
            child: LayoutBuilder(
              builder: (context, limites) {
                final w = limites.maxWidth;
                final h = limites.maxHeight;
                return Stack(
                  children: [
                    Positioned(
                      left: -w * 0.30,
                      top: -h * 0.06,
                      child: _Mancha(diametro: w * 0.95, color: tema.manchas[0].withValues(alpha: opacidad)),
                    ),
                    Positioned(
                      right: -w * 0.35,
                      top: h * 0.32,
                      child: _Mancha(diametro: w * 0.85, color: tema.manchas[1].withValues(alpha: opacidad)),
                    ),
                    Positioned(
                      left: -w * 0.10,
                      bottom: -h * 0.10,
                      child: _Mancha(diametro: w * 0.90, color: tema.manchas[2].withValues(alpha: opacidad)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Mancha extends StatelessWidget {
  const _Mancha({required this.diametro, required this.color});

  final double diametro;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: diametro,
        height: diametro,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
