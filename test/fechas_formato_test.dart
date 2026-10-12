import 'package:flutter_test/flutter_test.dart';
import 'package:lino/core/fechas.dart';
import 'package:lino/core/formato.dart';

void main() {
  group('semana', () {
    test('lunesDe regresa el lunes de la semana lunes-domingo', () {
      expect(lunesDe(DateTime(2026, 10, 9)), DateTime(2026, 10, 5)); // viernes
      expect(lunesDe(DateTime(2026, 10, 5)), DateTime(2026, 10, 5)); // lunes
      expect(lunesDe(DateTime(2026, 10, 11)), DateTime(2026, 10, 5)); // domingo
    });

    test('el sueldo del domingo financia la semana siguiente', () {
      final domingo = DateTime(2026, 10, 11);
      expect(semanaPresupuestal(domingo, esSueldo: true, esFijo: false), DateTime(2026, 10, 12));
      expect(semanaPresupuestal(domingo, esSueldo: false, esFijo: true), DateTime(2026, 10, 12));
      // Un gasto normal en domingo se queda en su semana.
      expect(semanaPresupuestal(domingo, esSueldo: false, esFijo: false), DateTime(2026, 10, 5));
    });

    test('semanaActual en domingo ya es la que empieza mañana', () {
      expect(semanaActual(DateTime(2026, 10, 11, 20)), DateTime(2026, 10, 12));
      expect(semanaActual(DateTime(2026, 10, 9, 8)), DateTime(2026, 10, 5));
    });

    test('domingosEntre cuenta días de sueldo', () {
      expect(domingosEntre(DateTime(2026, 10, 9), DateTime(2026, 10, 30)), 3);
      expect(domingosEntre(DateTime(2026, 10, 11), DateTime(2026, 10, 11)), 0);
    });

    test('fechaEnMes recorta al último día del mes', () {
      expect(fechaEnMes(2026, 2, 31), DateTime(2026, 2, 28));
      expect(fechaEnMes(2026, 13, 5), DateTime(2027, 1, 5));
    });
  });

  group('dinero', () {
    test('formatoDinero', () {
      expect(formatoDinero(0), r'$0.00');
      expect(formatoDinero(123456), r'$1,234.56');
      expect(formatoDinero(-500), r'-$5.00');
      expect(formatoDinero(100000000, conCentavos: false), r'$1,000,000');
      expect(formatoDinero(2500, signoMas: true), r'+$25.00');
    });

    test('parsearDinero', () {
      expect(parsearDinero('1,234.5'), 123450);
      expect(parsearDinero(r'$80'), 8000);
      expect(parsearDinero('0.05'), 5);
      expect(parsearDinero('12.345'), isNull);
      expect(parsearDinero('abc'), isNull);
      expect(parsearDinero(''), isNull);
    });

    test('montoEditable', () {
      expect(montoEditable(123450), '1234.50');
      expect(montoEditable(8000), '80');
    });
  });

  test('rangoSemana', () {
    expect(rangoSemana(DateTime(2026, 10, 5)), '5 – 11 oct');
    expect(rangoSemana(DateTime(2026, 9, 28)), '28 sep – 4 oct');
  });
}
