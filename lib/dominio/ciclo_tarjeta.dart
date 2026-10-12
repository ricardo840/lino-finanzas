import '../core/fechas.dart';

/// Fechas de corte y de pago de una tarjeta de crédito.
///
/// Regla usada: una compra hecha el mismo día del corte entra en ese corte.
/// La fecha límite de pago es el siguiente [diaPago] después del corte.
class CicloTarjeta {
  const CicloTarjeta({required this.diaCorte, required this.diaPago});

  final int diaCorte;
  final int diaPago;

  /// Corte en el que entrará una compra hecha en [fecha].
  DateTime proximoCorte(DateTime fecha) {
    final f = soloFecha(fecha);
    final esteMes = fechaEnMes(f.year, f.month, diaCorte);
    return f.isAfter(esteMes) ? fechaEnMes(f.year, f.month + 1, diaCorte) : esteMes;
  }

  /// Último corte que ya ocurrió (o que ocurre hoy).
  DateTime corteAnterior(DateTime fecha) {
    final f = soloFecha(fecha);
    final esteMes = fechaEnMes(f.year, f.month, diaCorte);
    return f.isBefore(esteMes) ? fechaEnMes(f.year, f.month - 1, diaCorte) : esteMes;
  }

  /// Fecha límite para pagar lo acumulado hasta [corte].
  DateTime fechaLimitePago(DateTime corte) {
    final candidata = fechaEnMes(corte.year, corte.month, diaPago);
    return candidata.isAfter(corte)
        ? candidata
        : fechaEnMes(corte.year, corte.month + 1, diaPago);
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
