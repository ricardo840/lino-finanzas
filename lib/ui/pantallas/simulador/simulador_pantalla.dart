import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../core/formato.dart';
import '../../../dominio/simulador_compra.dart';
import '../../../estado/datos.dart';
import '../../../estado/navegacion.dart';
import '../../tema/contexto.dart';
import '../../widgets/campos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/vidrio.dart';

/// "¿Cuándo y con qué me conviene comprar?"
class SimuladorVista extends ConsumerStatefulWidget {
  const SimuladorVista({super.key});

  @override
  ConsumerState<SimuladorVista> createState() => _SimuladorVistaState();
}

class _SimuladorVistaState extends ConsumerState<SimuladorVista> {
  final _monto = TextEditingController();
  DateTime _fecha = soloFecha(DateTime.now());
  int _espera = 0;
  bool _calculando = false;
  ResultadoSimulacion? _resultado;

  static const _opcionesEspera = {0: 'Hoy', 3: '3 días', 7: '1 sem', 15: '15 días', 30: '1 mes'};

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = soloFecha(DateTime.now());
    final fecha = await elegirFecha(
      context,
      inicial: _fecha.isBefore(hoy) ? hoy : _fecha,
      minima: hoy,
      maxima: sumarDias(hoy, 365),
    );
    if (fecha != null && mounted) {
      setState(() {
        _fecha = soloFecha(fecha);
        _resultado = null;
      });
    }
  }

  Future<void> _simular() async {
    FocusScope.of(context).unfocus();
    final monto = parsearDinero(_monto.text);
    if (monto == null || monto <= 0) {
      await avisar(context, titulo: 'Monto inválido', mensaje: 'Escribe cuánto cuesta la compra.');
      return;
    }
    setState(() => _calculando = true);
    final cuentas = await ref.read(cuentasProvider.future);
    final lunes = semanaPresupuestal(_fecha, esSueldo: false, esFijo: false);
    final resumen = await ref.read(resumenSemanalProvider(lunes).future);
    final resultado = simularCompra(
      monto: monto,
      fecha: _fecha,
      diasEspera: _espera,
      cuentas: cuentas,
      disponibleSemana: resumen.disponible,
    );
    if (!mounted) return;
    setState(() {
      _calculando = false;
      _resultado = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    // El calendario puede pedir que se simule una compra en un día concreto.
    ref.listen<DateTime?>(diaPorSimularProvider, (_, dia) {
      if (dia == null) return;
      setState(() {
        _fecha = dia;
        _resultado = null;
      });
      ref.read(diaPorSimularProvider.notifier).atender();
    });
    final tema = context.tema;
    final resultado = _resultado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Text(
            'Te digo cuándo y con qué conviene pagar, según tus fechas de corte, tu semana y tu ahorro.',
            style: tema.secundario,
          ),
        ),
        const Etiqueta('¿Cuánto cuesta?'),
        CampoVidrio(
          controller: _monto,
          placeholder: '0.00',
          prefijo: '\$',
          alineacion: TextAlign.center,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          formatos: formatoMonto,
          estilo: tema.montoGrande.copyWith(fontSize: 30),
          onChanged: (_) {
            if (_resultado != null) setState(() => _resultado = null);
          },
        ),
        const SizedBox(height: 16),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: 'Compraría el',
              valor: capitalizar(fechaMedia(_fecha)),
              icono: CupertinoIcons.calendar,
              onTap: _elegirFecha,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Etiqueta('¿Puedo esperar?'),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _espera,
          backgroundColor: tema.campo,
          thumbColor: tema.vidrioAlto,
          children: {
            for (final e in _opcionesEspera.entries)
              e.key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(e.value, style: tema.cuerpo.copyWith(fontSize: 13)),
              ),
          },
          onValueChanged: (v) {
            if (v != null) {
              setState(() {
                _espera = v;
                _resultado = null;
              });
            }
          },
        ),
        const SizedBox(height: 20),
        BotonLino(
          texto: 'Simular compra',
          icono: CupertinoIcons.lightbulb,
          cargando: _calculando,
          onPressed: _simular,
        ),
        if (resultado != null) ..._resultados(resultado),
      ],
    );
  }

  List<Widget> _resultados(ResultadoSimulacion r) {
    final tema = context.tema;
    final rec = r.recomendacion;
    final (IconData icono, Color color) = switch (rec.metodo) {
      MetodoSugerido.credito => (CupertinoIcons.creditcard_fill, tema.acento),
      MetodoSugerido.esperar => (CupertinoIcons.clock, tema.advertencia),
      MetodoSugerido.debito => (CupertinoIcons.creditcard, tema.positivo),
      MetodoSugerido.sinFondos => (CupertinoIcons.exclamationmark_triangle, tema.negativo),
    };
    return [
      const TituloSeccion('Recomendación'),
      PanelVidrio(
        colorBorde: color.withValues(alpha: 0.55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconoCirculo(icono: icono, color: color, tamano: 42),
                const SizedBox(width: 12),
                Expanded(child: Text(rec.titulo, style: tema.subtitulo)),
              ],
            ),
            const SizedBox(height: 14),
            for (final razon in rec.razones)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                      ),
                    ),
                    Expanded(child: Text(razon, style: tema.cuerpo.copyWith(fontSize: 14))),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (r.opcionesCredito.isNotEmpty) ...[
        const TituloSeccion('Tus tarjetas si compras ese día'),
        PanelVidrio(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < r.opcionesCredito.length; i++) ...[
                if (i > 0) Container(height: 0.5, color: tema.bordeVidrio),
                _FilaOpcionCredito(opcion: r.opcionesCredito[i]),
              ],
            ],
          ),
        ),
      ],
      if (r.opcionesDebito.isNotEmpty) ...[
        const TituloSeccion('Débito y efectivo'),
        PanelVidrio(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < r.opcionesDebito.length; i++) ...[
                if (i > 0) Container(height: 0.5, color: tema.bordeVidrio),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.opcionesDebito[i].cuenta.cuenta.nombreCompleto, style: tema.cuerpo),
                            Text(
                              r.opcionesDebito[i].alcanza ? 'Te alcanza' : 'Saldo insuficiente',
                              style: tema.secundario.copyWith(
                                color: r.opcionesDebito[i].alcanza ? null : tema.negativo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Quedaría', style: tema.secundario),
                          MontoTexto(r.opcionesDebito[i].saldoDespues, colorear: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Text('Disponible de esa semana: ', style: tema.secundario),
            MontoTexto(r.disponibleSemana, estilo: tema.secundario.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ];
  }
}

class _FilaOpcionCredito extends StatelessWidget {
  const _FilaOpcionCredito({required this.opcion});

  final OpcionCredito opcion;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final o = opcion;
    final buena = o.alcanza && o.diasParaPagar >= diasMinimosCredito;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.tarjeta.cuenta.nombreCompleto, style: tema.cuerpo),
                const SizedBox(height: 2),
                Text(
                  o.alcanza
                      ? 'Corte ${fechaCorta(o.corte)} · paga antes del ${fechaCorta(o.limitePago)}'
                      : 'Sin crédito disponible suficiente',
                  style: tema.secundario.copyWith(color: o.alcanza ? null : tema.negativo),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${o.diasParaPagar}',
                style: tema.titulo.copyWith(color: buena ? tema.positivo : tema.advertencia),
              ),
              Text('días', style: tema.secundario),
            ],
          ),
        ],
      ),
    );
  }
}
