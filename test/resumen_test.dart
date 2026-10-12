import 'package:flutter_test/flutter_test.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/data/modelos/gasto_fijo.dart';
import 'package:lino/data/modelos/movimiento.dart';
import 'package:lino/dominio/resumen_semanal.dart';

Movimiento _mov(
  TipoMovimiento tipo,
  int monto,
  DateTime fecha, {
  int cuenta = 1,
  int? destino,
  bool sueldo = false,
  bool fijo = false,
  int? gastoFijoId,
}) =>
    Movimiento(
      tipo: tipo,
      monto: monto,
      cuentaId: cuenta,
      cuentaDestinoId: destino,
      categoria: 'otros',
      fecha: fecha,
      esSueldo: sueldo,
      esFijo: fijo,
      gastoFijoId: gastoFijoId,
      creadoEn: fecha,
    );

void main() {
  final lunes = DateTime(2026, 10, 5);
  final cuentas = {
    1: Cuenta(id: 1, nombre: 'Débito', tipo: TipoCuenta.debito, creadaEn: DateTime(2026)),
    2: Cuenta(id: 2, nombre: 'Crédito', tipo: TipoCuenta.credito, creadaEn: DateTime(2026)),
    3: Cuenta(id: 3, nombre: 'Cajita', tipo: TipoCuenta.ahorro, creadaEn: DateTime(2026)),
  };

  test('calcula ingresos, gastos, ahorro y disponible de la semana', () {
    final r = calcularResumenSemanal(
      lunes: lunes,
      cuentas: cuentas,
      gastosFijos: const [],
      movimientos: [
        _mov(TipoMovimiento.ingreso, 400000, DateTime(2026, 10, 4), sueldo: true),
        _mov(TipoMovimiento.egreso, 50000, DateTime(2026, 10, 4), fijo: true),
        _mov(TipoMovimiento.egreso, 30000, DateTime(2026, 10, 6)),
        _mov(TipoMovimiento.egreso, 20000, DateTime(2026, 10, 7), cuenta: 2),
        _mov(TipoMovimiento.transferencia, 100000, DateTime(2026, 10, 8), destino: 3),
      ],
    );
    expect(r.ingresos, 400000);
    expect(r.sueldo, 400000);
    expect(r.gastosFijos, 50000);
    expect(r.gastosVariables, 50000);
    expect(r.gastadoConCredito, 20000);
    expect(r.ahorro, 100000);
    expect(r.disponible, 200000);
  });

  test('marca como pendientes los fijos que faltan', () {
    const internet = GastoFijo(id: 7, nombre: 'Internet', monto: 15000);
    const renta = GastoFijo(
      id: 8,
      nombre: 'Renta',
      monto: 300000,
      frecuencia: FrecuenciaFijo.mensual,
      diaMes: 7,
    );
    const gym = GastoFijo(
      id: 9,
      nombre: 'Gimnasio',
      monto: 50000,
      frecuencia: FrecuenciaFijo.mensual,
      diaMes: 20,
    );
    final r = calcularResumenSemanal(
      lunes: lunes,
      cuentas: cuentas,
      gastosFijos: const [internet, renta, gym],
      movimientos: const [],
    );
    expect(r.pendientes.map((p) => p.gasto.id).toList(), [7, 8]);
    expect(r.pendientes.first.fecha, DateTime(2026, 10, 4));
    expect(r.totalPendiente, 315000);

    final pagado = calcularResumenSemanal(
      lunes: lunes,
      cuentas: cuentas,
      gastosFijos: const [internet],
      movimientos: [
        _mov(TipoMovimiento.egreso, 15000, DateTime(2026, 10, 4), fijo: true, gastoFijoId: 7),
      ],
    );
    expect(pagado.pendientes, isEmpty);
  });
}
