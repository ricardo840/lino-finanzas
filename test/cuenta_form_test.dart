import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/data/repositorio.dart';
import 'package:lino/estado/servicios.dart';
import 'package:lino/ui/pantallas/cuentas/cuenta_form_pantalla.dart';

/// Repositorio de prueba: solo recuerda la última cuenta guardada.
class _RepositorioFalso implements Repositorio {
  Cuenta? guardada;

  @override
  Future<int> guardarCuenta(Cuenta cuenta) async {
    guardada = cuenta;
    return cuenta.id ?? 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CuentaConSaldo _cuenta(TipoCuenta tipo, {required int saldoInicial, required int saldo}) =>
    CuentaConSaldo(
      Cuenta(
        id: 1,
        nombre: 'Principal',
        banco: 'Nu',
        tipo: tipo,
        saldoInicial: saldoInicial,
        diaCorte: tipo == TipoCuenta.credito ? 10 : null,
        diaPago: tipo == TipoCuenta.credito ? 30 : null,
        creadaEn: DateTime(2026),
      ),
      saldo,
    );

/// Abre el formulario de edición encima de una ruta base (para que pueda
/// cerrarse al guardar) y regresa el repositorio que recibe la escritura.
Future<_RepositorioFalso> _abrirEdicion(WidgetTester tester, CuentaConSaldo cuenta) async {
  final repo = _RepositorioFalso();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [repositorioProvider.overrideWith((ref) async => repo)],
      child: const CupertinoApp(home: SizedBox.expand()),
    ),
  );
  tester.state<NavigatorState>(find.byType(Navigator)).push(
        CupertinoPageRoute<void>(builder: (_) => CuentaFormPantalla(existente: cuenta)),
      );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

/// Campo de saldo (o de deuda en crédito): el primero con marcador "0.00".
Finder get _campoSaldo => find
    .byWidgetPredicate((w) => w is CupertinoTextField && w.placeholder == '0.00')
    .first;

void main() {
  group('editar una cuenta', () {
    testWidgets('sin tocar el saldo conserva un saldo negativo', (tester) async {
      // Efectivo en -$500.00: se gastó más de lo que se había registrado.
      final repo = await _abrirEdicion(
        tester,
        _cuenta(TipoCuenta.efectivo, saldoInicial: 0, saldo: -50000),
      );
      await _guardar(tester);
      expect(repo.guardada!.saldoInicial, 0);
    });

    testWidgets('sin tocar la deuda conserva un saldo a favor en crédito', (tester) async {
      final repo = await _abrirEdicion(
        tester,
        _cuenta(TipoCuenta.credito, saldoInicial: 30000, saldo: 30000),
      );
      await _guardar(tester);
      expect(repo.guardada!.saldoInicial, 30000);
    });

    testWidgets('al capturar otro saldo ajusta el saldo inicial para que cuadre', (tester) async {
      // Saldo inicial 1,000.00 y movimientos por -1,500.00: saldo de -500.00.
      final repo = await _abrirEdicion(
        tester,
        _cuenta(TipoCuenta.debito, saldoInicial: 100000, saldo: -50000),
      );
      await tester.enterText(_campoSaldo, '300');
      await _guardar(tester);
      // El saldo de hoy debe quedar en 300.00: 300.00 - (-1,500.00).
      expect(repo.guardada!.saldoInicial, 180000);
    });

    testWidgets('al capturar otra deuda la guarda como saldo negativo', (tester) async {
      // Deuda inicial de 1,000.00 sin movimientos.
      final repo = await _abrirEdicion(
        tester,
        _cuenta(TipoCuenta.credito, saldoInicial: -100000, saldo: -100000),
      );
      await tester.enterText(_campoSaldo, '250');
      await _guardar(tester);
      expect(repo.guardada!.saldoInicial, -25000);
    });
  });
}
