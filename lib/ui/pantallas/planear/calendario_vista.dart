import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../core/formato.dart';
import '../../../data/modelos/compra_planeada.dart';
import '../../../dominio/calendario.dart';
import '../../../estado/ajustes.dart';
import '../../../estado/datos.dart';
import '../../../estado/navegacion.dart';
import '../../tema/contexto.dart';
import '../../tema/lino_tema.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import '../movimientos/movimiento_form_pantalla.dart';

Color _colorDe(TipoEvento tipo, LinoTema tema) => switch (tipo) {
      TipoEvento.sueldo => tema.positivo,
      TipoEvento.corte => tema.acento,
      TipoEvento.limitePago => tema.negativo,
      TipoEvento.gastoFijo => tema.advertencia,
      TipoEvento.compraPlaneada => tema.texto,
    };

IconData _iconoDe(TipoEvento tipo) => switch (tipo) {
      TipoEvento.sueldo => CupertinoIcons.briefcase,
      TipoEvento.corte => CupertinoIcons.scissors,
      TipoEvento.limitePago => CupertinoIcons.creditcard,
      TipoEvento.gastoFijo => CupertinoIcons.pin,
      TipoEvento.compraPlaneada => CupertinoIcons.bag,
    };

String _nombreDe(TipoEvento tipo) => switch (tipo) {
      TipoEvento.sueldo => 'Sueldo',
      TipoEvento.corte => 'Corte',
      TipoEvento.limitePago => 'Pago de tarjeta',
      TipoEvento.gastoFijo => 'Gasto fijo',
      TipoEvento.compraPlaneada => 'Compra planeada',
    };

/// Calendario del mes con los cortes y pagos de las tarjetas, los gastos
/// fijos y los domingos de sueldo. Al tocar un día se listan sus eventos.
class CalendarioVista extends ConsumerStatefulWidget {
  const CalendarioVista({super.key});

  @override
  ConsumerState<CalendarioVista> createState() => _CalendarioVistaState();
}

class _CalendarioVistaState extends ConsumerState<CalendarioVista> {
  late DateTime _mes;
  late DateTime _dia;

  @override
  void initState() {
    super.initState();
    _dia = soloFecha(DateTime.now());
    _mes = DateTime(_dia.year, _dia.month);
  }

  void _moverMes(int cuanto) => setState(() => _mes = DateTime(_mes.year, _mes.month + cuanto));

  void _irAHoy() => setState(() {
        _dia = soloFecha(DateTime.now());
        _mes = DateTime(_dia.year, _dia.month);
      });

  void _elegir(DateTime dia) => setState(() {
        _dia = dia;
        // Tocar un día de un mes vecino cambia de mes.
        _mes = DateTime(dia.year, dia.month);
      });

  void _simular() {
    ref.read(diaPorSimularProvider.notifier).pedir(_dia);
    ref.read(vistaPlanearProvider.notifier).ver(VistaPlanear.simulador);
  }

