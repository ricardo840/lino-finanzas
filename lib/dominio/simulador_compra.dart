import 'dart:math';

import '../core/fechas.dart';
import '../core/formato.dart';
import '../data/modelos/cuenta.dart';
import 'ciclo_tarjeta.dart';

/// Con menos días que estos para pagar, no conviene usar crédito.
const int diasMinimosCredito = 10;

/// Días extra de financiamiento que justifican esperar para comprar.
const int gananciaMinimaEspera = 7;

/// Si hoy ya se tienen estos días para pagar, no vale la pena esperar.
const int diasSuficientes = 30;

enum MetodoSugerido { credito, debito, esperar, sinFondos }

/// Cómo quedaría la compra con una tarjeta de crédito en cierta fecha.
class OpcionCredito {
  const OpcionCredito({
    required this.tarjeta,
    required this.fechaCompra,
    required this.corte,
    required this.limitePago,
    required this.diasParaPagar,
    required this.alcanza,
    required this.sueldosAntes,
    required this.rendimiento,
  });

  final CuentaConSaldo tarjeta;
  final DateTime fechaCompra;
  final DateTime corte;
  final DateTime limitePago;
  final int diasParaPagar;

  /// Hay crédito disponible suficiente.
  final bool alcanza;

  /// Domingos de sueldo entre la compra y la fecha límite.
  final int sueldosAntes;

  /// Lo que el dinero gana en ahorro mientras llega la fecha límite.
  final int rendimiento;
}

/// Cómo quedaría la compra pagando con débito o efectivo.
class OpcionDebito {
  const OpcionDebito({required this.cuenta, required this.alcanza, required this.saldoDespues});

  final CuentaConSaldo cuenta;
  final bool alcanza;
  final int saldoDespues;
}

class Recomendacion {
  const Recomendacion({
    required this.metodo,
    required this.titulo,
    required this.razones,
    this.credito,
    this.debito,
    this.fechaSugerida,
    this.apartarPorSueldo,
  });

  final MetodoSugerido metodo;
  final String titulo;
  final List<String> razones;
  final OpcionCredito? credito;
  final OpcionDebito? debito;

  /// Fecha recomendada para comprar (cuando conviene esperar).
  final DateTime? fechaSugerida;

  /// Cuánto apartar de cada sueldo para llegar a la fecha límite.
  final int? apartarPorSueldo;
}

class ResultadoSimulacion {
  const ResultadoSimulacion({
    required this.monto,
    required this.recomendacion,
    required this.opcionesCredito,
    required this.opcionesDebito,
    required this.disponibleSemana,
    required this.tasaAhorro,
  });

  final int monto;
  final Recomendacion recomendacion;

  /// Tarjetas evaluadas en la fecha de compra, de más a menos días.
  final List<OpcionCredito> opcionesCredito;
  final List<OpcionDebito> opcionesDebito;
  final int disponibleSemana;

  /// Mejor tasa anual de tus cuentas de ahorro (0 si no hay).
  final double tasaAhorro;

  bool get superaSemana => monto > disponibleSemana;
}

