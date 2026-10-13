import 'package:flutter_test/flutter_test.dart';
import 'package:lino/data/modelos/compra_planeada.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/data/modelos/gasto_fijo.dart';
import 'package:lino/dominio/calendario.dart';

CuentaConSaldo _nu({int deuda = 0}) => CuentaConSaldo(
      Cuenta(
        id: 1,
        nombre: 'Compras',
        banco: 'Nu',
        tipo: TipoCuenta.credito,
        diaCorte: 16,
        diaPago: 26,
        creadaEn: DateTime(2026),
      ),
      -deuda,
    );

CuentaConSaldo _plata() => CuentaConSaldo(
      Cuenta(
        id: 2,
        nombre: 'Plata',
        tipo: TipoCuenta.credito,
        periodoDias: 30,
        ultimoCorte: DateTime(2026, 10, 16),
        plazoPagoDias: 30,
        creadaEn: DateTime(2026),
      ),
      0,
    );

List<int> _dias(List<EventoCalendario> eventos, TipoEvento tipo) =>
    [for (final e in eventos) if (e.tipo == tipo) e.fecha.day];

void main() {
  group('diasDeCuadricula', () {
    test('octubre de 2026 empieza en lunes 28 de septiembre y son 5 semanas', () {
      final dias = diasDeCuadricula(2026, 10);
      expect(dias.first, DateTime(2026, 9, 28));
      expect(dias.last, DateTime(2026, 11, 1));
      expect(dias.length, 35);
    });

    test('siempre son semanas completas de lunes a domingo', () {
      for (var mes = 1; mes <= 12; mes++) {
        final dias = diasDeCuadricula(2026, mes);
        expect(dias.length % 7, 0);
        expect(dias.first.weekday, DateTime.monday);
        expect(dias.last.weekday, DateTime.sunday);
      }
    });
  });

  group('eventosDelMes', () {
    test('marca los domingos de sueldo', () {
      final eventos = eventosDelMes(anio: 2026, mes: 10, cuentas: const [], gastosFijos: const []);
      expect(_dias(eventos, TipoEvento.sueldo), [4, 11, 18, 25]);
      expect(eventos.first.monto, isNull);

      final conSueldo = eventosDelMes(
        anio: 2026,
        mes: 10,
        cuentas: const [],
        gastosFijos: const [],
        sueldoHabitual: 180000,
      );
      expect(conSueldo.first.monto, 180000);
    });

    test('marca el corte y la fecha límite de una tarjeta por día del mes', () {
      final eventos = eventosDelMes(anio: 2026, mes: 10, cuentas: [_nu()], gastosFijos: const []);
      expect(_dias(eventos, TipoEvento.corte), [16]);
      expect(_dias(eventos, TipoEvento.limitePago), [26]);
      expect(eventos.firstWhere((e) => e.tipo == TipoEvento.corte).titulo, 'Corte de Nu · Compras');
    });

    test('el próximo pago lleva la deuda actual', () {
      final eventos = eventosDelMes(
        anio: 2026,
        mes: 10,
        cuentas: [_nu(deuda: 100000)],
        gastosFijos: const [],
        hoy: DateTime(2026, 10, 12),
      );
      // El 12 de oct la próxima fecha límite es el 26 (del corte de septiembre).
      expect(eventos.firstWhere((e) => e.tipo == TipoEvento.limitePago).monto, 100000);

      final noviembre = eventosDelMes(
        anio: 2026,
        mes: 11,
        cuentas: [_nu(deuda: 100000)],
        gastosFijos: const [],
        hoy: DateTime(2026, 10, 12),
      );
      expect(noviembre.firstWhere((e) => e.tipo == TipoEvento.limitePago).monto, isNull);
    });

    test('una tarjeta por días (Plata) recorre sus cortes y pagos', () {
      final octubre = eventosDelMes(anio: 2026, mes: 10, cuentas: [_plata()], gastosFijos: const []);
      expect(_dias(octubre, TipoEvento.corte), [16]);
      // El pago del corte del 16 de septiembre vence 30 días después.
      expect(_dias(octubre, TipoEvento.limitePago), [16]);

      final noviembre = eventosDelMes(anio: 2026, mes: 11, cuentas: [_plata()], gastosFijos: const []);
      expect(_dias(noviembre, TipoEvento.corte), [15]);
      expect(_dias(noviembre, TipoEvento.limitePago), [15]);
    });

    test('marca los gastos fijos semanales, mensuales y omite los pausados', () {
      const fijos = [
        GastoFijo(id: 1, nombre: 'Transporte', monto: 20000),
        GastoFijo(id: 2, nombre: 'Telmex', monto: 40000, frecuencia: FrecuenciaFijo.mensual, diaMes: 7),
        GastoFijo(id: 3, nombre: 'Renta', monto: 300000, frecuencia: FrecuenciaFijo.mensual, diaMes: 31),
        GastoFijo(id: 4, nombre: 'Gimnasio', monto: 50000, activo: false),
      ];
      final eventos = eventosDelMes(anio: 2026, mes: 11, cuentas: const [], gastosFijos: fijos);
      final fijosDelMes = eventos.where((e) => e.tipo == TipoEvento.gastoFijo).toList();
      expect(
        [for (final e in fijosDelMes) if (e.titulo == 'Transporte') e.fecha.day],
        [1, 8, 15, 22, 29],
      );
      expect(fijosDelMes.firstWhere((e) => e.titulo == 'Telmex').fecha, DateTime(2026, 11, 7));
      // Noviembre tiene 30 días: el día 31 se recorre al último.
      expect(fijosDelMes.firstWhere((e) => e.titulo == 'Renta').fecha, DateTime(2026, 11, 30));
      expect(fijosDelMes.any((e) => e.titulo == 'Gimnasio'), isFalse);
    });

    test('marca las compras planeadas en su día', () {
      final compras = [
        CompraPlaneada(id: 1, descripcion: 'Audífonos', monto: 150000, fecha: DateTime(2026, 10, 17), creadaEn: DateTime(2026)),
        CompraPlaneada(id: 2, monto: 90000, fecha: DateTime(2026, 11, 2), creadaEn: DateTime(2026)),
      ];
      final eventos = eventosDelMes(
        anio: 2026,
        mes: 10,
        cuentas: const [],
        gastosFijos: const [],
        compras: compras,
      );
      final planeadas = eventos.where((e) => e.tipo == TipoEvento.compraPlaneada).toList();
      expect(planeadas.length, 1);
      expect(planeadas.single.titulo, 'Audífonos');
      expect(planeadas.single.fecha, DateTime(2026, 10, 17));
      expect(planeadas.single.monto, 150000);
      expect(planeadas.single.compra!.id, 1);
      // Sin descripción se muestra con un nombre genérico.
      expect(compras[1].titulo, 'Compra planeada');
      expect(CompraPlaneada.desdeMapa(compras[0].aMapa()).fecha, DateTime(2026, 10, 17));
    });

    test('los eventos salen ordenados por fecha', () {
      final eventos = eventosDelMes(
        anio: 2026,
        mes: 10,
        cuentas: [_nu(), _plata()],
        gastosFijos: const [GastoFijo(id: 1, nombre: 'Transporte', monto: 20000)],
      );
      for (var i = 1; i < eventos.length; i++) {
        expect(eventos[i].fecha.isBefore(eventos[i - 1].fecha), isFalse);
      }
    });
  });
}
