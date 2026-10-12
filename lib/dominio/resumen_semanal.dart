import '../data/modelos/cuenta.dart';
import '../data/modelos/gasto_fijo.dart';
import '../data/modelos/movimiento.dart';

/// Pago fijo que todavía no se registra en la semana.
class PagoFijoPendiente {
  const PagoFijoPendiente(this.gasto, this.fecha);

  final GastoFijo gasto;
  final DateTime fecha;
}

/// Números de una semana presupuestal (lunes a domingo, financiada por el
/// sueldo del domingo anterior).
class ResumenSemanal {
  const ResumenSemanal({
    required this.lunes,
    required this.ingresos,
    required this.sueldo,
    required this.gastosFijos,
    required this.gastosVariables,
    required this.ahorro,
    required this.gastadoConCredito,
    required this.pendientes,
  });

  final DateTime lunes;
  final int ingresos;

  /// Parte de [ingresos] marcada como sueldo.
  final int sueldo;
  final int gastosFijos;
  final int gastosVariables;

  /// Neto apartado a cuentas de ahorro (puede ser negativo si se retiró).
  final int ahorro;

  /// Parte de los gastos que se pagó con tarjeta de crédito.
  final int gastadoConCredito;
  final List<PagoFijoPendiente> pendientes;

  int get gastos => gastosFijos + gastosVariables;

  /// Lo que queda de los ingresos de la semana.
  int get disponible => ingresos - gastos - ahorro;

  int get totalPendiente => pendientes.fold(0, (s, p) => s + p.gasto.monto);

  /// Disponible si además se pagan los fijos que faltan.
  int get disponibleTrasPendientes => disponible - totalPendiente;

  /// Proporción gastada de los ingresos (0 a 1+).
  double get avance {
    if (ingresos <= 0) return gastos > 0 ? 1.0 : 0.0;
    return (gastos + ahorro) / ingresos;
  }
}

ResumenSemanal calcularResumenSemanal({
  required DateTime lunes,
  required List<Movimiento> movimientos,
  required Map<int, Cuenta> cuentas,
  required List<GastoFijo> gastosFijos,
}) {
  var ingresos = 0;
  var sueldo = 0;
  var fijos = 0;
  var variables = 0;
  var ahorro = 0;
  var conCredito = 0;
  final registrados = <int>{};

  for (final m in movimientos) {
    switch (m.tipo) {
      case TipoMovimiento.ingreso:
        ingresos += m.monto;
        if (m.esSueldo) sueldo += m.monto;
      case TipoMovimiento.egreso:
        if (m.esFijo) {
          fijos += m.monto;
        } else {
          variables += m.monto;
        }
        if (cuentas[m.cuentaId]?.esCredito ?? false) conCredito += m.monto;
      case TipoMovimiento.transferencia:
        final haciaAhorro = cuentas[m.cuentaDestinoId]?.tipo == TipoCuenta.ahorro;
        final desdeAhorro = cuentas[m.cuentaId]?.tipo == TipoCuenta.ahorro;
        if (haciaAhorro && !desdeAhorro) {
          ahorro += m.monto;
        } else if (desdeAhorro && !haciaAhorro) {
          ahorro -= m.monto;
        }
    }
    final idFijo = m.gastoFijoId;
    if (idFijo != null) registrados.add(idFijo);
  }

  final pendientes = <PagoFijoPendiente>[];
  for (final gasto in gastosFijos) {
    final id = gasto.id;
    if (!gasto.activo || id == null || registrados.contains(id)) continue;
    final fecha = gasto.fechaEnSemana(lunes);
    if (fecha != null) pendientes.add(PagoFijoPendiente(gasto, fecha));
  }
  pendientes.sort((a, b) => a.fecha.compareTo(b.fecha));

  return ResumenSemanal(
    lunes: lunes,
    ingresos: ingresos,
    sueldo: sueldo,
    gastosFijos: fijos,
    gastosVariables: variables,
    ahorro: ahorro,
    gastadoConCredito: conCredito,
    pendientes: pendientes,
  );
}
