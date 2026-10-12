import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/modelos/gasto_fijo.dart';
import '../../../estado/datos.dart';
import '../../categorias.dart';
import '../../tema/contexto.dart';
import '../../widgets/comunes.dart';
import '../../widgets/fondo_lino.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import 'gasto_fijo_form_pantalla.dart';

/// Plantillas de pagos fijos. Cada semana aparecen en Inicio los que faltan.
class GastosFijosPantalla extends ConsumerWidget {
  const GastosFijosPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    final fijos = ref.watch(gastosFijosProvider);

    return CupertinoPageScaffold(
      backgroundColor: tema.fondo.first,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Gastos fijos'),
        backgroundColor: tema.barra,
        border: null,
        trailing: BotonIcono(
          icono: CupertinoIcons.plus_circle_fill,
          tamano: 26,
          onPressed: () => abrirPantalla<void>(context, const GastoFijoFormPantalla(), modal: true),
        ),
      ),
      child: FondoLino(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.paddingOf(context).bottom + 32),
            children: fijos.when(
              skipLoadingOnReload: true,
              loading: () => const [Cargando()],
              error: (e, _) => [ErrorDatos(e)],
              data: (lista) {
                if (lista.isEmpty) {
                  return [
                    EstadoVacio(
                      icono: CupertinoIcons.pin,
                      titulo: 'Sin gastos fijos',
                      mensaje: 'Agrega lo que pagas cada domingo o cada mes (internet, renta, '
                          'transporte). Lino te recordará los que falten en la semana.',
                      accion: 'Agregar gasto fijo',
                      alAccion: () =>
                          abrirPantalla<void>(context, const GastoFijoFormPantalla(), modal: true),
                    ),
                  ];
                }
                final totalSemanal = lista
                    .where((g) => g.activo && g.frecuencia == FrecuenciaFijo.semanal)
                    .fold<int>(0, (s, g) => s + g.monto);
                return [
                  PanelVidrio(
                    child: Row(
                      children: [
                        Expanded(child: Text('Fijos de cada domingo', style: tema.cuerpo)),
                        MontoTexto(totalSemanal, estilo: tema.subtitulo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PanelVidrio(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < lista.length; i++) ...[
                          if (i > 0) Container(height: 0.5, color: tema.bordeVidrio),
                          _FilaFijo(gasto: lista[i]),
                        ],
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaFijo extends StatelessWidget {
  const _FilaFijo({required this.gasto});

  final GastoFijo gasto;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final g = gasto;
    final cuando = g.frecuencia == FrecuenciaFijo.semanal
        ? 'Cada domingo'
        : 'Cada mes, día ${g.diaMes ?? '-'}';
    return Presionable(
      onTap: () => abrirPantalla<void>(context, GastoFijoFormPantalla(existente: g), modal: true),
      child: Opacity(
        opacity: g.activo ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              IconoCirculo(icono: categoriaPorId(g.categoria).icono),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.nombre, style: tema.cuerpo),
                    const SizedBox(height: 2),
                    Text(g.activo ? cuando : '$cuando · pausado', style: tema.secundario),
                  ],
                ),
              ),
              MontoTexto(g.monto, estilo: tema.monto.copyWith(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
