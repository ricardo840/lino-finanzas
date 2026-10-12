import 'package:flutter/cupertino.dart';

import '../tema/contexto.dart';
import 'ajustes/ajustes_pantalla.dart';
import 'cuentas/cuentas_pantalla.dart';
import 'inicio/inicio_pantalla.dart';
import 'movimientos/movimientos_pantalla.dart';
import 'simulador/simulador_pantalla.dart';

/// Pestañas principales.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return CupertinoTabScaffold(
      backgroundColor: tema.fondo.first,
      tabBar: CupertinoTabBar(
        backgroundColor: tema.barra,
        activeColor: tema.acento,
        inactiveColor: tema.textoSecundario,
        border: Border(top: BorderSide(color: tema.bordeVidrio, width: 0.5)),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house),
            activeIcon: Icon(CupertinoIcons.house_fill),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard),
            activeIcon: Icon(CupertinoIcons.creditcard_fill),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lightbulb),
            activeIcon: Icon(CupertinoIcons.lightbulb_fill),
            label: 'Simulador',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt),
            activeIcon: Icon(CupertinoIcons.gear_alt_fill),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (context, indice) => CupertinoTabView(
        builder: (context) => switch (indice) {
          0 => const InicioPantalla(),
          1 => const CuentasPantalla(),
          2 => const MovimientosPantalla(),
          3 => const SimuladorPantalla(),
          _ => const AjustesPantalla(),
        },
      ),
    );
  }
}
