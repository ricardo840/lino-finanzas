import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../estado/navegacion.dart';
import '../../tema/contexto.dart';
import '../../widgets/paginas.dart';
import '../simulador/simulador_pantalla.dart';
import 'calendario_vista.dart';

/// Pestaña para planear: el calendario de cortes, pagos y gastos fijos, y el
/// simulador de compras.
class PlanearPantalla extends ConsumerWidget {
  const PlanearPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final vista = ref.watch(vistaPlanearProvider);
    return PaginaPestana(
      titulo: 'Planear',
      hijos: [
        CupertinoSlidingSegmentedControl<VistaPlanear>(
          groupValue: vista,
          backgroundColor: tema.campo,
          thumbColor: tema.vidrioAlto,
          children: {
            for (final v in VistaPlanear.values)
              v: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  v == VistaPlanear.calendario ? 'Calendario' : 'Simulador',
                  style: tema.cuerpo.copyWith(fontSize: 14),
                ),
              ),
          },
          onValueChanged: (v) {
            if (v != null) ref.read(vistaPlanearProvider.notifier).ver(v);
          },
        ),
        const SizedBox(height: 16),
        // Las dos vistas se conservan vivas para no perder lo que se haya
        // escrito en el simulador ni el mes que se estaba viendo.
        Visibility(
          visible: vista == VistaPlanear.calendario,
          maintainState: true,
          child: const CalendarioVista(),
        ),
        Visibility(
          visible: vista == VistaPlanear.simulador,
          maintainState: true,
          child: const SimuladorVista(),
        ),
      ],
    );
  }
}
