import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lino/core/seguridad/almacen_seguro.dart';
import 'package:lino/core/seguridad/pbkdf2.dart';
import 'package:lino/core/seguridad/servicio_auth.dart';

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('PBKDF2-HMAC-SHA256 (vectores conocidos)', () {
    List<int> calcular(int iteraciones, {int longitud = 32}) => pbkdf2Sha256(
          clave: utf8.encode('password'),
          sal: utf8.encode('salt'),
          iteraciones: iteraciones,
          longitud: longitud,
        );

    test('1 iteración', () {
      expect(_hex(calcular(1)), '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    });

    test('4096 iteraciones', () {
      expect(_hex(calcular(4096)), 'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a');
    });

    test('salida de más de un bloque', () {
      final r = pbkdf2Sha256(
        clave: utf8.encode('passwordPASSWORDpassword'),
        sal: utf8.encode('saltSALTsaltSALTsaltSALTsaltSALTsalt'),
        iteraciones: 4096,
        longitud: 40,
      );
      expect(
        _hex(r),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9',
      );
    });
  });

  group('ServicioAuth', () {
    late AlmacenEnMemoria almacen;
    late DateTime ahora;
    late ServicioAuth servicio;

    setUp(() {
      almacen = AlmacenEnMemoria();
      ahora = DateTime(2026, 10, 9, 12);
      servicio = ServicioAuth(almacen, reloj: () => ahora, iteraciones: 1000);
    });

    test('rechaza PIN obvios', () {
      expect(ServicioAuth.problemaConPin('111111'), isNotNull);
      expect(ServicioAuth.problemaConPin('123456'), isNotNull);
      expect(ServicioAuth.problemaConPin('654321'), isNotNull);
      expect(ServicioAuth.problemaConPin('12345'), isNotNull);
      expect(ServicioAuth.problemaConPin('482915'), isNull);
    });

    test('guarda el PIN como hash y lo verifica', () async {
      expect(await servicio.tienePin(), isFalse);
      await servicio.guardarPin('482915');
      expect(await servicio.tienePin(), isTrue);
      expect(almacen.datos.values.any((v) => v.contains('482915')), isFalse);
      expect((await servicio.verificarPin('482915')).correcto, isTrue);
      final malo = await servicio.verificarPin('000001');
      expect(malo.correcto, isFalse);
      expect(malo.intentosRestantes, 4);
    });

    test('bloquea 30 s tras 5 intentos y luego se libera', () async {
      await servicio.guardarPin('482915');
      ResultadoPin r = const ResultadoPin.correcto();
      for (var i = 0; i < 5; i++) {
        r = await servicio.verificarPin('000001');
      }
      expect(r.bloqueadoHasta, ahora.add(const Duration(seconds: 30)));
      // Bloqueado: ni el PIN correcto entra.
      expect((await servicio.verificarPin('482915')).correcto, isFalse);
      ahora = ahora.add(const Duration(seconds: 31));
      expect((await servicio.verificarPin('482915')).correcto, isTrue);
    });

    test('la segunda ronda de fallos bloquea 1 min', () async {
      await servicio.guardarPin('482915');
      ResultadoPin r = const ResultadoPin.correcto();
      for (var i = 0; i < 5; i++) {
        r = await servicio.verificarPin('000001');
      }
      ahora = ahora.add(const Duration(seconds: 31));
      for (var i = 0; i < 4; i++) {
        r = await servicio.verificarPin('000001');
        expect(r.bloqueadoHasta, isNull);
      }
      r = await servicio.verificarPin('000001');
      expect(r.bloqueadoHasta, ahora.add(const Duration(minutes: 1)));
    });

    test('el bloqueo crece 30 s, 1 min, 2 min... y se queda en 30 min', () {
      expect(
        [for (var ronda = 1; ronda <= 8; ronda++) ServicioAuth.segundosDeBloqueo(ronda)],
        [30, 60, 120, 240, 480, 960, 1800, 1800],
      );
      // Con muchas rondas una potencia de 2 desborda el entero de 64 bits y el
      // bloqueo quedaría en cero: debe seguir en el máximo.
      for (final ronda in [59, 60, 63, 64, 65, 1000]) {
        expect(ServicioAuth.segundosDeBloqueo(ronda), ServicioAuth.bloqueoMaximoSegundos);
      }
    });
  });
}
