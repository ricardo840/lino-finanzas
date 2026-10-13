import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/ui/tema/temas.dart';

void main() {
  test('la cuenta conserva el ciclo por días al guardarse y leerse', () {
    final original = Cuenta(
      id: 3,
      nombre: 'Plata',
      banco: 'Plata',
      tipo: TipoCuenta.credito,
      limiteCredito: 1500000,
      periodoDias: 30,
      ultimoCorte: DateTime(2026, 10, 16),
      plazoPagoDias: 30,
      color: 9,
      creadaEn: DateTime(2026, 10, 12),
    );
    final leida = Cuenta.desdeMapa(original.aMapa());
    expect(leida.periodoDias, 30);
    expect(leida.ultimoCorte, DateTime(2026, 10, 16));
    expect(leida.plazoPagoDias, 30);
    expect(leida.diaCorte, isNull);
    expect(leida.diaPago, isNull);
  });

  test('una cuenta guardada antes del ciclo por días se lee igual', () {
    // Fila como la devuelve la base en una cuenta de la versión 1.
    final leida = Cuenta.desdeMapa({
      'id': 1,
      'nombre': 'Compras',
      'banco': 'Nu',
      'tipo': 'credito',
      'saldo_inicial': 0,
      'dia_corte': 16,
      'dia_pago': 26,
      'periodo_dias': null,
      'ultimo_corte': null,
      'plazo_pago_dias': null,
      'color': 0,
      'archivada': 0,
      'creada_en': '2026-10-12T00:00:00.000',
    });
    expect(leida.diaCorte, 16);
    expect(leida.diaPago, 26);
    expect(leida.periodoDias, isNull);
    expect(leida.ultimoCorte, isNull);
  });

  test('pareceCuentaDeAhorro reconoce nombres de dinero apartado', () {
    expect(pareceCuentaDeAhorro('Ahorro'), isTrue);
    expect(pareceCuentaDeAhorro('mis ahorros'), isTrue);
    expect(pareceCuentaDeAhorro('Cajita Nu'), isTrue);
    expect(pareceCuentaDeAhorro('Apartado vacaciones'), isTrue);
    expect(pareceCuentaDeAhorro('Nómina'), isFalse);
    expect(pareceCuentaDeAhorro(''), isFalse);
  });

  group('paleta de cuentas', () {
    test('los primeros colores no cambian de lugar', () {
      // El color se guarda como posición: reordenar cambiaría los ya elegidos.
      expect(paletaCuentas[0], const [Color(0xFF6366F1), Color(0xFF8B5CF6)]);
      expect(paletaCuentas[5], const [Color(0xFF64748B), Color(0xFF94A3B8)]);
      expect(paletaCuentas[7], const [Color(0xFF14B8A6), Color(0xFF0EA5E9)]);
      expect(paletaCuentas.length, greaterThanOrEqualTo(18));
    });

    test('el color sugerido de cada banco existe en la paleta', () {
      for (final banco in ['Nu', 'BBVA', 'Banorte', 'Santander', 'Banamex', 'HSBC', 'Plata', 'Didi']) {
        final color = colorDeBanco(banco);
        expect(color, isNotNull, reason: banco);
        expect(color, lessThan(paletaCuentas.length), reason: banco);
      }
      expect(colorDeBanco('  plata '), colorDeBanco('Plata'));
      expect(colorDeBanco('Banco desconocido'), isNull);
    });
  });
}
