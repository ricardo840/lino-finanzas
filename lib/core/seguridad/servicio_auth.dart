import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'almacen_seguro.dart';
import 'pbkdf2.dart';

/// Resultado de comparar un PIN contra el guardado.
class ResultadoPin {
  const ResultadoPin.correcto()
      : correcto = true,
        intentosRestantes = 0,
        bloqueadoHasta = null;

  const ResultadoPin.incorrecto({
    required this.intentosRestantes,
    this.bloqueadoHasta,
  }) : correcto = false;

  final bool correcto;
  final int intentosRestantes;

  /// Si no es null, no se aceptan más intentos hasta esa hora.
  final DateTime? bloqueadoHasta;
}

/// PIN de 6 dígitos (hash PBKDF2 + sal en el Keystore) y huella digital.
///
/// Cada 5 intentos fallidos se bloquea el PIN: 30 s, luego 1 min, 2 min...
/// hasta un máximo de 30 min.
class ServicioAuth {
  ServicioAuth(
    this._almacen, {
    LocalAuthentication? biometria,
    DateTime Function()? reloj,
    this.iteraciones = 60000,
  })  : _biometria = biometria ?? LocalAuthentication(),
        _reloj = reloj ?? DateTime.now;

  static const int longitudPin = 6;
  static const int intentosPorRonda = 5;
  static const int bloqueoMaximoSegundos = 30 * 60;

  static const _kHash = 'pin_hash';
  static const _kSal = 'pin_sal';
  static const _kIteraciones = 'pin_iteraciones';
  static const _kFallos = 'pin_fallos';
  static const _kBloqueadoHasta = 'pin_bloqueado_hasta';

  final AlmacenSeguro _almacen;
  final LocalAuthentication _biometria;
  final DateTime Function() _reloj;

  /// Iteraciones de PBKDF2 para PIN nuevos.
  final int iteraciones;

  bool _autenticando = false;

  /// Mientras el diálogo de huella está abierto, Android puede pausar la app;
  /// el bloqueo automático lo consulta para no cerrar la sesión por eso.
  bool get autenticandoBiometria => _autenticando;

  Future<bool> tienePin() async => (await _almacen.leer(_kHash)) != null;

  /// Valida que sea de 6 dígitos y que no sea obvio (111111, 123456...).
  static String? problemaConPin(String pin) {
    if (pin.length != longitudPin || !RegExp(r'^\d+$').hasMatch(pin)) {
      return 'El PIN debe tener $longitudPin dígitos.';
    }
    if (pin.split('').toSet().length == 1) {
      return 'Evita repetir el mismo número.';
    }
    var ascendente = true;
    var descendente = true;
    for (var i = 1; i < pin.length; i++) {
      final paso = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (paso != 1) ascendente = false;
      if (paso != -1) descendente = false;
    }
    if (ascendente || descendente) return 'Evita números consecutivos.';
    return null;
  }

  Future<void> guardarPin(String pin) async {
    final problema = problemaConPin(pin);
    if (problema != null) throw ArgumentError(problema);
    final sal = _bytesAleatorios(16);
    final hash = await _derivar(pin, sal, iteraciones);
    await _almacen.escribir(_kSal, base64Encode(sal));
    await _almacen.escribir(_kHash, base64Encode(hash));
    await _almacen.escribir(_kIteraciones, '$iteraciones');
    await _almacen.borrar(_kFallos);
    await _almacen.borrar(_kBloqueadoHasta);
  }

  /// Hora hasta la que el PIN está bloqueado, o null si no lo está.
  Future<DateTime?> bloqueadoHasta() async {
    final valor = await _almacen.leer(_kBloqueadoHasta);
    if (valor == null) return null;
    final hasta = DateTime.tryParse(valor);
    if (hasta == null || !hasta.isAfter(_reloj())) return null;
    return hasta;
  }

  Future<ResultadoPin> verificarPin(String pin) async {
    final bloqueo = await bloqueadoHasta();
    if (bloqueo != null) {
      return ResultadoPin.incorrecto(intentosRestantes: 0, bloqueadoHasta: bloqueo);
    }

    final hashGuardado = await _almacen.leer(_kHash);
    final salGuardada = await _almacen.leer(_kSal);
    if (hashGuardado == null || salGuardada == null) {
      return const ResultadoPin.incorrecto(intentosRestantes: 0);
    }
    final iter = int.tryParse(await _almacen.leer(_kIteraciones) ?? '') ?? iteraciones;

    final calculado = await _derivar(pin, base64Decode(salGuardada), iter);
    if (comparacionConstante(calculado, base64Decode(hashGuardado))) {
      await _almacen.borrar(_kFallos);
      await _almacen.borrar(_kBloqueadoHasta);
      return const ResultadoPin.correcto();
    }

    final fallos = (int.tryParse(await _almacen.leer(_kFallos) ?? '') ?? 0) + 1;
    await _almacen.escribir(_kFallos, '$fallos');

    if (fallos % intentosPorRonda == 0) {
      final segundos = segundosDeBloqueo(fallos ~/ intentosPorRonda);
      final hasta = _reloj().add(Duration(seconds: segundos));
      await _almacen.escribir(_kBloqueadoHasta, hasta.toIso8601String());
      return ResultadoPin.incorrecto(intentosRestantes: 0, bloqueadoHasta: hasta);
    }
    return ResultadoPin.incorrecto(
      intentosRestantes: intentosPorRonda - fallos % intentosPorRonda,
    );
  }

  /// Segundos de bloqueo al completar la ronda [ronda] de intentos fallidos:
  /// 30 s, 1 min, 2 min... hasta [bloqueoMaximoSegundos].
  ///
  /// Se duplica paso a paso y se detiene al llegar al máximo: una potencia de 2
  /// desbordaría el entero a partir de la ronda 60 y dejaría el PIN sin
  /// bloqueo.
  static int segundosDeBloqueo(int ronda) {
    var segundos = 30;
    for (var i = 1; i < ronda && segundos < bloqueoMaximoSegundos; i++) {
      segundos *= 2;
    }
    return min(segundos, bloqueoMaximoSegundos);
  }

  /// true si el teléfono tiene huella (u otra biometría) registrada.
  Future<bool> biometriaDisponible() async {
    try {
      if (!await _biometria.isDeviceSupported()) return false;
      if (!await _biometria.canCheckBiometrics) return false;
      final tipos = await _biometria.getAvailableBiometrics();
      return tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autenticarConBiometria() async {
    if (_autenticando) return false;
    _autenticando = true;
    try {
      return await _biometria.authenticate(
        localizedReason: 'Confirma tu identidad para abrir Lino',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Desbloquear Lino',
            cancelButton: 'Usar PIN',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    } finally {
      _autenticando = false;
    }
  }

  static Uint8List _bytesAleatorios(int cantidad) {
    final azar = Random.secure();
    return Uint8List.fromList(List<int>.generate(cantidad, (_) => azar.nextInt(256)));
  }

  /// El cálculo corre en otro isolate para no congelar la interfaz.
  static Future<Uint8List> _derivar(String pin, List<int> sal, int iteraciones) {
    final clave = utf8.encode(pin);
    final salCopia = Uint8List.fromList(sal);
    return Isolate.run(
      () => pbkdf2Sha256(clave: clave, sal: salCopia, iteraciones: iteraciones),
    );
  }
}
