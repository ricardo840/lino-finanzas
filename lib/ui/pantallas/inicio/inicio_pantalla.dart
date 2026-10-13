import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../data/modelos/movimiento.dart';
import '../../../dominio/ciclo_tarjeta.dart';
import '../../../dominio/resumen_semanal.dart';
import '../../../estado/ajustes.dart';
import '../../../estado/datos.dart';
import '../../../estado/navegacion.dart';
import '../../categorias.dart';
import '../../tema/contexto.dart';
import '../../tema/temas.dart';
import '../../widgets/comunes.dart';
import '../../widgets/dialogos.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import '../cuentas/cuenta_form_pantalla.dart';
import '../movimientos/movimiento_form_pantalla.dart';

class InicioPantalla extends ConsumerWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lunes = ref.watch(semanaSeleccionadaProvider);
    final resumen = ref.watch(resumenSemanalProvider(lunes));
    final cuentas = ref.watch(cuentasProvider);
    final privacidad = ref.watch(privacidadProvider);

    return PaginaPestana(
      titulo: 'Lino',
      izquierda: BotonIcono(
        icono: privacidad ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        onPressed: () => ref.read(ajustesProvider.notifier).alternarPrivacidad(),
      ),
      hijos: cuentas.when(
          skipLoadingOnReload: true,
        loading: () => const [Cargando()],
        error: (e, _) => [ErrorDatos(e)],
        data: (lista) {
          if (lista.isEmpty) return const [_Bienvenida()];
          final porId = {for (final c in lista) c.cuenta.id!: c.cuenta};
          return [
            const SelectorSemana(),
            const SizedBox(height: 12),
            resumen.when(
          skipLoadingOnReload: true,
              loading: () => const Cargando(),
              error: (e, _) => ErrorDatos(e),
              data: (r) => _PanelSemana(resumen: r),
            ),
            if (resumen.valueOrNull?.pendientes.isNotEmpty ?? false)
              _PanelPendientes(resumen: resumen.requireValue, cuentas: lista),
            _PanelTarjetas(cuentas: lista),
            _PanelAhorro(cuentas: lista),
            _UltimosMovimientos(cuentas: porId),
          ];
        },
      ),
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: EstadoVacio(
        icono: CupertinoIcons.creditcard,
        titulo: 'Empieza con tus cuentas',
        mensaje: 'Agrega tus cuentas de débito, tarjetas de crédito, efectivo y ahorro. '
            'Con eso Lino calcula tu semana y te recomienda cómo pagar.',
        accion: 'Agregar cuenta',
        alAccion: () => abrirPantalla<void>(context, const CuentaFormPantalla(), modal: true),
      ),
    );
  }
}

class _PanelSemana extends StatelessWidget {
  const _PanelSemana({required this.resumen});

  final ResumenSemanal resumen;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final r = resumen;
    final colorBarra = r.avance >= 1
        ? tema.negativo
        : r.avance >= 0.85
            ? tema.advertencia
            : tema.acento;
    return PanelVidrio(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISPONIBLE DE LA SEMANA', style: tema.etiqueta),
          const SizedBox(height: 6),
          MontoTexto(
            r.disponible,
            estilo: tema.montoGrande,
            color: r.disponible < 0 ? tema.negativo : null,
          ),
          if (r.pendientes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text('Tras pagos fijos pendientes: ', style: tema.secundario),
                MontoTexto(r.disponibleTrasPendientes, estilo: tema.secundario),
              ],
            ),
          ],
          const SizedBox(height: 16),
          BarraProgreso(valor: r.avance, color: colorBarra),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Cifra(etiqueta: 'Ingresos', centavos: r.ingresos, color: tema.positivo)),
              Expanded(child: _Cifra(etiqueta: 'Gastos', centavos: r.gastos, color: tema.negativo)),
              Expanded(child: _Cifra(etiqueta: 'Ahorro', centavos: r.ahorro, color: tema.acento)),
            ],
          ),
          if (r.ingresos == 0) ...[
            const SizedBox(height: 14),
            Text(
              'Aún no registras el sueldo de esta semana. Cuenta el que recibes el domingo anterior.',
              style: tema.secundario,
            ),
          ] else if (r.gastadoConCredito > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Con tarjeta de crédito: ', style: tema.secundario),
                MontoTexto(r.gastadoConCredito, estilo: tema.secundario),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.centavos, required this.color});

  final String etiqueta;
  final int centavos;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(etiqueta, style: tema.secundario),
          ],
        ),
        const SizedBox(height: 4),
        MontoTexto(centavos, estilo: tema.monto.copyWith(fontSize: 15), sinCentavos: true),
      ],
    );
  }
}

