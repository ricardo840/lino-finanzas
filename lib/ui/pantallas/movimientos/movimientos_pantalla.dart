import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../data/modelos/movimiento.dart';
import '../../../estado/datos.dart';
import '../../tema/contexto.dart';
import '../../widgets/comunes.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import 'movimiento_form_pantalla.dart';

class MovimientosPantalla extends ConsumerWidget {
  const MovimientosPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lunes = ref.watch(semanaSeleccionadaProvider);
    final movimientos = ref.watch(movimientosSemanaProvider(lunes));
    final cuentas = ref.watch(cuentasProvider);
    // valueOrNull conserva los datos anteriores mientras se recargan, para
    // que la lista no parpadee después de cada cambio.
    final lista = movimientos.valueOrNull;
    final listaCuentas = cuentas.valueOrNull;
    final error = movimientos.error ?? cuentas.error;

    return PaginaPestana(
      titulo: 'Movimientos',
      derecha: BotonIcono(
        icono: CupertinoIcons.plus_circle_fill,
        tamano: 28,
        onPressed: () => abrirPantalla<void>(context, const MovimientoFormPantalla(), modal: true),
      ),
      hijos: [
        const SelectorSemana(),
        const SizedBox(height: 4),
        if (error != null)
          ErrorDatos(error)
        else if (lista == null || listaCuentas == null)
          const Cargando()
        else
          ..._contenido(context, lista, {for (final c in listaCuentas) c.cuenta.id!: c.cuenta}),
      ],
    );
  }

  List<Widget> _contenido(BuildContext context, List<Movimiento> lista, Map<int, Cuenta> cuentas) {
    if (lista.isEmpty) {
      return [
        const SizedBox(height: 8),
        EstadoVacio(
          icono: CupertinoIcons.list_bullet,
          titulo: 'Semana sin movimientos',
          mensaje: 'Lo que registres aquí se suma a esta semana. El sueldo del domingo cuenta para la semana que empieza.',
          accion: 'Registrar movimiento',
          alAccion: () => abrirPantalla<void>(context, const MovimientoFormPantalla(), modal: true),
        ),
      ];
    }

    final ingresos = lista
        .where((m) => m.tipo == TipoMovimiento.ingreso)
        .fold<int>(0, (s, m) => s + m.monto);
    final gastos = lista
        .where((m) => m.tipo == TipoMovimiento.egreso)
        .fold<int>(0, (s, m) => s + m.monto);

    // Agrupar por día conservando el orden (más reciente primero).
    final dias = <DateTime, List<Movimiento>>{};
    for (final m in lista) {
      dias.putIfAbsent(soloFecha(m.fecha), () => []).add(m);
    }

    return [
      const SizedBox(height: 8),
      _TotalesSemana(ingresos: ingresos, gastos: gastos),
      for (final entrada in dias.entries) ...[
        EncabezadoDia(entrada.key),
        PanelVidrio(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final m in entrada.value)
                FilaMovimiento(
                  movimiento: m,
                  cuentas: cuentas,
                  onTap: () => abrirPantalla<void>(
                    context,
                    MovimientoFormPantalla(movimiento: m),
                    modal: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }
}

class _TotalesSemana extends StatelessWidget {
  const _TotalesSemana({required this.ingresos, required this.gastos});

  final int ingresos;
  final int gastos;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return PanelVidrio(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingresos', style: tema.secundario),
                MontoTexto(ingresos, color: tema.positivo),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastos', style: tema.secundario),
                MontoTexto(gastos, color: tema.negativo),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance', style: tema.secundario),
                MontoTexto(ingresos - gastos, colorear: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
