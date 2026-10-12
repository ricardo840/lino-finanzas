import 'package:flutter_test/flutter_test.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/dominio/ciclo_tarjeta.dart';
import 'package:lino/dominio/simulador_compra.dart';

CuentaConSaldo _credito(int id, String banco, {required int corte, required int pago, int deuda = 0}) =>
    CuentaConSaldo(
      Cuenta(
        id: id,
        nombre: 'Crédito',
        banco: banco,
        tipo: TipoCuenta.credito,
        limiteCredito: 2000000,
        diaCorte: corte,
        diaPago: pago,
        creadaEn: DateTime(2026),
      ),
      -deuda,
    );

CuentaConSaldo _debito(int id, int saldo) => CuentaConSaldo(
      Cuenta(id: id, nombre: 'Débito', banco: 'Nu', tipo: TipoCuenta.debito, creadaEn: DateTime(2026)),
      saldo,
    );

CuentaConSaldo _ahorro(int id, int saldo, double tasa) => CuentaConSaldo(
      Cuenta(
        id: id,
        nombre: 'Cajita',
        banco: 'Nu',
        tipo: TipoCuenta.ahorro,
        tasaAnual: tasa,
        creadaEn: DateTime(2026),
      ),
      saldo,
    );

void main() {
  final viernes = DateTime(2026, 10, 9);

  group('CicloTarjeta', () {
    const ciclo = CicloTarjeta(diaCorte: 10, diaPago: 30);

    test('compra antes del corte entra en el corte de este mes', () {
      expect(ciclo.proximoCorte(viernes), DateTime(2026, 10, 10));
      expect(ciclo.fechaLimitePago(DateTime(2026, 10, 10)), DateTime(2026, 10, 30));
      expect(ciclo.diasParaPagar(viernes), 21);
    });

    test('el día del corte cuenta en ese corte; el siguiente ya no', () {
      expect(ciclo.diasParaPagar(DateTime(2026, 10, 10)), 20);
      expect(ciclo.diasParaPagar(DateTime(2026, 10, 11)), 50);
    });

    test('corte 31 en febrero y pago al mes siguiente', () {
      const c = CicloTarjeta(diaCorte: 31, diaPago: 20);
      expect(c.proximoCorte(DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
      expect(c.fechaLimitePago(DateTime(2026, 2, 28)), DateTime(2026, 3, 20));
      expect(c.proximoCorte(DateTime(2026, 3, 1)), DateTime(2026, 3, 31));
    });

    test('día de pago menor al de corte cae al mes siguiente', () {
      const c = CicloTarjeta(diaCorte: 10, diaPago: 5);
      expect(c.fechaLimitePago(DateTime(2026, 10, 10)), DateTime(2026, 11, 5));
    });

    test('próxima fecha límite pendiente', () {
      // El 12 de oct ya pasó el corte del 10; su pago vence el 30.
      expect(ciclo.proximaFechaLimite(DateTime(2026, 10, 12)), DateTime(2026, 10, 30));
      // El 31 de oct ya venció; toca la del corte de noviembre.
      expect(ciclo.proximaFechaLimite(DateTime(2026, 10, 31)), DateTime(2026, 11, 30));
    });
  });

  group('simularCompra', () {
    test('recomienda la tarjeta con más días para pagar', () {
      final r = simularCompra(
        monto: 150000,
        fecha: viernes,
        disponibleSemana: 300000,
        cuentas: [
          _credito(1, 'Nu', corte: 10, pago: 30, deuda: 100000),
          _credito(2, 'BBVA', corte: 8, pago: 28),
          _debito(3, 500000),
          _ahorro(4, 1000000, 15),
        ],
      );
      expect(r.recomendacion.metodo, MetodoSugerido.credito);
      expect(r.recomendacion.credito!.tarjeta.cuenta.banco, 'BBVA');
      expect(r.recomendacion.credito!.diasParaPagar, 50);
      expect(r.recomendacion.credito!.sueldosAntes, 7);
      expect(r.recomendacion.credito!.rendimiento, 3082);
      expect(r.tasaAhorro, 15);
      expect(r.superaSemana, isFalse);
    });

    test('sugiere esperar al día después del corte si se puede', () {
      final r = simularCompra(
        monto: 150000,
        fecha: viernes,
        diasEspera: 3,
        disponibleSemana: 300000,
        cuentas: [_credito(1, 'Nu', corte: 10, pago: 30), _debito(2, 500000)],
      );
      expect(r.recomendacion.metodo, MetodoSugerido.esperar);
      expect(r.recomendacion.fechaSugerida, DateTime(2026, 10, 11));
      expect(r.recomendacion.credito!.diasParaPagar, 50);
    });

    test('usa débito cuando el corte está demasiado cerca', () {
      final r = simularCompra(
        monto: 150000,
        fecha: viernes,
        disponibleSemana: 300000,
        cuentas: [_credito(1, 'Nu', corte: 10, pago: 15), _debito(2, 500000)],
      );
      expect(r.recomendacion.metodo, MetodoSugerido.debito);
      expect(r.recomendacion.debito!.saldoDespues, 350000);
    });

    test('avisa cuando supera el disponible de la semana', () {
      final r = simularCompra(
        monto: 150000,
        fecha: viernes,
        disponibleSemana: 100000,
        cuentas: [_debito(1, 500000)],
      );
      expect(r.superaSemana, isTrue);
      expect(r.recomendacion.razones.any((t) => t.startsWith('Supera')), isTrue);
    });

    test('sin fondos ni crédito suficiente', () {
      final r = simularCompra(
        monto: 100000000,
        fecha: viernes,
        disponibleSemana: 0,
        cuentas: [_credito(1, 'Nu', corte: 10, pago: 30), _debito(2, 500000)],
      );
      expect(r.recomendacion.metodo, MetodoSugerido.sinFondos);
    });
  });
}
