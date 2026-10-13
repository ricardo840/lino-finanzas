import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';

/// Panel translúcido con desenfoque y borde claro (glassmorfismo).
class PanelVidrio extends StatelessWidget {
  const PanelVidrio({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radio = 22,
    this.onTap,
    this.desenfoque = true,
    this.gradiente,
    this.colorBorde,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radio;
  final VoidCallback? onTap;

  /// Desenfoque del fondo. Se puede apagar en listas largas por rendimiento.
  final bool desenfoque;

  /// Reemplaza el relleno de vidrio (p. ej. para tarjetas de crédito).
  final Gradient? gradiente;
  final Color? colorBorde;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final bordes = BorderRadius.circular(radio);
    final contenido = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: bordes,
        gradient: gradiente ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tema.vidrioAlto, tema.vidrio],
            ),
        border: Border.all(color: colorBorde ?? tema.bordeVidrio),
      ),
      child: Padding(padding: padding, child: child),
    );
    Widget panel = ClipRRect(
      borderRadius: bordes,
      child: desenfoque && !context.reducirDesenfoque
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: contenido,
            )
          : contenido,
    );
    if (onTap != null) panel = Presionable(onTap: onTap, child: panel);
    return panel;
  }
}

/// Panel de vidrio para las piezas que flotan sobre el contenido (la isla de
/// pestañas y el encabezado): más opaco que un panel normal, para que se lea
/// lo que lleva dentro, y con sombra.
class PanelIsla extends StatelessWidget {
  const PanelIsla({
    super.key,
    required this.child,
    required this.radio,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final sombra = tema.esOscuro
        ? tema.fondo.last.withValues(alpha: 0.55)
        : tema.texto.withValues(alpha: 0.16);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: [BoxShadow(color: sombra, blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: PanelVidrio(
        radio: radio,
        padding: padding,
        gradiente: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(tema.vidrioAlto, tema.barra),
            Color.alphaBlend(tema.vidrio, tema.barra),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Da respuesta visual al tocar (se encoge y atenúa un poco).
class Presionable extends StatefulWidget {
  const Presionable({super.key, required this.onTap, required this.child, this.onLongPress});

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _presionado = false;

  void _cambiar(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: activo ? (_) => _cambiar(true) : null,
      onTapUp: activo ? (_) => _cambiar(false) : null,
      onTapCancel: activo ? () => _cambiar(false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !activo ? 0.45 : (_presionado ? 0.8 : 1.0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _presionado ? 0.98 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

enum EstiloBoton { primario, secundario, destructivo }

/// Botón principal de Lino.
class BotonLino extends StatelessWidget {
  const BotonLino({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.estilo = EstiloBoton.primario,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final EstiloBoton estilo;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final (Color fondo, Color frente, Color? borde) = switch (estilo) {
      EstiloBoton.primario => (tema.acento, tema.sobreAcento, null),
      EstiloBoton.secundario => (tema.vidrioAlto, tema.texto, tema.bordeVidrio),
      EstiloBoton.destructivo => (
          tema.negativo.withValues(alpha: 0.14),
          tema.negativo,
          tema.negativo.withValues(alpha: 0.35),
        ),
    };
    return Presionable(
      onTap: cargando ? null : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(16),
          border: borde == null ? null : Border.all(color: borde),
        ),
        alignment: Alignment.center,
        child: cargando
            ? CupertinoActivityIndicator(color: frente)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 18, color: frente),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    texto,
                    style: TextStyle(
                      color: frente,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Botón pequeño de icono para barras de navegación.
class BotonIcono extends StatelessWidget {
  const BotonIcono({super.key, required this.icono, required this.onPressed, this.tamano = 24});

  final IconData icono;
  final VoidCallback? onPressed;
  final double tamano;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icono, size: tamano, color: context.tema.acento),
      );
}