  /// Una compra planeada se puede registrar como gasto o quitar del calendario.
  Future<void> _opcionesDeCompra(CompraPlaneada compra) async {
    final id = compra.id;
    if (id == null) return;
    final registrar = await elegirOpcion<bool>(
      context,
      titulo: compra.titulo,
      mensaje: 'Planeada para el ${fechaMedia(compra.fecha)}.',
      opciones: const [
        Opcion(true, 'Ya la hice: registrar el gasto'),
        Opcion(false, 'Quitar del calendario'),
      ],
    );
    if (registrar == null || !mounted) return;
    if (registrar) {
      final hoy = soloFecha(DateTime.now());
      final guardado = await abrirPantalla<bool>(
        context,
        MovimientoFormPantalla(
          montoInicial: compra.monto,
          cuentaInicialId: compra.cuentaId,
          descripcionInicial: compra.descripcion,
          fechaInicial: compra.fecha.isAfter(hoy) ? hoy : compra.fecha,
        ),
        modal: true,
      );
      if (guardado != true) return;
    }
    await ref.escribir((repo) => repo.eliminarCompraPlaneada(id));
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final cuentas = ref.watch(cuentasProvider);
    final fijos = ref.watch(gastosFijosProvider);
    final compras = ref.watch(comprasPlaneadasProvider);
    final sueldoHabitual = ref.watch(ajustesProvider.select((a) => a.sueldoHabitual));
    final error = cuentas.error ?? fijos.error ?? compras.error;
    if (error != null) return ErrorDatos(error);
    final listaCuentas = cuentas.valueOrNull;
    final listaFijos = fijos.valueOrNull;
    final listaCompras = compras.valueOrNull;
    if (listaCuentas == null || listaFijos == null || listaCompras == null) {
      return const Cargando();
    }

    final hoy = soloFecha(DateTime.now());
    // Se calculan los dos meses vecinos para marcar también los días que se
    // asoman en la cuadrícula.
    final eventos = [
      for (final desplazo in const [-1, 0, 1])
        ...eventosDelMes(
          anio: _mes.year,
          mes: _mes.month + desplazo,
          cuentas: listaCuentas,
          gastosFijos: listaFijos,
          compras: listaCompras,
          hoy: hoy,
          sueldoHabitual: sueldoHabitual,
        ),
    ];
    List<EventoCalendario> eventosDe(DateTime dia) =>
        [for (final e in eventos) if (mismaFecha(e.fecha, dia)) e];

    final dias = diasDeCuadricula(_mes.year, _mes.month);
    final delDia = eventosDe(_dia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelVidrio(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BotonIcono(
                    icono: CupertinoIcons.chevron_left,
                    tamano: 20,
                    onPressed: () => _moverMes(-1),
                  ),
                  Expanded(
                    child: Presionable(
                      onTap: _irAHoy,
                      child: Text(
                        '${capitalizar(mesesLargos[_mes.month - 1])} ${_mes.year}',
                        textAlign: TextAlign.center,
                        style: tema.subtitulo,
                      ),
                    ),
                  ),
                  BotonIcono(
                    icono: CupertinoIcons.chevron_right,
                    tamano: 20,
                    onPressed: () => _moverMes(1),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final inicial in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(inicial, textAlign: TextAlign.center, style: tema.etiqueta),
                      ),
                    ),
                ],
              ),
              for (var semana = 0; semana < dias.length; semana += 7)
                Row(
                  children: [
                    for (final dia in dias.sublist(semana, semana + 7))
                      Expanded(
                        child: _CeldaDia(
                          dia: dia,
                          delMes: dia.month == _mes.month,
                          esHoy: mismaFecha(dia, hoy),
                          seleccionado: mismaFecha(dia, _dia),
                          tipos: {for (final e in eventosDe(dia)) e.tipo},
                          onTap: () => _elegir(dia),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final tipo in TipoEvento.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Punto(color: _colorDe(tipo, tema)),
                    const SizedBox(width: 6),
                    Text(_nombreDe(tipo), style: tema.secundario.copyWith(fontSize: 12)),
                  ],
                ),
            ],
          ),
        ),
        TituloSeccion(capitalizar(fechaMedia(_dia))),
        if (delDia.isEmpty)
          PanelVidrio(child: Text('Sin eventos este día.', style: tema.secundario))
        else
          PanelVidrio(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < delDia.length; i++) ...[
                  if (i > 0) Container(height: 0.5, color: tema.bordeVidrio),
                  if (delDia[i].compra case final compra?)
                    Presionable(
                      onTap: () => _opcionesDeCompra(compra),
                      child: _FilaEvento(evento: delDia[i]),
                    )
                  else
                    _FilaEvento(evento: delDia[i]),
                ],
              ],
            ),
          ),
        if (!_dia.isBefore(hoy)) ...[
          const SizedBox(height: 14),
          BotonLino(
            texto: 'Simular una compra este día',
            icono: CupertinoIcons.lightbulb,
            estilo: EstiloBoton.secundario,
            onPressed: _simular,
          ),
        ],
      ],
    );
  }
}

class _CeldaDia extends StatelessWidget {
  const _CeldaDia({
    required this.dia,
    required this.delMes,
    required this.esHoy,
    required this.seleccionado,
    required this.tipos,
    required this.onTap,
  });

  final DateTime dia;
  final bool delMes;
  final bool esHoy;
  final bool seleccionado;
  final Set<TipoEvento> tipos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final colorNumero = seleccionado
        ? tema.sobreAcento
        : delMes
            ? tema.texto
            : tema.textoSecundario.withValues(alpha: 0.45);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seleccionado ? tema.acento : null,
                border: esHoy && !seleccionado ? Border.all(color: tema.acento, width: 1.5) : null,
              ),
              child: Text(
                '${dia.day}',
                style: tema.cuerpo.copyWith(
                  color: colorNumero,
                  fontWeight: esHoy || seleccionado ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final tipo in TipoEvento.values)
                    if (tipos.contains(tipo))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: _Punto(
                          color: _colorDe(tipo, tema).withValues(alpha: delMes ? 1 : 0.4),
                          tamano: 5,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.color, this.tamano = 8});

  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _FilaEvento extends StatelessWidget {
  const _FilaEvento({required this.evento});

  final EventoCalendario evento;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final monto = evento.monto;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconoCirculo(icono: _iconoDe(evento.tipo), color: _colorDe(evento.tipo, tema)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.titulo, style: tema.cuerpo, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (evento.detalle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(evento.detalle, style: tema.secundario),
                ],
              ],
            ),
          ),
          if (monto != null) ...[
            const SizedBox(width: 8),
            MontoTexto(monto, estilo: tema.monto.copyWith(fontSize: 15)),
          ],
        ],
      ),
    );
  }
}
