import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formato.dart';
import '../../../data/modelos/cuenta.dart';
import '../../../estado/datos.dart';
import '../../categorias.dart';
import '../../tema/contexto.dart';
import '../../tema/temas.dart';
import '../../widgets/comunes.dart';
import '../../widgets/monto_texto.dart';
import '../../widgets/paginas.dart';
import '../../widgets/vidrio.dart';
import 'cuenta_form_pantalla.dart';

class CuentasPantalla extends ConsumerWidget {
  const CuentasPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(cuentasProvider);
    return PaginaPestana(
      titulo: 'Cuentas',
      derecha: BotonIcono(
        icono: CupertinoIcons.plus_circle_fill,
        tamano: 28,
        onPressed: () => abrirPantalla<void>(context, const CuentaFormPantalla(), modal: true),
      ),
      hijos: cuentas.when(
          skipLoadingOnReload: true,
        loading: () => const [Cargando()],
        error: (e, _) => [ErrorDatos(e)],
        data: (lista) {
          if (lista.isEmpty) {
            return [
              EstadoVacio(
                icono: CupertinoIcons.creditcard,
                titulo: 'Sin cuentas',
                mensaje: 'Agrega tus 6 bancos: débito, crédito, efectivo y ahorro.',
                accion: 'Agregar cuenta',
                alAccion: () =>
                    abrirPantalla<void>(context, const CuentaFormPantalla(), modal: true),
              ),
            ];
          }
          return [
            _Totales(cuentas: lista),
            for (final tipo in TipoCuenta.values)
              if (lista.any((c) => c.cuenta.tipo == tipo)) ...[
                TituloSeccion(_tituloGrupo(tipo)),
                for (final c in lista.where((c) => c.cuenta.tipo == tipo)) ...[
                  _TarjetaCuenta(cuenta: c),
                  const SizedBox(height: 10),
                ],
              ],
          ];
        },
      ),
    );
  }

  static String _tituloGrupo(TipoCuenta tipo) => switch (tipo) {
        TipoCuenta.debito => 'Débito',
        TipoCuenta.credito => 'Tarjetas de crédito',
        TipoCuenta.efectivo => 'Efectivo',
        TipoCuenta.ahorro => 'Ahorro',
      };
}

class _Totales extends StatelessWidget {
  const _Totales({required this.cuentas});

  final List<CuentaConSaldo> cuentas;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final liquido = cuentas
        .where((c) => c.cuenta.esLiquida)
        .fold<int>(0, (s, c) => s + c.saldo);
    final ahorro = cuentas
        .where((c) => c.cuenta.tipo == TipoCuenta.ahorro)
        .fold<int>(0, (s, c) => s + c.saldo);
    final deuda = cuentas.fold<int>(0, (s, c) => s + c.deuda);
    final neto = cuentas.fold<int>(0, (s, c) => s + c.saldo);
    return PanelVidrio(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PATRIMONIO NETO', style: tema.etiqueta),
          const SizedBox(height: 4),
          MontoTexto(neto, estilo: tema.montoGrande.copyWith(fontSize: 32), color: neto < 0 ? tema.negativo : null),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Total(etiqueta: 'Disponible', centavos: liquido)),
              Expanded(child: _Total(etiqueta: 'Ahorro', centavos: ahorro)),
              Expanded(child: _Total(etiqueta: 'Deuda', centavos: deuda, color: deuda > 0 ? tema.negativo : null)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.etiqueta, required this.centavos, this.color});

  final String etiqueta;
  final int centavos;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: tema.secundario),
        const SizedBox(height: 2),
        MontoTexto(centavos, sinCentavos: true, color: color, estilo: tema.monto.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _TarjetaCuenta extends StatelessWidget {
  const _TarjetaCuenta({required this.cuenta});

  final CuentaConSaldo cuenta;

  @override
  Widget build(BuildContext context) {
    final tema = context.tema;
    final c = cuenta.cuenta;
    final colores = coloresCuenta(c.color);

    final String detalle;
    switch (c.tipo) {
      case TipoCuenta.credito:
        final partes = <String>[
          if (c.diaCorte != null) 'Corte día ${c.diaCorte}',
          if (c.diaPago != null) 'pago día ${c.diaPago}',
        ];
        detalle = partes.isEmpty ? 'Sin fechas de corte y pago' : partes.join(' · ');
      case TipoCuenta.ahorro:
        detalle = c.tasaAnual == null ? 'Sin tasa capturada' : 'Tasa fija ${porcentaje(c.tasaAnual!)} anual';
      case TipoCuenta.debito:
      case TipoCuenta.efectivo:
        detalle = c.tipo.etiqueta;
    }

    return PanelVidrio(
      onTap: () => abrirPantalla<void>(context, CuentaFormPantalla(existente: cuenta), modal: true),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colores,
              ),
            ),
            child: Icon(iconoTipoCuenta(c.tipo), color: const Color(0xFFFFFFFF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nombreCompleto, style: tema.cuerpo.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detalle, style: tema.secundario),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (c.esCredito) ...[
                MontoTexto(cuenta.deuda, estilo: tema.monto, color: cuenta.deuda > 0 ? tema.negativo : null),
                if (cuenta.creditoDisponible != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Disp. ', style: tema.secundario),
                      MontoTexto(cuenta.creditoDisponible!, sinCentavos: true, estilo: tema.secundario),
                    ],
                  ),
              ] else ...[
                MontoTexto(cuenta.saldo, estilo: tema.monto, color: cuenta.saldo < 0 ? tema.negativo : null),
                if (c.tipo == TipoCuenta.ahorro && cuenta.rendimientoEstimado(30) > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MontoTexto(
                        cuenta.rendimientoEstimado(30),
                        signo: true,
                        estilo: tema.secundario.copyWith(color: tema.positivo),
                      ),
                      Text(' / mes', style: tema.secundario),
                    ],
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