/// Decide cuándo y con qué conviene hacer una compra.
///
/// Supuestos (vienen de la planeación): siempre se paga el total de la tarjeta
/// y no se usan meses sin intereses, así que el crédito no cuesta; su ventaja
/// son los días de financiamiento y lo que el dinero gana mientras tanto en el
/// ahorro.
ResultadoSimulacion simularCompra({
  required int monto,
  required DateTime fecha,
  required List<CuentaConSaldo> cuentas,
  required int disponibleSemana,
  int diasEspera = 0,
}) {
  final fechaCompra = soloFecha(fecha);

  final tasa = cuentas
      .where((c) => c.cuenta.tipo == TipoCuenta.ahorro)
      .map((c) => c.cuenta.tasaAnual ?? 0.0)
      .fold<double>(0, max);

  final tarjetas = cuentas
      .where((c) => c.cuenta.esCredito && c.cuenta.diaCorte != null && c.cuenta.diaPago != null)
      .toList();

  OpcionCredito evaluar(CuentaConSaldo tarjeta, DateTime dia) {
    final ciclo = CicloTarjeta(diaCorte: tarjeta.cuenta.diaCorte!, diaPago: tarjeta.cuenta.diaPago!);
    final corte = ciclo.proximoCorte(dia);
    final limite = ciclo.fechaLimitePago(corte);
    final dias = diasEntre(dia, limite);
    final disponible = tarjeta.creditoDisponible;
    return OpcionCredito(
      tarjeta: tarjeta,
      fechaCompra: dia,
      corte: corte,
      limitePago: limite,
      diasParaPagar: dias,
      alcanza: disponible == null || disponible >= monto,
      sueldosAntes: domingosEntre(dia, limite),
      rendimiento: (monto * tasa / 100 * dias / 365).round(),
    );
  }

  final opcionesHoy = [for (final t in tarjetas) evaluar(t, fechaCompra)]
    ..sort((a, b) => b.diasParaPagar.compareTo(a.diasParaPagar));
  OpcionCredito? mejorHoy;
  for (final o in opcionesHoy) {
    if (o.alcanza) {
      mejorHoy = o;
      break;
    }
  }

  OpcionCredito? mejorEsperando;
  for (var d = 1; d <= diasEspera; d++) {
    final dia = sumarDias(fechaCompra, d);
    for (final t in tarjetas) {
      final o = evaluar(t, dia);
      if (!o.alcanza) continue;
      if (mejorEsperando == null || o.diasParaPagar > mejorEsperando.diasParaPagar) {
        mejorEsperando = o;
      }
    }
  }

  final debitos = [
    for (final c in cuentas)
      if (c.cuenta.esLiquida)
        OpcionDebito(cuenta: c, alcanza: c.saldo >= monto, saldoDespues: c.saldo - monto),
  ]..sort((a, b) => b.cuenta.saldo.compareTo(a.cuenta.saldo));
  OpcionDebito? mejorDebito;
  for (final d in debitos) {
    if (d.alcanza) {
      mejorDebito = d;
      break;
    }
  }

  final razones = <String>[];
  final Recomendacion recomendacion;
  final diasHoy = mejorHoy?.diasParaPagar ?? 0;

  if (mejorEsperando != null &&
      mejorEsperando.diasParaPagar - diasHoy >= gananciaMinimaEspera &&
      diasHoy < diasSuficientes) {
    final o = mejorEsperando;
    final nombre = o.tarjeta.cuenta.nombreCompleto;
    razones
      ..add('Ese día ya habrá pasado el corte de $nombre: tendrás ${o.diasParaPagar} días '
          'para pagar en lugar de $diasHoy.')
      ..add('Fecha límite de pago: ${fechaMedia(o.limitePago)}. '
          'Recibirás ${plural(o.sueldosAntes, 'sueldo', 'sueldos')} antes.');
    if (tasa > 0 && o.rendimiento > 0) {
      razones.add('Mientras tanto tu dinero sigue en ahorro y genera cerca de '
          '${formatoDinero(o.rendimiento)} al ${porcentaje(tasa)} anual.');
    }
    recomendacion = Recomendacion(
      metodo: MetodoSugerido.esperar,
      titulo: 'Espera al ${fechaMedia(o.fechaCompra)} y usa $nombre',
      razones: razones,
      credito: o,
      fechaSugerida: o.fechaCompra,
      apartarPorSueldo: _apartarPorSueldo(monto, o.sueldosAntes),
    );
  } else if (mejorHoy != null &&
      mejorHoy.diasParaPagar >= diasMinimosCredito &&
      mejorHoy.sueldosAntes >= 1) {
    final o = mejorHoy;
    final nombre = o.tarjeta.cuenta.nombreCompleto;
    razones
      ..add('Tendrás ${o.diasParaPagar} días para pagarla; la fecha límite es el '
          '${fechaMedia(o.limitePago)}.')
      ..add('Recibirás ${plural(o.sueldosAntes, 'sueldo', 'sueldos')} antes de esa fecha.')
      ..add('Como pagas el total de la tarjeta, no generas intereses.');
    if (tasa > 0 && o.rendimiento > 0) {
      razones.add('Mientras tanto tu dinero sigue en ahorro y genera cerca de '
          '${formatoDinero(o.rendimiento)} al ${porcentaje(tasa)} anual.');
    }
    recomendacion = Recomendacion(
      metodo: MetodoSugerido.credito,
      titulo: 'Paga con $nombre',
      razones: razones,
      credito: o,
      apartarPorSueldo: _apartarPorSueldo(monto, o.sueldosAntes),
    );
  } else if (mejorDebito != null) {
    final d = mejorDebito;
    if (mejorHoy != null) {
      razones.add('Con ${mejorHoy.tarjeta.cuenta.nombreCompleto} solo tendrías '
          '${mejorHoy.diasParaPagar} días para pagar (corte el ${fechaCorta(mejorHoy.corte)}).');
    } else if (tarjetas.isEmpty) {
      razones.add('No tienes tarjetas de crédito con fecha de corte y de pago capturadas.');
    } else {
      razones.add('Ninguna tarjeta tiene crédito disponible suficiente.');
    }
    razones.add('El saldo de ${d.cuenta.cuenta.nombreCompleto} quedaría en '
        '${formatoDinero(d.saldoDespues)}.');
    recomendacion = Recomendacion(
      metodo: MetodoSugerido.debito,
      titulo: 'Paga con ${d.cuenta.cuenta.nombreCompleto}',
      razones: razones,
      debito: d,
    );
  } else if (mejorHoy != null) {
    final o = mejorHoy;
    razones
      ..add('Ninguna cuenta de débito o efectivo tiene saldo suficiente.')
      ..add('La fecha límite de pago sería el ${fechaMedia(o.limitePago)}; '
          'aparta el dinero antes.');
    recomendacion = Recomendacion(
      metodo: MetodoSugerido.credito,
      titulo: 'Solo alcanza con ${o.tarjeta.cuenta.nombreCompleto}',
      razones: razones,
      credito: o,
      apartarPorSueldo: _apartarPorSueldo(monto, o.sueldosAntes),
    );
  } else {
    razones.add('Ni tus cuentas ni tus tarjetas tienen saldo o crédito suficiente '
        'para ${formatoDinero(monto)}.');
    recomendacion = Recomendacion(
      metodo: MetodoSugerido.sinFondos,
      titulo: 'Por ahora no te alcanza',
      razones: razones,
    );
  }

  if (monto > disponibleSemana) {
    final faltante = monto - max<int>(disponibleSemana, 0);
    razones.add('Supera tu disponible de la semana '
        '(${formatoDinero(disponibleSemana)}) por ${formatoDinero(faltante)}.');
  }
  final apartar = recomendacion.apartarPorSueldo;
  if (apartar != null) {
    razones.add('Aparta ${formatoDinero(apartar)} de cada sueldo hasta la fecha límite.');
  }

  return ResultadoSimulacion(
    monto: monto,
    recomendacion: recomendacion,
    opcionesCredito: opcionesHoy,
    opcionesDebito: debitos,
    disponibleSemana: disponibleSemana,
    tasaAhorro: tasa,
  );
}

int? _apartarPorSueldo(int monto, int sueldos) =>
    sueldos <= 0 ? null : (monto / sueldos).ceil();
