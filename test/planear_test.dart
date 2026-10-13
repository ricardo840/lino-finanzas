import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/ui/pantallas/shell.dart';
import 'package:lino/ui/widgets/barra_isla.dart';
import 'package:lino/ui/widgets/linea_tiempo.dart';

import 'apoyo.dart';

/// Abre la pestaña Planear con un repositorio vacío y lo regresa.
Future<RepositorioVacio> _abrirPlanear(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = RepositorioVacio();
  await tester.pumpWidget(
    ProviderScope(
      overrides: sustitutos(AlmacenEnMemoria(), repositorio: repo),
      child: const CupertinoApp(home: Shell()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(BarraIsla), matching: find.text('Planear')));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Finder _campo(String marcador) =>
    find.byWidgetPredicate((w) => w is CupertinoTextField && w.placeholder == marcador);

void main() {
  testWidgets('el simulador pide un rango de fechas en lugar de "¿Puedo esperar?"', (tester) async {
    await _abrirPlanear(tester);
    await _tocar(tester, find.text('Simulador'));
    expect(find.text('Desde'), findsOneWidget);
    expect(find.text('Hasta'), findsOneWidget);
    expect(find.text('¿PUEDO ESPERAR?'), findsNothing);
    for (final atajo in ['Hoy', 'Esta semana', 'Este mes', '30 días']) {
      expect(find.text(atajo), findsOneWidget);
    }
  });

  testWidgets('una simulación se guarda como compra planeada y aparece en el calendario', (tester) async {
    final repo = await _abrirPlanear(tester);
    await _tocar(tester, find.text('Simulador'));
    await tester.enterText(_campo('0.00'), '5000');
    await tester.enterText(_campo('Audífonos, llantas...'), 'Bocina');
    await _tocar(tester, find.text('Este mes'));
    await _tocar(tester, find.text('Simular compra'));
    // Sin cuentas ni tarjetas no hay con qué pagar.
    expect(find.text('Por ahora no te alcanza'), findsOneWidget);
    expect(find.text('Registrar esta compra'), findsNothing);

    await _tocar(tester, find.text('Guardar como compra planeada'));
    expect(repo.compras.single.monto, 500000);
    expect(repo.compras.single.descripcion, 'Bocina');
    await _tocar(tester, find.text('Entendido'));

    // Queda en el día de hoy, que es el que el calendario abre seleccionado.
    await _tocar(tester, find.text('Calendario'));
    expect(find.text('Bocina'), findsOneWidget);

    // Desde el calendario se puede quitar.
    await _tocar(tester, find.text('Bocina'));
    await _tocar(tester, find.text('Quitar del calendario'));
    expect(repo.compras, isEmpty);
    expect(find.text('Bocina'), findsNothing);
  });

  testWidgets('la línea de tiempo muestra compra, corte, pago y sueldos', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox(
            width: 600,
            child: LineaTiempoCompra(
              compra: DateTime(2026, 10, 30),
              corte: DateTime(2026, 11, 16),
              limite: DateTime(2026, 11, 26),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Compra 30 oct'), findsOneWidget);
    expect(find.text('Corte 16 nov'), findsOneWidget);
    expect(find.text('Pago 26 nov'), findsOneWidget);
    // Domingos 1, 8, 15 y 22 de noviembre.
    expect(find.text('4 domingos de sueldo antes del pago'), findsOneWidget);
  });
}
