import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/app.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/core/seguridad/servicio_auth.dart';
import 'package:lino/data/modelos/cuenta.dart';
import 'package:lino/data/modelos/gasto_fijo.dart';
import 'package:lino/data/modelos/movimiento.dart';
import 'package:lino/data/repositorio.dart';
import 'package:lino/estado/auth.dart';
import 'package:lino/estado/servicios.dart';
import 'package:local_auth/local_auth.dart';

const _pin = '482915';

/// Teléfono sin huella ni otra biometría.
class _SinBiometria implements LocalAuthentication {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repositorio de una base recién creada: todo vacío.
class _RepositorioVacio implements Repositorio {
  @override
  Future<List<CuentaConSaldo>> cuentasConSaldo({bool incluirArchivadas = false}) async => [];

  @override
  Future<List<Movimiento>> movimientosDeSemana(DateTime lunes) async => [];

  @override
  Future<List<Movimiento>> ultimosMovimientos({int limite = 5}) async => [];

  @override
  Future<List<GastoFijo>> gastosFijos() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ServicioAuth _servicio(AlmacenSeguro almacen) =>
    ServicioAuth(almacen, biometria: _SinBiometria(), iteraciones: 1000);

/// Arranca la app completa con un almacén en memoria, en una pantalla del
/// tamaño de un teléfono común (360 x 800 puntos).
Future<ProviderContainer> _abrirApp(WidgetTester tester, AlmacenSeguro almacen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        almacenSeguroProvider.overrideWithValue(almacen),
        servicioAuthProvider.overrideWith((ref) => _servicio(almacen)),
        repositorioProvider.overrideWith((ref) async => _RepositorioVacio()),
      ],
      child: const LinoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(LinoApp)));
}

Future<void> _teclear(WidgetTester tester, String pin) async {
  for (final digito in pin.split('')) {
    await tester.tap(find.text(digito));
    await tester.pump();
  }
}

/// Deja pasar tiempo real hasta que se cumple [listo]: el hash del PIN se
/// calcula en otro isolate y el reloj simulado de las pruebas no lo espera.
Future<void> _esperar(WidgetTester tester, bool Function() listo) async {
  for (var i = 0; i < 500 && !listo(); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  expect(listo(), isTrue, reason: 'La app no respondió a tiempo.');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la primera vez abre la pantalla de crear PIN', (tester) async {
    final contenedor = await _abrirApp(tester, AlmacenEnMemoria());
    expect(contenedor.read(authProvider).fase, FaseAuth.crearPin);
    expect(find.text('Crea tu PIN'), findsOneWidget);
    expect(find.text('Ingresa tu PIN'), findsNothing);
  });

  testWidgets('crear el PIN guarda solo su hash y lleva a Inicio', (tester) async {
    final almacen = AlmacenEnMemoria();
    final contenedor = await _abrirApp(tester, almacen);

    // Un PIN obvio se rechaza y se vuelve a pedir.
    await _teclear(tester, '123456');
    expect(find.text('Evita números consecutivos.'), findsOneWidget);
    expect(find.text('Crea tu PIN'), findsOneWidget);

    await _teclear(tester, _pin);
    expect(find.text('Confirma tu PIN'), findsOneWidget);
    await _teclear(tester, _pin);
    await _esperar(tester, () => contenedor.read(authProvider).fase == FaseAuth.desbloqueada);

    expect(almacen.datos.values.any((v) => v.contains(_pin)), isFalse);
    expect(find.text('Crea tu PIN'), findsNothing);
    expect(find.text('Empieza con tus cuentas'), findsOneWidget);
  });

  testWidgets('con PIN guardado abre bloqueada y solo entra el PIN correcto', (tester) async {
    final almacen = AlmacenEnMemoria();
    await tester.runAsync(() => _servicio(almacen).guardarPin(_pin));
    final contenedor = await _abrirApp(tester, almacen);
    expect(contenedor.read(authProvider).fase, FaseAuth.bloqueada);
    expect(find.text('Ingresa tu PIN'), findsOneWidget);
    // La interfaz principal no se construye antes del primer desbloqueo.
    expect(find.text('Empieza con tus cuentas'), findsNothing);

    await _teclear(tester, '000001');
    await _esperar(tester, () => find.textContaining('PIN incorrecto').evaluate().isNotEmpty);
    expect(find.text('PIN incorrecto. Te quedan 4 intentos.'), findsOneWidget);
    expect(contenedor.read(authProvider).fase, FaseAuth.bloqueada);

    await _teclear(tester, _pin);
    await _esperar(tester, () => contenedor.read(authProvider).fase == FaseAuth.desbloqueada);
    expect(find.text('Ingresa tu PIN'), findsNothing);
    expect(find.text('Empieza con tus cuentas'), findsOneWidget);
  });
}
