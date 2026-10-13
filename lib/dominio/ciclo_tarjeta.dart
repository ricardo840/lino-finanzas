import '../core/fechas.dart';
import '../data/modelos/cuenta.dart';

/// Fechas de corte y de pago de una tarjeta de crédito.
///
/// Hay dos formas de ciclo:
/// - Por día del mes: el corte cae el mismo día cada mes ([diaCorte]) y la
///   fecha límite es un día fijo ([diaPago]) o llega [plazoPagoDias] días
///   después del corte.
/// - Por días ([CicloTarjeta.porDias]): cada periodo dura [periodoDias] a
///   partir de un corte conocido ([ultimoCorte]) y se paga [plazoPagoDias]
///   días después. Es el caso de la tarjeta Plata (30 y 30).
///
/// En ambas, una compra hecha el mismo día del corte entra en ese corte.
class CicloTarjeta {
  const CicloTarjeta({required int this.diaCorte, this.diaPago, this.plazoPagoDias})
      : assert(diaPago != null || plazoPagoDias != null),
        periodoDias = null,
        ultimoCorte = null;

  const CicloTarjeta.porDias({
    required DateTime this.ultimoCorte,
    required int this.periodoDias,
    required int this.plazoPagoDias,
  })  : assert(periodoDias > 0),
        diaCorte = null,
        diaPago = null;

  final int? diaCorte;
  final int? diaPago;
  final int? plazoPagoDias;
  final int? periodoDias;
  final DateTime? ultimoCorte;

  bool get esPorDias => periodoDias != null;

  /// "Corte día 16 · pago día 26", "Corte cada 30 días · 30 para pagar"...
  String get descripcion {
    if (esPorDias) return 'Corte cada $periodoDias días · $plazoPagoDias para pagar';
    if (plazoPagoDias != null) return 'Corte día $diaCorte · $plazoPagoDias días para pagar';
    return 'Corte día $diaCorte · pago día $diaPago';
  }

  /// Corte en el que entrará una compra hecha en [fecha].
  DateTime proximoCorte(DateTime fecha) {
    final f = soloFecha(fecha);
    final periodo = periodoDias;
    if (periodo != null) {
      final base = soloFecha(ultimoCorte!);
      final dias = diasEntre(base, f);
      // Periodos completos hasta el primer corte que no queda antes de la fecha.
      final periodos = dias >= 0 ? (dias + periodo - 1) ~/ periodo : -((-dias) ~/ periodo);
      return sumarDias(base, periodos * periodo);
    }
    final esteMes = fechaEnMes(f.year, f.month, diaCorte!);
    return f.isAfter(esteMes) ? fechaEnMes(f.year, f.month + 1, diaCorte!) : esteMes;
  }

  /// Último corte que ya ocurrió (o que ocurre hoy).
  DateTime corteAnterior(DateTime fecha) {
    final f = soloFecha(fecha);
    final periodo = periodoDias;
    if (periodo != null) {
      final base = soloFecha(ultimoCorte!);
      final dias = diasEntre(base, f);
      final periodos = dias >= 0 ? dias ~/ periodo : -((-dias + periodo - 1) ~/ periodo);
      return sumarDias(base, periodos * periodo);
    }
    final esteMes = fechaEnMes(f.year, f.month, diaCorte!);
    return f.isBefore(esteMes) ? fechaEnMes(f.year, f.month - 1, diaCorte!) : esteMes;
  }

  /// Fecha límite para pagar lo acumulado hasta [corte].
  DateTime fechaLimitePago(DateTime corte) {
    final plazo = plazoPagoDias;
    if (plazo != null) return sumarDias(corte, plazo);
    final candidata = fechaEnMes(corte.year, corte.month, diaPago!);
    return candidata.isAfter(corte)
        ? candidata
        : fechaEnMes(corte.year, corte.month + 1, diaPago!);
  }

  /// Días que pasan entre la compra y su fecha límite de pago.
  int diasParaPagar(DateTime compra) =>
      diasEntre(compra, fechaLimitePago(proximoCorte(compra)));

  /// Próxima fecha límite de pago que todavía no pasa.
  DateTime proximaFechaLimite(DateTime hoy) {
    final h = soloFecha(hoy);
    final limiteAnterior = fechaLimitePago(corteAnterior(h));
    if (!limiteAnterior.isBefore(h)) return limiteAnterior;
    return fechaLimitePago(proximoCorte(h));
  }
}

/// Ciclo de una tarjeta según lo capturado en la cuenta, o null si no es de
/// crédito o le faltan fechas.
CicloTarjeta? cicloDe(Cuenta cuenta) {
  if (!cuenta.esCredito) return null;
  final periodo = cuenta.periodoDias;
  final ultimo = cuenta.ultimoCorte;
  final plazo = cuenta.plazoPagoDias;
  if (periodo != null && periodo > 0 && ultimo != null && plazo != null) {
    return CicloTarjeta.porDias(ultimoCorte: ultimo, periodoDias: periodo, plazoPagoDias: plazo);
  }
  final corte = cuenta.diaCorte;
  if (corte == null || (cuenta.diaPago == null && plazo == null)) return null;
  return CicloTarjeta(diaCorte: corte, diaPago: cuenta.diaPago, plazoPagoDias: plazo);
}
