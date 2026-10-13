import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import '../widgets/barra_isla.dart';
import 'ajustes/ajustes_pantalla.dart';
import 'cuentas/cuentas_pantalla.dart';
import 'inicio/inicio_pantalla.dart';
import 'movimientos/movimientos_pantalla.dart';
import 'simulador/simulador_pantalla.dart';

/// Pestañas principales, con la barra en una isla flotante.
///
/// Cada pestaña tiene su propio navegador, se construye hasta la primera vez
/// que se abre y conserva su pantalla principal al cambiar a otra. Las
/// pantallas internas (Tema, Gastos fijos...) se cierran al salir, para que
/// cada pestaña abra siempre en su pantalla principal.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
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
    PestanaIsla(
      etiqueta: 'Simulador',
      icono: CupertinoIcons.lightbulb,
      iconoActivo: CupertinoIcons.lightbulb_fill,
    ),
    PestanaIsla(
      etiqueta: 'Ajustes',
      icono: CupertinoIcons.gear_alt,
      iconoActivo: CupertinoIcons.gear_alt_fill,
    ),
  ];

  final _navegadores = [
    for (var i = 0; i < _pestanas.length; i++) GlobalKey<NavigatorState>(),
  ];
  final _visitadas = <int>{0};
  int _indice = 0;

  void _alTocar(int nueva) {
    if (nueva == _indice) {
      // Tocar la pestaña abierta regresa a su pantalla principal.
      _navegadores[nueva].currentState?.popUntil((ruta) => ruta.isFirst);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      // Si la pestaña que se deja tiene pantallas internas abiertas, se le da
      // un navegador nuevo: al volver abre en su pantalla principal y no
      // parece que esta desapareció. Con una llave nueva el cambio es
      // inmediato, sin animación de regreso a medias.
      if (_navegadores[_indice].currentState?.canPop() ?? false) {
        _navegadores[_indice] = GlobalKey<NavigatorState>();
      }
      _indice = nueva;
      _visitadas.add(nueva);
    });
  }

  Widget _pagina(int indice) => CupertinoTabView(
        navigatorKey: _navegadores[indice],
        builder: (context) => switch (indice) {
          0 => const InicioPantalla(),
          1 => const CuentasPantalla(),
          2 => const MovimientosPantalla(),
          3 => const SimuladorPantalla(),
          _ => const AjustesPantalla(),
        },
      );

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final medios = MediaQuery.of(context);
    final teclado = medios.viewInsets.bottom;
    const espacioIsla = BarraIsla.altura + BarraIsla.margenInferior;

    // Igual que CupertinoTabScaffold: el teclado se descuenta aquí y, si no
    // tapa la isla, su altura se anuncia como margen inferior para que las
    // listas puedan desplazarse por encima de ella.
    var mediosContenido = medios.removeViewInsets(removeBottom: true);
    if (espacioIsla > teclado) {
      mediosContenido = mediosContenido.copyWith(
        padding: mediosContenido.padding.copyWith(
          bottom: medios.padding.bottom + espacioIsla,
        ),
      );
    }

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
                      enabled: i == _indice,
                      child: Offstage(
                        offstage: i != _indice,
                        child: TickerMode(
                          enabled: i == _indice,
                          child: _visitadas.contains(i) ? _pagina(i) : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: BarraIsla.margenLateral,
            right: BarraIsla.margenLateral,
            bottom: medios.padding.bottom + BarraIsla.margenInferior,
            child: BarraIsla(pestanas: _pestanas, indice: _indice, alTocar: _alTocar),
          ),
        ],
      ),
    );
  }
}
