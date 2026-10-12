import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'fondo_lino.dart';

/// Página de pestaña con título grande que se contrae al hacer scroll.
class PaginaPestana extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tema = context.tema;
    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      child: FondoLino(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(titulo),
              backgroundColor: tema.barra,
              border: null,
              leading: izquierda,
              trailing: derecha,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 28),
              sliver: SliverList(delegate: SliverChildListDelegate(hijos)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de formulario con Cancelar / Guardar en la barra.
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
    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: tema.barra,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancelar'),
        ),
        middle: Text(titulo),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: guardando ? null : alGuardar,
          child: guardando
              ? const CupertinoActivityIndicator()
              : Text(textoGuardar, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      child: FondoLino(
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 32),
              children: hijos,
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre una pantalla. Con [modal] cubre también la barra de pestañas.
Future<T?> abrirPantalla<T>(BuildContext context, Widget pantalla, {bool modal = false}) {
  return Navigator.of(context, rootNavigator: modal).push<T>(
    CupertinoPageRoute<T>(fullscreenDialog: modal, builder: (_) => pantalla),
  );
}