class _PanelPendientes extends ConsumerWidget {
  const _PanelPendientes({required this.resumen, required this.cuentas});

  final ResumenSemanal resumen;
  final List<CuentaConSaldo> cuentas;

  Future<void> _registrar(BuildContext context, WidgetRef ref, PagoFijoPendiente p) async {
    var cuentaId = p.gasto.cuentaId;
    if (cuentaId == null || !cuentas.any((c) => c.cuenta.id == cuentaId)) {
      cuentaId = await elegirOpcion<int>(
        context,
        titulo: '¿Con qué cuenta pagaste ${p.gasto.nombre}?',
        opciones: [
          for (final c in cuentas) Opcion(c.cuenta.id!, c.cuenta.nombreCompleto),
        ],
      );
      if (cuentaId == null) return;
    }
    await ref.escribir(
      (repo) => repo.guardarMovimiento(
        Movimiento(
          tipo: TipoMovimiento.egreso,
          monto: p.gasto.monto,
          cuentaId: cuentaId!,
          categoria: p.gasto.categoria,
          descripcion: p.gasto.nombre,
          fecha: p.fecha,
          esFijo: true,
          gastoFijoId: p.gasto.id,
          creadoEn: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Pagos fijos pendientes'),
        PanelVidrio(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final p in resumen.pendientes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      IconoCirculo(icono: categoriaPorId(p.gasto.categoria).icono),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.gasto.nombre, style: tema.cuerpo),
                            const SizedBox(height: 2),
                            Text(capitalizar(fechaMedia(p.fecha)), style: tema.secundario),
                          ],
                        ),
                      ),
                      MontoTexto(p.gasto.monto, estilo: tema.monto.copyWith(fontSize: 15)),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: tema.acento,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => _registrar(context, ref, p),
                        child: Text(
                          'Pagar',
                          style: TextStyle(
                            color: tema.sobreAcento,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelTarjetas extends StatelessWidget {
  const _PanelTarjetas({required this.cuentas});

  final List<CuentaConSaldo> cuentas;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final tarjetas = cuentas.where((c) => c.cuenta.esCredito).toList();
    if (tarjetas.isEmpty) return const SizedBox.shrink();
    final hoy = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Tarjetas de crédito'),
        for (final t in tarjetas) ...[
          _TarjetaResumen(tarjeta: t, hoy: hoy),
          const SizedBox(height: 10),
        ],
        if (tarjetas.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Text('Deuda total: ', style: tema.secundario),
                MontoTexto(
                  tarjetas.fold<int>(0, (s, t) => s + t.deuda),
                  estilo: tema.secundario.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TarjetaResumen extends ConsumerWidget {
  const _TarjetaResumen({required this.tarjeta, required this.hoy});

  final CuentaConSaldo tarjeta;
  final DateTime hoy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuenta = tarjeta.cuenta;
    final colores = coloresCuenta(cuenta.color);
    const blanco = Color(0xFFFFFFFF);
    const blancoSuave = Color(0xCCFFFFFF);
    final ciclo = cicloDe(cuenta);

    return PanelVidrio(
      // Con fechas capturadas, la tarjeta lleva a su corte y pago en el calendario.
      onTap: ciclo == null
          ? null
          : () {
              ref.read(vistaPlanearProvider.notifier).ver(VistaPlanear.calendario);
              ref.read(pestanaProvider.notifier).ir(Pestana.planear);
            },
      gradiente: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colores[0].withValues(alpha: 0.85), colores[1].withValues(alpha: 0.65)],
      ),
      colorBorde: const Color(0x40FFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cuenta.nombreCompleto,
                  style: const TextStyle(color: blanco, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                ciclo == null ? CupertinoIcons.creditcard_fill : CupertinoIcons.calendar,
                color: blancoSuave,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Deuda actual', style: TextStyle(color: blancoSuave, fontSize: 12)),
          MontoTexto(
            tarjeta.deuda,
            estilo: const TextStyle(color: blanco, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ciclo != null) ...[
                Expanded(
                  child: _DatoTarjeta(
                    etiqueta: 'Próximo corte',
                    valor: fechaCorta(ciclo.proximoCorte(hoy)),
                  ),
                ),
                Expanded(
                  child: _DatoTarjeta(
                    etiqueta: 'Pagar antes del',
                    valor: fechaCorta(ciclo.proximaFechaLimite(hoy)),
                  ),
                ),
              ] else
                const Expanded(
                  child: _DatoTarjeta(etiqueta: 'Fechas', valor: 'Captura corte y pago'),
                ),
              if (tarjeta.creditoDisponible != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Disponible', style: TextStyle(color: blancoSuave, fontSize: 12)),
                      MontoTexto(
                        tarjeta.creditoDisponible!,
                        sinCentavos: true,
                        estilo: const TextStyle(color: blanco, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoTarjeta extends StatelessWidget {
  const _DatoTarjeta({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
          Text(
            valor,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      );
}

class _PanelAhorro extends StatelessWidget {
  const _PanelAhorro({required this.cuentas});

  final List<CuentaConSaldo> cuentas;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final ahorros = cuentas.where((c) => c.cuenta.tipo == TipoCuenta.ahorro).toList();
    if (ahorros.isEmpty) return const SizedBox.shrink();
    final total = ahorros.fold<int>(0, (s, c) => s + c.saldo);
    final semanal = ahorros.fold<int>(0, (s, c) => s + c.rendimientoEstimado(7));
    final mensual = ahorros.fold<int>(0, (s, c) => s + c.rendimientoEstimado(30));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Ahorro'),
        PanelVidrio(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL AHORRADO', style: tema.etiqueta),
              const SizedBox(height: 4),
              MontoTexto(total, estilo: tema.titulo.copyWith(fontSize: 26)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Rendimiento(etiqueta: 'Gana por semana', centavos: semanal),
                  ),
                  Expanded(
                    child: _Rendimiento(etiqueta: 'Gana por mes', centavos: mensual),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Estimado con la tasa fija de cada cuenta, antes de impuestos.',
                style: tema.secundario.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rendimiento extends StatelessWidget {
  const _Rendimiento({required this.etiqueta, required this.centavos});

  final String etiqueta;
  final int centavos;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: tema.secundario),
        MontoTexto(centavos, signo: true, colorear: true, estilo: tema.monto),
      ],
    );
  }
}

class _UltimosMovimientos extends ConsumerWidget {
  const _UltimosMovimientos({required this.cuentas});

  final Map<int, Cuenta> cuentas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ultimos = ref.watch(ultimosMovimientosProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Últimos movimientos'),
        ultimos.when(
          skipLoadingOnReload: true,
          loading: () => const Cargando(),
          error: (e, _) => ErrorDatos(e),
          data: (lista) => lista.isEmpty
              ? EstadoVacio(
                  icono: CupertinoIcons.list_bullet,
                  titulo: 'Sin movimientos',
                  mensaje: 'Registra tu sueldo del domingo y tus gastos para ver tu semana.',
                  accion: 'Registrar movimiento',
                  alAccion: () =>
                      abrirPantalla<void>(context, const MovimientoFormPantalla(), modal: true),
                )
              : PanelVidrio(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (final m in lista)
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
        ),
      ],
    );
  }
}
