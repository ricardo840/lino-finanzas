import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/ui/pantallas/shell.dart';
import 'package:lino/ui/widgets/barra_isla.dart';
import 'package:lino/ui/widgets/boton_flotante.dart';

import 'apoyo.dart';

/// Abre las pestañas principales en una pantalla alta. La fuente de las
/// pruebas es casi el doble de ancha que la real, así que 800 puntos de ancho
/// equivalen a un teléfono común.
Future<void> _abrirShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: sustitutos(AlmacenEnMemoria()),
      child: const CupertinoApp(home: Shell()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Botón de la isla con esa etiqueta.
Finder _pestana(String etiqueta) =>
    find.descendant(of: find.byType(BarraIsla), matching: find.text(etiqueta));

Future<void> _tocar(WidgetTester tester, Finder objetivo) async {
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la isla muestra las cinco pestañas y cambia de pantalla', (tester) async {
    await _abrirShell(tester);
    for (final etiqueta in ['Inicio', 'Cuentas', 'Movimientos', 'Simulador', 'Ajustes']) {
      expect(_pestana(etiqueta), findsOneWidget);
    }
    expect(find.text('Empieza con tus cuentas'), findsOneWidget);

    await _tocar(tester, _pestana('Cuentas'));
    expect(find.text('Sin cuentas'), findsOneWidget);
    expect(find.text('Empieza con tus cuentas'), findsNothing);

    await _tocar(tester, _pestana('Movimientos'));
    expect(find.text('Semana sin movimientos'), findsOneWidget);

    await _tocar(tester, _pestana('Simulador'));
    expect(find.text('Simular compra'), findsOneWidget);

    await _tocar(tester, _pestana('Ajustes'));
    expect(find.text('Modo privacidad'), findsOneWidget);

    await _tocar(tester, _pestana('Inicio'));
    expect(find.text('Empieza con tus cuentas'), findsOneWidget);
  });

  testWidgets('la isla flota: no toca los bordes de la pantalla', (tester) async {
    await _abrirShell(tester);
    final isla = tester.getRect(find.byType(BarraIsla));
    final pantalla = tester.getRect(find.byType(Shell));
    expect(isla.left, greaterThan(pantalla.left));
    expect(isla.right, lessThan(pantalla.right));
    expect(isla.bottom, lessThan(pantalla.bottom));
  });

  testWidgets('el botón flotante dice qué registra y abre su formulario', (tester) async {
    await _abrirShell(tester);
    // En Inicio registra un movimiento.
    await _tocar(tester, find.widgetWithText(BotonFlotante, 'Movimiento'));
    expect(find.text('Nuevo movimiento'), findsOneWidget);
    await _tocar(tester, find.text('Cancelar'));

    await _tocar(tester, _pestana('Cuentas'));
    await _tocar(tester, find.widgetWithText(BotonFlotante, 'Cuenta'));
    expect(find.text('Nueva cuenta'), findsOneWidget);
    await _tocar(tester, find.text('Cancelar'));

    await _tocar(tester, _pestana('Movimientos'));
    expect(find.widgetWithText(BotonFlotante, 'Movimiento'), findsOneWidget);

    // Ajustes no tiene acción principal.
    await _tocar(tester, _pestana('Ajustes'));
    expect(find.byType(BotonFlotante), findsNothing);
  });

  testWidgets('al volver a una pestaña abre en su pantalla principal', (tester) async {
    await _abrirShell(tester);
    await _tocar(tester, _pestana('Ajustes'));
    await _tocar(tester, find.text('Gastos fijos'));
    expect(find.text('Sin gastos fijos'), findsOneWidget);
    expect(find.text('Modo privacidad'), findsNothing);

    // Se sale de la pestaña con la pantalla interna abierta.
    await _tocar(tester, _pestana('Inicio'));
    await _tocar(tester, _pestana('Ajustes'));
    expect(find.text('Sin gastos fijos'), findsNothing);
    expect(find.text('Modo privacidad'), findsOneWidget);
  });

  testWidgets('tocar la pestaña abierta regresa a su pantalla principal', (tester) async {
    await _abrirShell(tester);
    await _tocar(tester, _pestana('Ajustes'));
    await _tocar(tester, find.text('Gastos fijos'));
    expect(find.text('Sin gastos fijos'), findsOneWidget);

    await _tocar(tester, _pestana('Ajustes'));
    expect(find.text('Sin gastos fijos'), findsNothing);
    expect(find.text('Modo privacidad'), findsOneWidget);
  });

  testWidgets('en Tema no queda un hueco entre los temas oscuros y los claros', (tester) async {
    await _abrirShell(tester);
    await _tocar(tester, _pestana('Ajustes'));
    await _tocar(tester, find.text('Tema'));

    final ultimoOscuro = tester.getRect(find.text('Amatista'));
    final tituloClaros = tester.getRect(find.text('CLAROS DE TEMPORADA'));
    // Margen de la tarjeta, separación y etiqueta: unos 40 puntos.
    expect(tituloClaros.top - ultimoOscuro.bottom, lessThan(60));
  });
}
