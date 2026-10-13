import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'encabezado.dart';
import 'fondo_lino.dart';
import 'vidrio.dart';

/// Página de pestaña: el título grande va sobre el fondo y, al desplazar, se
/// convierte en una cápsula de vidrio flotante.
class PaginaPestana extends StatefulWidget {
  const PaginaPestana({
    super.key,
    required this.titulo,
    required this.hijos,
    this.izquierda,
    this.derecha,
  });

  final String titulo;
  final List<Widget> hijos;
  final Widget? izquierda;
  final Widget? derecha;

  @override
  State<PaginaPestana> createState() => _PaginaPestanaState();
}

class _PaginaPestanaState extends State<PaginaPestana> {
  /// Desplazamiento a partir del cual el título grande ya no se ve.
  static const double _umbral = 40;

  final _desplazamiento = ScrollController();
  bool _contraido = false;

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    final contraido = _desplazamiento.offset > _umbral;
    if (contraido != _contraido) setState(() => _contraido = contraido);
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final margenes = MediaQuery.paddingOf(context);
    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      child: FondoLino(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomScrollView(
              controller: _desplazamiento,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, margenes.top + 12, 16, margenes.bottom + 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TituloGrande(
                        titulo: widget.titulo,
                        izquierda: widget.izquierda,
                        derecha: widget.derecha,
                      ),
                      ...widget.hijos,
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _contraido
                    ? EncabezadoFlotante(
                        titulo: widget.titulo,
                        izquierda: widget.izquierda,
                        derecha: widget.derecha,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TituloGrande extends StatelessWidget {
  const _TituloGrande({required this.titulo, this.izquierda, this.derecha});

  final String titulo;
  final Widget? izquierda;
  final Widget? derecha;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.titulo.copyWith(fontSize: 34, letterSpacing: -1.0),
            ),
          ),
          if (izquierda != null) izquierda!,
          if (derecha != null) derecha!,
        ],
      ),
    );
  }
}

/// Página de formulario con Cancelar / Guardar en el encabezado.
class PaginaFormulario extends StatelessWidget {
  const PaginaFormulario({
    super.key,
    required this.titulo,
    required this.hijos,
    required this.alGuardar,
    this.guardando = false,
    this.textoGuardar = 'Guardar',
  });

  final String titulo;
  final List<Widget> hijos;
  final VoidCallback? alGuardar;
  final bool guardando;
  final String textoGuardar;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final margenes = MediaQuery.paddingOf(context);
    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      child: FondoLino(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  margenes.top + EncabezadoFlotante.espacio,
                  16,
                  margenes.bottom + 32,
                ),
                children: hijos,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoFlotante(
                titulo: titulo,
                izquierda: BotonTextoEncabezado(
                  texto: 'Cancelar',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                derecha: guardando
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: CupertinoActivityIndicator(),
                      )
                    : BotonTextoEncabezado(texto: textoGuardar, onPressed: alGuardar, fuerte: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla interna de una pestaña, con botón de regreso en el encabezado.
///
/// Recibe [hijos] para una lista desplazable o [cuerpo] para un contenido fijo.
class PaginaSecundaria extends StatelessWidget {
  const PaginaSecundaria({
    super.key,
    required this.titulo,
    this.derecha,
    this.hijos,
    this.cuerpo,
  }) : assert((hijos == null) != (cuerpo == null));

  final String titulo;
  final Widget? derecha;
  final List<Widget>? hijos;
  final Widget? cuerpo;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final margenes = MediaQuery.paddingOf(context);
    final arriba = margenes.top + EncabezadoFlotante.espacio;
    final lista = hijos;
    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      child: FondoLino(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (lista != null)
              ListView(
                padding: EdgeInsets.fromLTRB(16, arriba, 16, margenes.bottom + 32),
                children: lista,
              )
            else
              Padding(
                padding: EdgeInsets.only(top: arriba, bottom: margenes.bottom),
                child: cuerpo,
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EncabezadoFlotante(
                titulo: titulo,
                izquierda: BotonIcono(
                  icono: CupertinoIcons.chevron_left,
                  tamano: 22,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                derecha: derecha,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre una pantalla. Con [modal] cubre también la isla de pestañas.
Future<T?> abrirPantalla<T>(BuildContext context, Widget pantalla, {bool modal = false}) {
  return Navigator.of(context, rootNavigator: modal).push<T>(
    CupertinoPageRoute<T>(fullscreenDialog: modal, builder: (_) => pantalla),
  );
}
