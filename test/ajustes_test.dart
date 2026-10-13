import 'dart:ui' show Brightness;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/estado/ajustes.dart';
import 'package:lino/estado/servicios.dart';

/// Almacén en memoria que cuenta las escrituras.
class _AlmacenContado extends AlmacenEnMemoria {
  int escrituras = 0;

  @override
  Future<void> escribir(String clave, String valor) {
    escrituras++;
    return super.escribir(clave, valor);
  }
}

ProviderContainer _contenedor(AlmacenSeguro almacen, {Ajustes iniciales = const Ajustes()}) {
  final contenedor = ProviderContainer(
    overrides: [
      almacenSeguroProvider.overrideWithValue(almacen),
      ajustesInicialesProvider.overrideWithValue(iniciales),
    ],
  );
  addTearDown(contenedor.dispose);
  return contenedor;
}

void main() {
  test('los ajustes se guardan y se vuelven a leer', () async {
    final almacen = AlmacenEnMemoria();
    final ajustes = _contenedor(almacen).read(ajustesProvider.notifier);
    await ajustes.cambiarTema('esmeralda');
    await ajustes.cambiarReducirDesenfoque(true);
    await ajustes.cambiarVibracion(false);
    await ajustes.cambiarOcultarAlAbrir(true);
    await ajustes.cambiarSueldoHabitual(180000);
    await ajustes.cambiarCuentaPredeterminada(4);
    await ajustes.cambiarBloqueo(60);

    final leidos = await AlmacenAjustes(almacen).cargar();
    expect(leidos.temaId, 'esmeralda');
    expect(leidos.reducirDesenfoque, isTrue);
    expect(leidos.vibracion, isFalse);
    expect(leidos.ocultarAlAbrir, isTrue);
    expect(leidos.sueldoHabitual, 180000);
    expect(leidos.cuentaPredeterminadaId, 4);
    expect(leidos.bloqueoSegundos, 60);
  });

  test('sin nada guardado se usan los valores por defecto', () async {
    final leidos = await AlmacenAjustes(AlmacenEnMemoria()).cargar();
    expect(leidos.temaId, 'medianoche');
    expect(leidos.vibracion, isTrue);
    expect(leidos.temaAutomatico, isFalse);
    expect(leidos.sueldoHabitual, 0);
    expect(leidos.cuentaPredeterminadaId, isNull);
  });

  test('la cuenta predeterminada se puede quitar', () async {
    final almacen = AlmacenEnMemoria();
    final contenedor = _contenedor(almacen);
    final ajustes = contenedor.read(ajustesProvider.notifier);
    await ajustes.cambiarCuentaPredeterminada(4);
    await ajustes.cambiarCuentaPredeterminada(null);
    expect(contenedor.read(ajustesProvider).cuentaPredeterminadaId, isNull);
    expect((await AlmacenAjustes(almacen).cargar()).cuentaPredeterminadaId, isNull);
  });

  test('cada cambio escribe solo lo que cambió', () async {
    final almacen = _AlmacenContado();
    final ajustes = _contenedor(almacen).read(ajustesProvider.notifier);
    await ajustes.cambiarPrivacidad(true);
    expect(almacen.escrituras, 1);
    await ajustes.cambiarPrivacidad(true);
    expect(almacen.escrituras, 1);
  });

  group('tema automático', () {
    test('usa el tema claro u oscuro según el modo del teléfono', () async {
      final contenedor = _contenedor(
        AlmacenEnMemoria(),
        iniciales: const Ajustes(temaAutomatico: true, temaClaroId: 'verano', temaOscuroId: 'grafito'),
      );
      contenedor.read(brilloSistemaProvider.notifier).fijar(Brightness.dark);
      expect(contenedor.read(temaProvider).id, 'grafito');
      contenedor.read(brilloSistemaProvider.notifier).fijar(Brightness.light);
      expect(contenedor.read(temaProvider).id, 'verano');
    });

    test('al activarlo conserva el tema actual y al elegir cambia el de su grupo', () async {
      final contenedor = _contenedor(AlmacenEnMemoria(), iniciales: const Ajustes(temaId: 'amatista'));
      final ajustes = contenedor.read(ajustesProvider.notifier);
      contenedor.read(brilloSistemaProvider.notifier).fijar(Brightness.dark);

      await ajustes.cambiarTemaAutomatico(true);
      expect(contenedor.read(ajustesProvider).temaOscuroId, 'amatista');
      expect(contenedor.read(temaProvider).id, 'amatista');

      // Elegir un tema claro no toca el de noche.
      await ajustes.cambiarTema('primavera');
      expect(contenedor.read(ajustesProvider).temaClaroId, 'primavera');
      expect(contenedor.read(temaProvider).id, 'amatista');

      // Al apagarlo se queda el que se estaba viendo.
      await ajustes.cambiarTemaAutomatico(false);
      expect(contenedor.read(ajustesProvider).temaId, 'amatista');
    });
  });
}
