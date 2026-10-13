import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../estado/navegacion.dart';
import '../tema/contexto.dart';
import '../widgets/barra_isla.dart';
import '../widgets/boton_flotante.dart';
import '../widgets/paginas.dart';
import 'ajustes/ajustes_pantalla.dart';
import 'cuentas/cuenta_form_pantalla.dart';
import 'cuentas/cuentas_pantalla.dart';
import 'inicio/inicio_pantalla.dart';
import 'movimientos/movimiento_form_pantalla.dart';
import 'movimientos/movimientos_pantalla.dart';
import 'planear/planear_pantalla.dart';

/// Pestañas principales, con la barra en una isla flotante.
///
/// Cada pestaña tiene su propio navegador, se construye hasta la primera vez
/// que se abre y conserva su pantalla principal al cambiar a otra. Las
/// pantallas internas (Tema, Gastos fijos...) se cierran al salir, para que
/// cada pestaña abra siempre en su pantalla principal.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  // En el mismo orden que las constantes de [Pestana].
  static const _pestanas = [
    PestanaIsla(
      etiqueta: 'Inicio',
      icono: CupertinoIcons.house,
      iconoActivo: CupertinoIcons.house_fill,
    ),
    PestanaIsla(
      etiqueta: 'Cuentas',
      icono: CupertinoIcons.creditcard,
      iconoActivo: CupertinoIcons.creditcard_fill,
    ),
    PestanaIsla(etiqueta: 'Movimientos', icono: CupertinoIcons.list_bullet),
    PestanaIsla(etiqueta: 'Planear', icono: CupertinoIcons.calendar),
    PestanaIsla(
      etiqueta: 'Ajustes',
      icono: CupertinoIcons.gear_alt,
      iconoActivo: CupertinoIcons.gear_alt_fill,
    ),
  ];

  final _navegadores = [
    for (var i = 0; i < _pestanas.length; i++) GlobalKey<NavigatorState>(),
  ];
  final _visitadas = <int>{};

  void _alTocar(int pestana) {
    if (pestana == ref.read(pestanaProvider)) {
      // Tocar la pestaña abierta regresa a su pantalla principal.
      _navegadores[pestana].currentState?.popUntil((ruta) => ruta.isFirst);
      return;
    }
    ref.read(pestanaProvider.notifier).ir(pestana);
  }

  /// Al cambiar de pestaña: se cierra el teclado y, si la que se deja tiene
  /// pantallas internas abiertas, se le da un navegador nuevo. Así al volver
  /// abre en su pantalla principal y no parece que esta desapareció; con una
  /// llave nueva el cambio es inmediato, sin animación de regreso a medias.
  void _alCambiar(int? anterior, int nueva) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (anterior == null) return;
    if (_navegadores[anterior].currentState?.canPop() ?? false) {
      setState(() => _navegadores[anterior] = GlobalKey<NavigatorState>());
    }
  }

  Widget _pagina(int pestana) => CupertinoTabView(
        navigatorKey: _navegadores[pestana],
        builder: (context) => switch (pestana) {
          Pestana.inicio => const InicioPantalla(),
          Pestana.cuentas => const CuentasPantalla(),
          Pestana.movimientos => const MovimientosPantalla(),
          Pestana.planear => const PlanearPantalla(),
          _ => const AjustesPantalla(),
        },
      );

  /// Acción principal de la pestaña abierta, o null si no tiene.
  BotonFlotante? _accion(int pestana) => switch (pestana) {
        Pestana.inicio || Pestana.movimientos => BotonFlotante(
            key: const ValueKey('movimiento'),
            texto: 'Movimiento',
            onPressed: () =>
                abrirPantalla<void>(context, const MovimientoFormPantalla(), modal: true),
          ),
        Pestana.cuentas => BotonFlotante(
            key: const ValueKey('cuenta'),
            texto: 'Cuenta',
            onPressed: () => abrirPantalla<void>(context, const CuentaFormPantalla(), modal: true),
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(pestanaProvider, _alCambiar);
    final indice = ref.watch(pestanaProvider);
    _visitadas.add(indice);

    final tema = context.tema;
    final medios = MediaQuery.of(context);
    final teclado = medios.viewInsets.bottom;
    final accion = _accion(indice);
    const espacioIsla = BarraIsla.altura + BarraIsla.margenInferior;
    final espacioInferior =
        espacioIsla + (accion == null ? 0 : BotonFlotante.altura + BotonFlotante.separacion);

    // Igual que CupertinoTabScaffold: el teclado se descuenta aquí y, si no
    // tapa la isla, lo que ocupan la isla y el botón flotante se anuncia como
    // margen inferior para que las listas puedan desplazarse por encima.
    var mediosContenido = medios.removeViewInsets(removeBottom: true);
    if (espacioIsla > teclado) {
      mediosContenido = mediosContenido.copyWith(
        padding: mediosContenido.padding.copyWith(
          bottom: medios.padding.bottom + espacioInferior,
        ),
      );
    }
    final bordeIsla = medios.padding.bottom + BarraIsla.margenInferior;

    return ColoredBox(
      color: tema.fondo.first,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaQuery(
            data: mediosContenido,
            child: Padding(
              padding: EdgeInsets.only(bottom: teclado),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < _pestanas.length; i++)
                    HeroMode(
                      enabled: i == indice,
                      child: Offstage(
                        offstage: i != indice,
                        child: TickerMode(
                          enabled: i == indice,
                          child: _visitadas.contains(i) ? _pagina(i) : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: BarraIsla.margenLateral,
            bottom: bordeIsla + BarraIsla.altura + BotonFlotante.separacion,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              // Con el teclado abierto quedaría escondido detrás; no se dibuja.
              child: teclado > 0 ? null : accion,
            ),
          ),
          Positioned(
            left: BarraIsla.margenLateral,
            right: BarraIsla.margenLateral,
            bottom: bordeIsla,
            child: BarraIsla(pestanas: _pestanas, indice: indice, alTocar: _alTocar),
          ),
        ],
      ),
    );
  }
}
