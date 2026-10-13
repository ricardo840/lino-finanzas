import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fechas.dart';
import '../../../core/formato.dart';
import '../../../data/modelos/compra_planeada.dart';
import '../../../dominio/simulador_compra.dart';
import '../../../estado/datos.dart';
import '../../../estado/navegacion.dart';
import '../../tema/contexto.dart';
import '../../widgets/campos.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/linea_tiempo.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import '../movimientos/movimiento_form_pantalla.dart';

/// Simulador de compras: con cuánto cuesta y entre qué fechas se podría
/// comprar, recomienda el mejor día y con qué pagar.
class SimuladorVista extends ConsumerStatefulWidget {
  const SimuladorVista({super.key});

  @override
  ConsumerState<SimuladorVista> createState() => _SimuladorVistaState();
}

class _SimuladorVistaState extends ConsumerState<SimuladorVista> {
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();
  late DateTime _desde;
  late DateTime _hasta;
  bool _calculando = false;
  ResultadoSimulacion? _resultado;

  @override
  void initState() {
    super.initState();
    _desde = soloFecha(DateTime.now());
    _hasta = _desde;
  }

  @override
  void dispose() {
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _fijarRango(DateTime desde, DateTime hasta) => setState(() {
        _desde = desde;
        _hasta = hasta.isBefore(desde) ? desde : hasta;
        _resultado = null;
      });

  /// Atajos del rango: nombre y último día, siempre a partir de hoy.
  List<(String, DateTime)> _atajos(DateTime hoy) => [
        ('Hoy', hoy),
        ('Esta semana', sumarDias(lunesDe(hoy), 6)),
        ('Este mes', DateTime(hoy.year, hoy.month, diasEnMes(hoy.year, hoy.month))),
        ('30 días', sumarDias(hoy, 30)),
      ];

  Future<void> _elegirDesde() async {
    final hoy = soloFecha(DateTime.now());
    final fecha = await elegirFecha(
      context,
      inicial: _desde.isBefore(hoy) ? hoy : _desde,
      minima: hoy,
      maxima: sumarDias(hoy, 365),
    );
    if (fecha != null && mounted) _fijarRango(soloFecha(fecha), _hasta);
  }

  Future<void> _elegirHasta() async {
    final fecha = await elegirFecha(
      context,
      inicial: _hasta,
      minima: _desde,
      maxima: sumarDias(_desde, 365),
    );
    if (fecha != null && mounted) _fijarRango(_desde, soloFecha(fecha));
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
    final lunes = semanaPresupuestal(_desde, esSueldo: false, esFijo: false);
    final resumen = await ref.read(resumenSemanalProvider(lunes).future);
    // Poder esperar hasta el último día del rango es lo que el motor llama
    // días de espera.
    final resultado = simularCompra(
      monto: monto,
      fecha: _desde,
      diasEspera: diasEntre(_desde, _hasta),
      cuentas: cuentas,
      disponibleSemana: resumen.disponible,
    );
    if (!mounted) return;
    setState(() {
      _calculando = false;
      _resultado = resultado;
    });
  }

  /// Día en que conviene comprar según la recomendación.
  DateTime _diaRecomendado(ResultadoSimulacion r) => r.recomendacion.fechaSugerida ?? _desde;

  /// Cuenta o tarjeta recomendada, si la hay.
  int? _cuentaRecomendada(ResultadoSimulacion r) =>
      r.recomendacion.credito?.tarjeta.cuenta.id ?? r.recomendacion.debito?.cuenta.cuenta.id;

  Future<void> _guardarPlaneada(ResultadoSimulacion r) async {
    final dia = _diaRecomendado(r);
    await ref.escribir(
      (repo) => repo.guardarCompraPlaneada(
        CompraPlaneada(
          descripcion: _descripcion.text.trim(),
          monto: r.monto,
          fecha: dia,
          cuentaId: _cuentaRecomendada(r),
          creadaEn: DateTime.now(),
        ),
      ),
    );
    if (!mounted) return;
    await avisar(
      context,
      titulo: 'Compra planeada',
      mensaje: 'La verás en el calendario el ${fechaMedia(dia)}.',
    );
  }

  Future<void> _registrar(ResultadoSimulacion r) => abrirPantalla<bool>(
        context,
        MovimientoFormPantalla(
          montoInicial: r.monto,
          cuentaInicialId: _cuentaRecomendada(r),
          descripcionInicial: _descripcion.text.trim(),
          fechaInicial: _diaRecomendado(r),
        ),
        modal: true,
      );

  @override
  Widget build(BuildContext context) {
    // El calendario puede pedir que se simule una compra en un día concreto.
    ref.listen<DateTime?>(diaPorSimularProvider, (_, dia) {
      if (dia == null) return;
      _fijarRango(dia, dia);
      ref.read(diaPorSimularProvider.notifier).atender();
    });
    final tema = context.tema;
    final resultado = _resultado;
    final hoy = soloFecha(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Text(
            'Dime cuánto cuesta y entre qué fechas podrías comprar. Te digo el mejor día y con qué pagar.',
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
        const Etiqueta('¿Qué vas a comprar? (opcional)'),
        CampoVidrio(controller: _descripcion, placeholder: 'Audífonos, llantas...', maxLength: 80),
        const SizedBox(height: 16),
        const Etiqueta('¿Cuándo podrías comprar?'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (nombre, fin) in _atajos(hoy))
              _Atajo(
                texto: nombre,
                activo: mismaFecha(_desde, hoy) && mismaFecha(_hasta, fin),
                onTap: () => _fijarRango(hoy, fin),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GrupoFilas(
          filas: [
            FilaSelector(
              etiqueta: 'Desde',
              valor: capitalizar(fechaMedia(_desde)),
              icono: CupertinoIcons.calendar,
              onTap: _elegirDesde,
            ),
            FilaSelector(
              etiqueta: 'Hasta',
              valor: capitalizar(fechaMedia(_hasta)),
              icono: CupertinoIcons.calendar_today,
              onTap: _elegirHasta,
            ),
          ],
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
    final credito = rec.credito;
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
            if (credito != null) ...[
              const SizedBox(height: 16),
              LineaTiempoCompra(
                compra: credito.fechaCompra,
                corte: credito.corte,
                limite: credito.limitePago,
              ),
            ],
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
      const SizedBox(height: 12),
      if (rec.metodo != MetodoSugerido.sinFondos) ...[
        BotonLino(
          texto: 'Registrar esta compra',
          icono: CupertinoIcons.add,
          onPressed: () => _registrar(r),
        ),
        const SizedBox(height: 10),
      ],
      BotonLino(
        texto: 'Guardar como compra planeada',
        icono: CupertinoIcons.calendar_badge_plus,
        estilo: EstiloBoton.secundario,
        onPressed: () => _guardarPlaneada(r),
      ),
      if (r.opcionesCredito.isNotEmpty) ...[
        TituloSeccion('Tus tarjetas si compras el ${fechaCorta(_desde)}'),
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

/// Atajo para elegir un rango de fechas común.
class _Atajo extends StatelessWidget {
  const _Atajo({required this.texto, required this.activo, required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Presionable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? tema.acento.withValues(alpha: 0.18) : tema.campo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? tema.acento : tema.bordeVidrio),
        ),
        child: Text(
          texto,
          style: tema.secundario.copyWith(color: activo ? tema.texto : tema.textoSecundario),
        ),
      ),
    );
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
